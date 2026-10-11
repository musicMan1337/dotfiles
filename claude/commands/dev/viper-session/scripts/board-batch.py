#!/usr/bin/env python3
"""Plan-driven batch writer for the Viper case system (see references/case-system.md,
"The batch driver"). Idempotent; GETs run in dry-run, POSTs are printed and suppressed.

  board-batch.py <plan.json> --dry-run | --live

Plan keys: board, lane, common, new_cases[], patches[], notes[]. Created ids go to
<plan>-ids.json beside the plan. Aborts on the first non-2xx.
"""
import json, os, re, subprocess, sys
from pathlib import Path

args = [a for a in sys.argv[1:] if not a.startswith("--")]
if len(args) != 1: sys.exit("usage: board-batch.py <plan.json> --dry-run|--live")
PLAN_F = Path(args[0]).resolve(); PLAN = json.loads(PLAN_F.read_text())
IDS_F = PLAN_F.with_name(PLAN_F.stem.replace("-plan", "") + "-ids.json")
for k in ("patches", "notes"): PLAN.setdefault(k, [])
for c in PLAN.get("new_cases", []): c.setdefault("DependsOnCases", []); c.setdefault("DependsOnKeys", [])
VCURL = os.path.expanduser("~/dotfiles/claude/commands/dev/viper-session/scripts/vcurl")
DRY = "--dry-run" in sys.argv
if DRY == ("--live" in sys.argv): sys.exit("pick exactly one of --dry-run / --live")
ids = json.loads(IDS_F.read_text()) if IDS_F.exists() else {}
def save(): IDS_F.write_text(json.dumps(ids, indent=2))
CLIENT = PLAN["common"]["Client"]; ME = PLAN["common"]["AssignedTo"]; writes = 0
B = PLAN["board"]; LANE = PLAN["lane"]

def run(verb, path, fields):
    args = [VCURL, verb, path] + [f"{k}={v}" for k, v in fields.items() if v is not None]
    r = subprocess.run(args, capture_output=True, text=True)
    first, _, body = r.stdout.partition("\n")
    m = re.search(r"HTTP (\d{3})", first); st = int(m.group(1)) if m else -1
    try: d = json.loads(body)
    except ValueError: d = body
    return st, d

def GET(path, **f):
    st, d = run("GET", path, f)
    if st not in (200, 204): sys.exit(f"ABORT: GET {path} -> {st}: {str(d)[:300]}")
    return d if st == 200 else []

def GET1(path, **f):
    d = GET(path, **f); return d[0] if isinstance(d, list) and d else d

def POST(path, **f):
    global writes; writes += 1
    print("\n" + "=" * 78 + f"\nPOST {path}")
    for k, v in f.items():
        if v is None: continue
        s = str(v).replace("\n", "\\n"); print(f"  {k} = {s if len(s) <= 150 else s[:147] + '...'}")
    if DRY: print("  (dry run, not sent)"); return None
    st, d = run("POST", path, f); print(f"  -> HTTP {st}")
    if st not in (200, 201):
        print(str(d)[:1500]); save(); sys.exit(f"ABORT: POST {path} -> {st}; nothing after this was sent")
    return d

def find(obj, keys):
    if isinstance(obj, dict):
        for k in keys:
            if k in obj and str(obj[k]).isdigit(): return int(obj[k])
        for v in obj.values():
            g = find(v, keys)
            if g: return g
    if isinstance(obj, list):
        for v in obj:
            g = find(v, keys)
            if g: return g
    return None

def board_rows():
    return {str(r["LinkedCaseId"]): r for r in GET(f"rest/viperToDo/projectItems/{B}").get("items", []) if r.get("LinkedCaseId")}

def sub_ids(text):
    for k, v in ids.items(): text = text.replace(f"<{k}>", str(v))
    return text

# ---- A. cases + cards, in plan order so key-deps resolve backwards ---------------
rows = board_rows()
for c in PLAN["new_cases"]:
    if c["key"] not in ids:
        f = dict(PLAN["common"]); f.update({k: c[k] for k in ("CaseTitle","CaseDescription","CaseType","MilestoneId")})
        d = POST("rest/caseREST/newCaseCreate", **f)
        if not DRY:
            cid = find(d, ("ID","CaseID","CaseId","NewCaseId","id"))
            if not cid: print(json.dumps(d)[:1500]); save(); sys.exit(f"ABORT: no CaseID for {c['key']}")
            ids[c["key"]] = cid; save()
    else:
        print(f"[skip] {c['key']} exists as case {ids[c['key']]}")
    cid = ids.get(c["key"], f"<{c['key']}>")
    if str(cid) in rows: print(f"[skip] card for {c['key']} ({cid}) exists on {B}"); continue
    dep_rowids = []
    for dep_case in c["DependsOnCases"] + [str(ids.get(k, f"<{k}>")) for k in c["DependsOnKeys"]]:
        r = rows.get(str(dep_case))
        if not r:
            if DRY and dep_case.startswith("<"): dep_rowids.append(f"<{dep_case.strip('<>')}.RowId>"); continue
            sys.exit(f"ABORT: no card for {dep_case} on {B}")
        dd = (r.get("Dependencies") or "").strip()
        if dd and not dd.startswith("["):
            print(f"\n[fix] card {r['RowId']} prose Dependencies {dd!r} -> []")
            POST("rest/viperToDo/projectItem", Mode="Update", CaseID=B, RowId=r["RowId"], Category=r["Category"],
                 SortOrder=r["SortOrder"], Effort=r.get("Effort"), Dependencies="[]")
        dep_rowids.append(str(r["RowId"]))
    d = POST("rest/viperToDo/projectItem", Mode="Create", CaseID=B, Title=f"Case #{cid}", Category=LANE, LinkedCaseId=cid,
             AssignedTo=ME, SortOrder=c["SortOrder"], Effort=c["Effort"], Dependencies="[" + ", ".join(dep_rowids) + "]")
    if not DRY:
        rows = board_rows()   # refresh so a later case can depend on this card

