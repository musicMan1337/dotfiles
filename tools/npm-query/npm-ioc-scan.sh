#!/usr/bin/env bash
# npm-ioc-scan.sh - find npm project roots on this machine, then run `npm query`
# in each one (in parallel) to check for compromised dependency versions.
#
#   bash npm-ioc-scan.sh                 # scan $HOME
#   bash npm-ioc-scan.sh ~/code ~/work   # scan specific trees
#   JOBS=4 bash npm-ioc-scan.sh          # throttle parallelism (default 8)
#
# Exit 0 = clean, 1 = indicator found, 2 = setup problem.

set -uo pipefail

# ---------------------------------------------------------------------------
# CONFIG - the packages under investigation. One "name range" per line.
# Ranges are npm semver syntax. Update this block for the next incident.
# ---------------------------------------------------------------------------
read -r -d '' IOCS <<'EOF' || true
keyv >=6.0.0
flat-cache >=6.1.0
file-entry-cache >=11.0.0
cacheable >=2.5.1
EOF

JOBS="${JOBS:-8}"
[ "$#" -gt 0 ] && ROOTS=("$@") || ROOTS=("$HOME")

command -v npm >/dev/null 2>&1 || { echo "error: npm not on PATH" >&2; exit 2; }

# Build the npm query selector: "#keyv:semver(>=6.0.0), #flat-cache:semver(...)"
SEL=""
NAMES=""
while read -r name range; do
  [ -z "${name:-}" ] && continue
  [ -n "$SEL" ] && SEL="$SEL, "
  SEL="$SEL#${name}:semver(${range})"
  NAMES="$NAMES $name"
done <<< "$IOCS"
export SEL

TMP=$(mktemp -d) || exit 2
trap 'rm -rf "$TMP"' EXIT

echo "=> checking:$NAMES"
echo "=> roots: ${ROOTS[*]}"

# ---------------------------------------------------------------------------
# 1. Locate project roots. Pruning node_modules is what makes this fast;
#    without it a full $HOME walk is minutes instead of seconds.
# ---------------------------------------------------------------------------
find "${ROOTS[@]}" \
  \( -name node_modules -o -name .git -o -name Library -o -name .Trash \
     -o -name .cache -o -name .npm -o -name .venv -o -name venv \
     -o -name Applications -o -name .terraform \) -prune -o \
  \( -name package-lock.json -o -name npm-shrinkwrap.json \
     -o -name yarn.lock -o -name pnpm-lock.yaml \) -print 2>/dev/null \
  > "$TMP/locks.txt"

grep -E '/(package-lock|npm-shrinkwrap)\.json$' "$TMP/locks.txt" 2>/dev/null \
  | sed 's|/[^/]*$||' | sort -u > "$TMP/npmroots.txt"
grep -E '/(yarn\.lock|pnpm-lock\.yaml)$' "$TMP/locks.txt" 2>/dev/null \
  | sort -u > "$TMP/otherlocks.txt"

n_npm=$(wc -l < "$TMP/npmroots.txt" | tr -d ' ')
n_oth=$(wc -l < "$TMP/otherlocks.txt" | tr -d ' ')
echo "=> found $n_npm npm root(s), $n_oth yarn/pnpm lockfile(s)"

