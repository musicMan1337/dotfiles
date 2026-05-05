---
name: audit-statement
model: opus
description: Audit bank or credit-card statements (PDF) — find subscriptions, unverified charges, and spending patterns. Per-account state lives in <account>/audits/ so re-runs build on past audits and skip already-scanned PDFs. Triggers on, audit my statement, audit bank statement, audit credit card, check my charges, find subscriptions, recurring charges, suspicious charges, weird charges on my card, where is my money going, spending audit, review my statement
allowed-tools: Bash(uv run *), Bash(~/.claude/commands/audit-statement/lib/extract-pdf.py *), Bash(ls *), Bash(mkdir *), Bash(cat *), Bash(jq *), Bash(test *), Bash(find *), Bash(md5 *), Read, Edit, Write, Glob
---

# Statement Auditor

Audit bank/credit-card statements (PDF) for subscriptions, unverified charges, and spending patterns. **Output is information, not judgment** — never moralize about spending choices, just surface the numbers.

## Inputs

**Request:** $ARGUMENTS

Expected: a path to a directory. Two layouts are supported:

- **Single-account folder** — `<path>/<pdf>` files alongside an `audits/` subfolder for state and reports.
- **Multi-account parent folder** — each subdirectory is one account (subdir name = account label, e.g. `MAIN...7723`). Audit each subfolder separately.

If `$ARGUMENTS` is empty, ask for the path.

## Per-account state

Each account stores its own state in `<account>/audits/`:

- `audits/known-merchants.json` — acknowledged merchants and subscriptions
- `audits/scanned-pdfs.json` — `{ "filename.pdf": { "md5": "...", "scanned_at": "ISO-date", "txn_count": N } }` so re-runs skip already-audited PDFs
- `audits/YYYY-MM-DD-audit.md` — the audit report (one per run)

Co-locating state with statements means the audit is portable — copy the account folder anywhere and history travels with it. There is no global state.

## Step 1 — Resolve mode and accounts

```bash
ls -F "<path>"
```

If the path contains subdirectories (other than `audits/`), this is multi-account mode. Treat each subdirectory as one account and run Steps 2–7 for each in turn. If the path contains only PDFs (and optionally `audits/`), it's a single account.

## Step 2 — Set up audit folder

For each account folder:

```bash
mkdir -p "<account>/audits"
test -f "<account>/audits/known-merchants.json" || echo '{"merchants":{},"subscriptions":{}}' > "<account>/audits/known-merchants.json"
test -f "<account>/audits/scanned-pdfs.json" || echo '{}' > "<account>/audits/scanned-pdfs.json"
```

Read both JSON files into memory before processing. They drive what's "new" vs "known."

## Step 3 — Identify new PDFs to scan

For each `.pdf` in the account folder, compute its MD5 and check `scanned-pdfs.json`. A PDF is **new** if its filename isn't in `scanned-pdfs.json`, OR if it is but the MD5 differs (file was replaced).

```bash
md5 "<pdf-path>"
```

Skip PDFs already scanned with matching MD5. Surface a count: "12 PDFs total, 3 new since last audit."

If zero new PDFs, ask whether the user wants to re-audit everything anyway (re-runs overwrite the scanned-pdfs entries — useful for testing or after script updates).

## Step 4 — Extract transactions

Run the extractor on the new (or all) PDFs. The script already parses transactions into structured rows — don't re-parse from raw text.

```bash
~/.claude/commands/audit-statement/lib/extract-pdf.py "<account-folder>" --json > /tmp/audit-extract-<account>.jsonl
```

The script emits one JSON object per PDF with these fields:
- `file` — full path
- `pages` — page text (use only for header context, e.g. account number, date range)
- `transactions` — array of `{ page, date, description, deposit, withdrawal, balance }`. **This is the source of truth.** Already disambiguates deposit vs withdrawal columns by x-coordinate.
- `words` — raw word-level coordinates (only needed if `transactions` is empty for a non-Wells-Fargo format)

