#!/usr/bin/env node
// Prints the dashboard's Today focus items as markdown bullets, plus the stamp
// date, so callers never parse HTML themselves.
// Usage: node today.mjs [--json] [--file <path>]

import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

const args = process.argv.slice(2);
const asJson = args.includes('--json');
const fileArg = args.indexOf('--file');
const file =
  fileArg !== -1 && args[fileArg + 1]
    ? args[fileArg + 1]
    : join(homedir(), 'dotfiles', 'artifacts', 'case-queue-in-discussion.html');

let html;
try {
  html = readFileSync(file, 'utf8');
} catch {
  out({ exists: false, file, stamp: null, items: [], reason: 'file not found' });
  process.exit(0);
}

const block = html.match(/<!--\s*today:start\s*-->([\s\S]*?)<!--\s*today:end\s*-->/);
if (!block) {
  out({ exists: false, file, stamp: null, items: [], reason: 'today markers not found' });
  process.exit(0);
}

const section = block[1];
const stamp = (section.match(/class="stamp"[^>]*>([^<]+)</) || [null, null])[1]?.trim() ?? null;

const items = [];
const liRe = /<li\b[^>]*>([\s\S]*?)<\/li>/g;
let m;
while ((m = liRe.exec(section)) !== null) {
  const li = m[1];
  const title = text((li.match(/<h3\b[^>]*>([\s\S]*?)<\/h3>/) || [])[1]);
  const why = text((li.match(/<p\b[^>]*>([\s\S]*?)<\/p>/) || [])[1]);
  if (title) items.push({ title, why });
}

out({ exists: true, file, stamp, items });

function text(s) {
  if (!s) return '';
  return s
    .replace(/<[^>]+>/g, '')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function out(payload) {
  if (asJson) {
    console.log(JSON.stringify(payload, null, 2));
    return;
  }
  if (!payload.exists) {
    console.log(`(no dashboard Today section: ${payload.reason})`);
    return;
  }
  console.log(`stamp: ${payload.stamp ?? 'none'}`);
  for (const it of payload.items) {
    console.log(`- **${it.title}** ${it.why}`);
  }
}
