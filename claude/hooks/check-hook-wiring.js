#!/usr/bin/env node
// SessionStart drift detector: declared config must equal deployed files.
//
// Catches the 2026-07-05 failure class found by the Bitter Lesson audit:
// settings.json declared subagent-gate hooks (and skills referenced the
// "committer" agent) whose files were never symlinked on this machine, so
// enforcement silently failed open. Two checks:
//   1. Every "$HOME/.claude/..." file referenced by a hook command exists.
//   2. Every top-level file in each dotfiles/claude dir that symlinks.ps1
//      deploys (hooks, commands, scripts, agents) byte-matches its
//      ~/.claude counterpart, and each nested dir (junction) exists
//      (hardlinks silently diverge when git replaces the source file).
// Prints warnings only when something is wrong; always exits 0 (fail-open).
'use strict';
const fs = require('fs');
const path = require('path');
const os = require('os');

const home = os.homedir();
const problems = [];

try {
  const settings = fs.readFileSync(path.join(home, '.claude', 'settings.json'), 'utf8');
  const refs = new Set();
  for (const m of settings.matchAll(/\$HOME(\/\.claude\/[\w./-]+)/g)) refs.add(m[1]);
  for (const ref of refs) {
    if (!fs.existsSync(path.join(home, ref.replace(/\//g, path.sep)))) {
      problems.push(`missing hook file referenced by settings.json: ~${ref}`);
    }
  }
} catch (e) {
  problems.push(`could not scan settings.json: ${e.message}`);
}

for (const dir of ['hooks', 'commands', 'scripts', 'agents']) {
  try {
    const srcDir = path.join(home, 'dotfiles', 'claude', dir);
    const dstDir = path.join(home, '.claude', dir);
    if (!fs.existsSync(srcDir)) continue;
    for (const name of fs.readdirSync(srcDir)) {
      const src = path.join(srcDir, name);
      const dst = path.join(dstDir, name);
      if (fs.statSync(src).isDirectory()) {
        if (!fs.existsSync(dst)) problems.push(`dir in dotfiles not deployed to ~/.claude/${dir}: ${name}`);
        continue;
      }
      if (!fs.existsSync(dst)) {
        problems.push(`file in dotfiles not deployed to ~/.claude/${dir}: ${name}`);
      } else if (!fs.readFileSync(src).equals(fs.readFileSync(dst))) {
        problems.push(`deployed file diverged from dotfiles source (stale hardlink?): ${dir}/${name}`);
      }
    }
  } catch (e) {
    problems.push(`could not compare ${dir} dirs: ${e.message}`);
  }
}

if (problems.length) {
  console.log(
    'HOOK WIRING DRIFT detected (declared config != deployed files). ' +
    'Fix by re-running the symlink script (pnpm run windows_symlinks / mac_symlinks) or relinking manually:\n- ' +
    problems.join('\n- ')
  );
}
process.exit(0);