If `transactions` is empty for a file, the script didn't find the standard "Date / Description / Additions / Subtractions / balance" header. Fall back to inspecting `pages` text and ask the user how to interpret. Don't guess silently.

## Step 5 — Verify account match and reconcile

For each PDF:

1. **Account match.** Extract account number from `pages[0]` (regex: `Account number:\s*(\d+)`). Compare against the folder name's trailing digits. If mismatch, **flag prominently in the report** — the file is misfiled and its transactions don't belong to this account.
2. **Reconcile.** From `pages[0]`, parse the statement summary (`Deposits/Additions`, `Withdrawals/Subtractions`). Sum the parsed `transactions`. If the per-PDF delta exceeds $0.01, parsing is wrong — surface the file path and the gap, and exclude that PDF from the audit. Don't analyze on bad data.

## Step 6 — Build the unified transaction set

Aggregate transactions across all newly-scanned PDFs (skipping any that failed reconciliation or had account mismatches). Also load and include transactions from previous scans if their parsed data was stored — but in this skill version, only the new run is in memory; previous runs only contributed to the known-merchants list.

If the user wants cross-statement subscription detection, you need transactions from all PDFs. So if doing subscription analysis on a re-run with only some new files, also re-extract the previously-scanned files (cheap — extraction is fast).

## Step 7 — Three analyses

### A. Subscriptions (recurring charges)

A charge is a subscription candidate when:
- Same normalized merchant appears **2+ times** at roughly consistent cadence (weekly, monthly, quarterly, annually)
- Amount is identical or within ~2% (covers FX, tax bumps)
- Cadence variance is small (monthly charges within ±5 days)

Output a table: merchant | amount | cadence | last charge | annualized cost. Include a **total monthly burn** at the bottom.

Cross-check `subscriptions` in known-merchants — mark known ones as ✓, unknown ones as **NEW**.

### B. Unverified / suspicious charges

Flag in priority order:
1. **Unfamiliar merchant** — not in `merchants.acknowledged` and doesn't fit a known subscription. Top concern.
2. **Duplicate charges** — same merchant, same amount, within minutes. Could be a real double-charge or a hold-then-settle.
3. **Outlier amount** — same merchant, but amount is ≥3× the user's typical charge there.
4. **Round-number charges** at unusual merchants — often test charges by fraudsters.
5. **Foreign-currency or unusual location** — if statement includes country/FX info.

For each flag, show: date, merchant_raw, amount, why-flagged. Don't flag aggressively — false positives erode trust. If you're <70% sure something's worth flagging, leave it out.

### C. Spending breakdown

Categorize transactions (groceries, dining, transport, shopping, entertainment, bills, transfers, etc.). Use merchant name + amount pattern; you don't need a perfect taxonomy.

Output:
- Top 10 merchants by total spend
- Total per category
- Largest single transactions (top 5)
- Net cash flow (deposits − withdrawals)

Skip transfers between own accounts when summing — they double-count.

## Step 8 — Write the report

