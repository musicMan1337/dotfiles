#!/usr/bin/env node

/**
 * The one entry point for obsidian:* skills to touch the vault.
 *
 * The vault is a plain directory and Obsidian indexes filesystem changes on its
 * own, so everything here is straight fs. There is NO `obsidian` CLI: the
 * `obsidian` on PATH is the app binary, and calling it with
 * `create path=... content=...` just launches the app and leaves a stray
 * `Untitled N.md` in the vault root, writing nothing.
 *
 * Usage:
 *   node vault-cli.mjs read   <rel>
 *   node vault-cli.mjs write  <rel> [--append] [--no-clobber]   # content on STDIN
 *   node vault-cli.mjs append <rel>                             # content on STDIN
 *   node vault-cli.mjs search <query> [--path <folder>] [--limit <n>]
 *   node vault-cli.mjs move   <from> <to>
 *   node vault-cli.mjs list   [folder]
 *
 * Write content arrives on STDIN, never as an argument: these notes are
 * multi-KB markdown full of backticks and quotes, which is exactly what a shell
 * argument mangles.
 *
 * Every subcommand prints JSON on success and exits non-zero with a
 * `vault-cli: <reason>` line on refusal.
 */

import fs from "node:fs";
import path from "node:path";
import { vaultPath, resolveVault, readVaultFile, listFolder } from "./vault.mjs";

const VAULT = resolveVault();
const VAULT_ABS = path.resolve(VAULT);

function die(msg) {
  console.error(`vault-cli: ${msg}`);
  process.exit(1);
}

function out(obj) {
  console.log(JSON.stringify(obj, null, 2));
}

/** Resolve a vault-relative path, refusing anything that escapes the vault. */
function safeAbs(rel, { requireMd = true } = {}) {
  if (!rel) die("missing path");
  if (requireMd && !rel.endsWith(".md")) die(`refusing a non-markdown path: ${rel}`);
  const abs = path.resolve(vaultPath(rel));
  if (abs !== VAULT_ABS && !abs.startsWith(VAULT_ABS + path.sep)) {
    die(`path escapes the vault: ${rel}`);
  }
  return abs;
}

async function readStdin() {
  let content = "";
  for await (const chunk of process.stdin) content += chunk;
  return content;
}

/** Every .md file under a vault folder, recursively. Skips dot dirs. */
function walk(relRoot) {
  const absRoot = path.resolve(vaultPath(relRoot || ""));
  const found = [];
  if (!fs.existsSync(absRoot)) return found;
  const stack = [absRoot];
  while (stack.length) {
    const dir = stack.pop();
    let entries;
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch {
      continue;
    }
    for (const e of entries) {
      if (e.name.startsWith(".")) continue;
      const abs = path.join(dir, e.name);
      if (e.isDirectory()) stack.push(abs);
      else if (e.name.endsWith(".md")) found.push(abs);
    }
  }
  return found.sort();
}

const [cmd, ...rest] = process.argv.slice(2);
const flag = (name) => rest.includes(`--${name}`);
const flagVal = (name) => {
  const i = rest.indexOf(`--${name}`);
  return i >= 0 ? rest[i + 1] : undefined;
};
const positionals = rest.filter((a, i) => {
  if (a.startsWith("--")) return false;
  const prev = rest[i - 1];
  return !(prev === "--path" || prev === "--limit");
});

switch (cmd) {
  case "read": {
    const rel = positionals[0];
    safeAbs(rel);
    const res = readVaultFile(rel);
    if (!res.exists) die(`no such file: ${rel}`);
    process.stdout.write(res.content);
    break;
  }

  case "write":
  case "append": {
    const rel = positionals[0];
    const abs = safeAbs(rel);
    const appending = cmd === "append" || flag("append");
    const existed = fs.existsSync(abs);

    if (existed && flag("no-clobber")) die(`refusing to overwrite existing file: ${rel}`);

    const content = await readStdin();
    // A write of nothing is nearly always a broken pipe or an unset variable in
    // the caller, not an intentional truncation. Refuse rather than blank a note.
    if (!content.trim()) die("refusing to write empty content (stdin was empty)");

    fs.mkdirSync(path.dirname(abs), { recursive: true });
    if (appending) {
      const sep = existed && !fs.readFileSync(abs, "utf8").endsWith("\n") ? "\n" : "";
      fs.appendFileSync(abs, sep + content);
    } else {
      fs.writeFileSync(abs, content);
    }
    out({
      path: rel,
      abs,
      mode: appending ? "append" : "overwrite",
      bytes: Buffer.byteLength(content),
      existed,
    });
    break;
  }

  case "search": {
    const query = positionals[0];
    if (!query) die("missing <query>");
    const limit = Number(flagVal("limit") || 50);
    // Per-file cap so one chatty note cannot swallow the whole result set and
    // hide the other files that matched. Topic search wants breadth.
    const perFile = Number(flagVal("per-file") || 3);
    const scope = flagVal("path") || "";
    const needle = query.toLowerCase();
    const hits = [];
    for (const abs of walk(scope)) {
      const rel = path.relative(VAULT_ABS, abs);
      // Filename match counts: slugs encode the topic (2026-05-06-ci3-ci4-...),
      // and a note about X often never spells X the same way in its body.
      if (path.basename(rel).toLowerCase().includes(needle)) {
        hits.push({ path: rel, line: 0, match: "filename", text: path.basename(rel) });
        if (hits.length >= limit) break;
      }
      let text;
      try {
        text = fs.readFileSync(abs, "utf8");
      } catch {
        continue;
      }
      const lines = text.split("\n");
      let inFile = 0;
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].toLowerCase().includes(needle)) {
          hits.push({ path: rel, line: i + 1, match: "content", text: lines[i].trim().slice(0, 300) });
          inFile++;
          if (inFile >= perFile || hits.length >= limit) break;
        }
      }
      if (hits.length >= limit) break;
    }
    out({ query, scope: scope || "(vault)", count: hits.length, truncated: hits.length >= limit, hits });
    break;
  }

  case "move": {
    const [from, to] = positionals;
    const absFrom = safeAbs(from);
    const absTo = safeAbs(to);
    if (!fs.existsSync(absFrom)) die(`no such file: ${from}`);
    if (fs.existsSync(absTo)) die(`destination already exists: ${to}`);
    fs.mkdirSync(path.dirname(absTo), { recursive: true });
    fs.renameSync(absFrom, absTo);
    out({ from, to, abs: absTo });
    break;
  }

  case "list": {
    const rel = positionals[0] || "";
    out({ folder: rel || "(vault root)", entries: listFolder(rel) });
    break;
  }

  default:
    die(`unknown command: ${cmd || "(none)"}. Use read|write|append|search|move|list`);
}