# ---- B. patch 359685 from its live row -----------------------------------------
for pt in PLAN["patches"]:
    cur = GET1("rest/caseREST/case", CaseID=pt["CaseID"], Client=CLIENT)
    desc = cur.get("CaseDescription") or ""
    if pt["guard_contains"] not in desc:
        print(f"\n[skip] {pt['CaseID']}: guard text {pt['guard_contains']!r} not in the stored description (already patched or edited)"); continue
    f = {"CaseID": pt["CaseID"], "AssignedTo": cur["AssignedTo"], "CaseTitle": cur["CaseTitle"],
         "CaseDescription": sub_ids(pt["CaseDescription"]), "CaseType": cur["CaseType"], "CaseClient": cur["CaseClient"],
         "FolderId": cur.get("FolderId") or "0", "MilestoneId": cur.get("MilestoneId") or "0", "Duration": cur.get("Duration") or "",
         "DevStatus": cur["DevStatus"], "DevRanking": cur.get("DevRanking") or "1", "DevCaseType": cur["DevCaseType"],
         "PublicYn": "1" if str(cur.get("PublicYn")).lower() in ("true", "1") else "0",
         "InternalConfidential": cur.get("InternalConfidential") or "0", "HidePrefixYN": cur.get("HidePrefixYN") or "0",
         "ChangeLog[0][Attribute]": "CaseDescription", "ChangeLog[0][OldValue]": pt["ChangeLogOld"], "ChangeLog[0][NewValue]": pt["ChangeLogNew"]}
    POST("rest/caseREST/updateCaseDetail", **f)

# ---- C. notes, ids substituted, idempotent by marker ---------------------------
for n in PLAN["notes"]:
    have = GET("rest/notes/enhancedNote", itemType="Case", item=n["on"], client=CLIENT)
    if any(n["marker"] in ((x.get("Note") or x.get("note") or "") if isinstance(x, dict) else "") for x in (have if isinstance(have, list) else [])):
        print(f"\n[skip] note already on {n['on']} ({n['marker'][:40]}...)"); continue
    POST("rest/notes/enhancedNote", itemType="Case", item=n["on"], client=CLIENT, note=sub_ids(n["text"]))

# ---- D. verify ----------------------------------------------------------------
if not DRY:
    print("\n" + "-" * 78 + "\nVERIFY")
    rows = board_rows()
    for c in PLAN["new_cases"]:
        r = rows.get(str(ids.get(c["key"])), {})
        print(f"{c['key']} {ids.get(c['key'])}: RowId {r.get('RowId')} {r.get('Category')} sort {r.get('SortOrder')} (want {c['SortOrder']}) deps {r.get('Dependencies')!r} prio {r.get('Priority')}")
        if r and str(r.get("SortOrder")) != c["SortOrder"]:
            POST("rest/viperToDo/projectItem", Mode="Update", CaseID=B, RowId=r["RowId"], Category=LANE, SortOrder=c["SortOrder"],
                 Effort=c["Effort"], Dependencies=r.get("Dependencies") or None)
    for pt in PLAN["patches"]:
        cur = GET1("rest/caseREST/case", CaseID=pt["CaseID"], Client=CLIENT)
        print(f"{pt['CaseID']}: description {'patched' if pt['guard_contains'] not in (cur.get('CaseDescription') or '') else 'STILL STALE'}, InternalConfidential {cur.get('InternalConfidential')}")
    for n in PLAN["notes"]:
        have = GET("rest/notes/enhancedNote", itemType="Case", item=n["on"], client=CLIENT)
        hit = [x for x in (have if isinstance(have, list) else []) if isinstance(x, dict) and n["marker"] in (x.get("Note") or x.get("note") or "")]
        print(f"{n['on']}: note present {bool(hit)}; unresolved placeholders: {bool(hit) and '<' in (hit[0].get('Note') or hit[0].get('note') or '') and '>' in (hit[0].get('Note') or hit[0].get('note') or '')}")
print("\n" + "=" * 78 + f"\n{'DRY RUN' if DRY else 'DONE'}: {writes} POSTs {'previewed' if DRY else 'sent'}. ids: {json.dumps(ids)}")