Write to `<account>/audits/YYYY-MM-DD-audit.md` (today's date). One report per account per run. If a same-day file already exists, append a counter (`-2`, `-3`).

Structure:

```markdown
# <Account label> — Audit YYYY-MM-DD

**Period covered:** <earliest date> – <latest date>
**Statements audited:** N (M new since last audit)
**Total deposits:** $X,XXX.XX  •  **Total withdrawals:** $X,XXX.XX  •  **Net:** $±X,XXX.XX

## Account integrity

(Only include if anomalies found.) Misfiled PDFs, reconciliation failures, etc.

## Subscriptions

| Merchant | Amount | Cadence | Last charge | Annual | Status |
|---|---|---|---|---|---|
| ... | ... | ... | ... | ... | ✓ known / NEW |

**Total monthly burn:** $X.XX  ($XX/yr)

## Suspicious / unverified

| Date | Merchant | Amount | Why flagged |
|---|---|---|---|
| ... | ... | ... | ... |

## Spending breakdown

(Top merchants, categories, largest transactions, net flow.)

## What to do

1. Confirm UNKNOWN MERCHANT X — bank? add to known? dispute?
2. ...
```

Open the report with a one-line headline summarizing the run. End with a **What to do** numbered list — each item answerable by number when the user reviews.

## Step 9 — Update state

After the report is written:

1. **Update `scanned-pdfs.json`** — add an entry for each PDF that successfully reconciled, with its MD5, ISO timestamp, and transaction count. Skip files that failed reconciliation. Use a single `Write`.
2. **Don't auto-update `known-merchants.json`.** Wait for the user to respond to the "What to do" list. When they say "add X and Y to known," merge those entries (preserving existing ones) and write back.

## Gotchas

**Merchant name variations.** "AMZN MKTP", "AMAZON.COM", "AMAZON PRIME" all hit the same parent but mean different things — Marketplace = purchases (variable), Prime = subscription (fixed annual/monthly). Normalize for grouping but preserve the raw string in the report so the user can verify.

**Account-folder mismatch.** Folder names like `MAIN...7723` encode the last 4 of the account number. PDFs may be misfiled. Check `pages[0]` for `Account number:` and compare. Misfiled files should be reported as a top-level integrity issue, not silently included.

**Annual subscriptions hide as one-offs.** A single $99 charge from a SaaS isn't a one-off if it shows up every December. Cadence detection needs cross-statement data — re-extract older scanned PDFs when the user asks for subscriptions, don't only rely on new ones.

**Pending vs posted.** Pending charges can disappear or change amount when posted. If the PDF labels charges "pending," call them out separately and don't sum them into spending totals.

**Refunds and reversals.** A debit followed by an equal credit days later is a refund, not net spend. Match charge/credit pairs by merchant + amount before summing categories.

**Hold-then-settle (gas, hotels, restaurants).** Common pattern: $1 hold → real charge a day later. Don't flag both as duplicates. If two same-merchant charges are within 72h and one is a tiny round number, treat as a single transaction.

**Don't moralize.** The user wants numbers, not opinions. Never write "you should cut back on X" or "this is a lot for Y." Report totals; let the user decide. This is a hard rule — financial advice unsolicited is irritating and out of scope.

**Privacy.** Statement contents are sensitive. Don't search the web for unfamiliar merchant names by default — the merchant string can leak transaction context. If the user asks "what is XYZ?", confirm before searching, and only send the merchant name (no dates/amounts).

**No bad-data audits.** If parsed totals don't reconcile against the statement summary, exclude that PDF and report the parse failure. An audit on misread data is worse than no audit — false flags will be confidently wrong.

**Don't auto-acknowledge.** `known-merchants.json` only grows by explicit user confirmation. A merchant being "seen before" doesn't mean it's verified.

**Statement period boundaries.** A "monthly" subscription that's really every 30 days drifts across statement boundaries — it might appear once in March and twice in April. Use rolling cadence detection, not per-statement counts.

**Same UUID, different content.** Statement PDFs are sometimes named with UUIDs that collide between accounts. Always use MD5 (not filename) to decide if a PDF was already scanned.

## Operational notes

- **Trust `transactions` from the script.** It already does column-aware parsing for the standard Wells Fargo layout. Don't re-parse raw text or words unless `transactions` is empty.
- **Don't load full PDFs into context.** Extraction writes to `/tmp/audit-extract-<account>.jsonl`; work from the structured `transactions` field, not the raw `pages` text or `words` array.
- **One report per account per run.** Don't iterate on partial reports; gather all data, then write one report at the end.
- **Multi-account runs are sequential.** Process each subfolder, write its report, update its state, then move to the next. Don't intermix accounts in one report.