# ---------------------------------------------------------------------------
# 2. Fan out npm query across roots. --package-lock-only means no install and
#    no network; npm does the semver evaluation itself.
#    Note: `xargs -I{}` blows up on BSD with a long command, so pass the path
#    positionally to sh -c instead.
# ---------------------------------------------------------------------------
if [ "$n_npm" -gt 0 ]; then
  xargs -P"$JOBS" -n1 sh -c '
    r=$(cd "$1" 2>/dev/null && npm query "$SEL" --package-lock-only 2>/dev/null \
        | node -e "let s=\"\";process.stdin.on(\"data\",d=>s+=d).on(\"end\",()=>{
             try{const a=JSON.parse(s);if(a.length)
               console.log([...new Set(a.map(p=>p.name+\"@\"+p.version))].join(\", \"));
             }catch(e){}})" 2>/dev/null)
    [ -n "$r" ] && echo "$1|$r"
  ' sh < "$TMP/npmroots.txt" > "$TMP/hits.txt" 2>/dev/null
fi

# ---------------------------------------------------------------------------
# 3/4. yarn+pnpm locks and the npm cache. npm query cannot read either, so
#      parse out (name, version) pairs and range-check them ourselves.
#      yarn.lock splits the name and the version across lines, which a naive
#      "name@version" grep silently misses - hence the block-aware parse.
# ---------------------------------------------------------------------------
: > "$TMP/review.txt"
: > "$TMP/cache.txt"
CACHE="$HOME/.npm/_cacache/index-v5"

IOCS="$IOCS" node - "$TMP" "$CACHE" <<'NODE' 2>/dev/null
const fs=require('fs'),path=require('path');
const [TMP,CACHE]=process.argv.slice(2);
const ioc={};
for(const line of (process.env.IOCS||'').split('\n')){
  const [n,r]=line.trim().split(/\s+/); if(n&&r) (ioc[n]=ioc[n]||[]).push(r);
}
const cmp=(a,b)=>{const A=a.split('.').map(Number),B=b.split('.').map(Number);
  for(let i=0;i<3;i++){if((A[i]||0)!==(B[i]||0))return (A[i]||0)<(B[i]||0)?-1:1}return 0};
// Minimal range support: the comparators our IOC lists actually use.
const inRange=(n,v)=>(ioc[n]||[]).some(r=>{
  const m=r.match(/^(>=|>|<=|<|=)?\s*([0-9]+(?:\.[0-9]+){0,2})$/); if(!m)return false;
  const c=cmp(v,m[2]);
  switch(m[1]||'='){case '>=':return c>=0;case '>':return c>0;
    case '<=':return c<=0;case '<':return c<0;default:return c===0}
});
const out=[],cached=[];
const locks=fs.existsSync(path.join(TMP,'otherlocks.txt'))
  ? fs.readFileSync(path.join(TMP,'otherlocks.txt'),'utf8').split('\n').filter(Boolean):[];
for(const lf of locks){
  let t; try{t=fs.readFileSync(lf,'utf8')}catch{continue}
  const pairs=new Set();
  if(lf.endsWith('yarn.lock')){
    // header block "name@range, name@range:" then an indented  version "x.y.z"
    let cur=null;
    for(const ln of t.split('\n')){
      if(/^\S/.test(ln)&&ln.trim().endsWith(':')){
        const first=ln.replace(/:$/,'').split(',')[0].trim().replace(/^"|"$/g,'');
        cur=first.slice(0,first.lastIndexOf('@'));
      } else {
        const m=ln.match(/^\s+version\s+"?([0-9][^"\s]*)"?/);
        if(m&&cur) pairs.add(cur+'\t'+m[1]);
      }
    }
  } else { // pnpm keys on name@version directly
    for(const m of t.matchAll(/(?:^|[\s'"/(])((?:@[^/\s]+\/)?[a-z0-9._-]+)@([0-9]+\.[0-9]+\.[0-9]+)/gim))
      pairs.add(m[1]+'\t'+m[2]);
  }
  for(const p of pairs){const [n,v]=p.split('\t'); if(inRange(n,v)) out.push(`${lf}|${n}@${v}`)}
}
// npm cache: a cached tarball means the version was actually fetched.
if(CACHE&&fs.existsSync(CACHE)){
  (function rec(d,depth){ if(depth>6)return; let e;
    try{e=fs.readdirSync(d,{withFileTypes:true})}catch{return}
    for(const x of e){const p=path.join(d,x.name);
      if(x.isDirectory())rec(p,depth+1);
      else{let t;try{t=fs.readFileSync(p,'utf8')}catch{continue}
        for(const m of t.matchAll(/\/((?:@[^/]+\/)?[a-z0-9._-]+)\/-\/[^/"]*?-([0-9]+\.[0-9]+\.[0-9]+)\.tgz/gi))
          if(inRange(m[1],m[2])) cached.push(`${m[1]}@${m[2]}`);
      }}})(CACHE,0);
}
fs.writeFileSync(path.join(TMP,'review.txt'),[...new Set(out)].join('\n')+(out.length?'\n':''));
fs.writeFileSync(path.join(TMP,'cache.txt'),[...new Set(cached)].join('\n')+(cached.length?'\n':''));
NODE

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
rc=0
echo
if [ -s "$TMP/hits.txt" ]; then
  rc=1
  echo "!! COMPROMISED VERSIONS IN npm LOCKFILES !!"
  while IFS='|' read -r dir pkgs; do printf '   %s\n      %s\n' "$dir" "$pkgs"; done \
    < "$TMP/hits.txt"
  echo
fi

if [ -s "$TMP/review.txt" ]; then
  rc=1
  echo "!! COMPROMISED VERSIONS IN yarn/pnpm LOCKFILES !!"
  sort -u "$TMP/review.txt" | while IFS='|' read -r lf m; do
    printf '   %-26s %s\n' "$m" "$lf"
  done
  echo
fi

if [ -s "$TMP/cache.txt" ]; then
  rc=1
  echo "!! npm CACHE CONTAINS A COMPROMISED TARBALL !!"
  sed 's|^|   |' "$TMP/cache.txt"
  echo "   This machine downloaded it. Assume the payload ran."
  echo
fi

if [ "$rc" = 0 ]; then
  echo "CLEAN: nothing matched the IOC ranges."
  echo "       scanned $n_npm npm root(s), $n_oth yarn/pnpm lockfile(s), npm cache."
else
  echo "ACTION: rotate npm tokens, gh auth, AWS keys, Vault tokens, kubeconfigs, SSH keys."
fi
exit "$rc"
