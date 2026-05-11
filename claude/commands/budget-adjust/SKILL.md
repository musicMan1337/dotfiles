---
name: budget-adjust
model: sonnet
description: Adjust Boo Boo Budget — expenses, salary, paystub updates. Triggers on: budget, add expense, update salary
---

# Budget Adjust

You manage Derek's personal budget spreadsheet ("Boo Boo Budget"). Both an Excel file and a markdown file must stay in sync.

## Files

- **Excel:** `/Users/derek/eBacon/obsidian/eBacon/finances/boo boo budget.xlsx` (sheet: `Budget (Updated)`)
- **Markdown:** `/Users/derek/eBacon/obsidian/eBacon/finances/Boo Boo Budget.md`
- **Lib scripts:** `~/.claude/commands/budget-adjust/lib/`
- **Structure reference:** `~/.claude/commands/budget-adjust/references/spreadsheet-structure.txt`

## How It Works

1. Read current budget state: `python3 ~/.claude/commands/budget-adjust/lib/budget-read.py`
2. Modify the JSON data model based on the user's request
3. Regenerate both files: `echo '<json>' | python3 ~/.claude/commands/budget-adjust/lib/budget-regen.py`

**Always read first, modify the JSON, then regenerate.** Never edit the Excel or markdown directly.

## Account Structure

| Account                         | What goes here                                                             |
| ------------------------------- | -------------------------------------------------------------------------- |
| **Ally > Housing**              | Rent, utilities, internet, parking, apartment-related                      |
| **Ally > Auto & Debt**          | Car payment, car maintenance, loans, debt                                  |
| **Ally > Savings**              | Savings goals, present fund                                                |
| **Lion** (sub-account of Ally)  | Gas, car insurance, verizon/phone, subscriptions — Lion is Derek's partner |
| **Doge**                        | Pet insurance, pet food, heartworm, pet expenses                           |
| **Wells Fargo** (Fixed)         | Groceries, credit card payments, regular bills                             |
| **Wells Fargo** (Discretionary) | Travel, dining, entertainment, allowance, personal subscriptions           |

When the user says "add to ally", determine the best sub-section. If ambiguous, ask.

When adding to **Lion subscriptions**, add to both the `lion` list (update the Subscriptions line item monthly total) AND the `subscriptions` detail list.

## Handling Salary Changes

If the user wants to update their salary:

1. **Require a paystub.** Tax withholding amounts depend on elections, not simple percentages.
2. If no paystub is provided, say: "To update your salary, I need your recent paystub so I can update tax withholding amounts too. Can you share the PDF or a screenshot?"
3. From the paystub, extract: salary, all tax line items (amounts), all deduction line items (amounts), and direct deposit splits.
4. Update the full `salary`, `pretax`, `aftertax`, `taxes`, `ally_deposit`, and `doge_deposit` fields.

## Workflow

1. Parse the user's request to determine: **action** (add/remove/update), **item name**, **monthly amount**, **target account/section**
2. Read current state via `budget-read.py`
3. Show the user what you're about to change (one sentence, e.g., "Adding 'Chase Credit Card' at $150/mo to Wells Fargo Fixed")
4. Modify the JSON
5. Pipe it to `budget-regen.py`
6. Confirm completion

## Gotchas

- **Lion subscriptions are tracked in two places**: the `lion` array has a "Subscriptions" line with the aggregate monthly, AND the `subscriptions` array has the individual services. If adding/removing a subscription, update BOTH — the detail list AND the aggregate total in `lion`.
- **Per-check is always monthly/2.** Never set per-check amounts directly. The Excel formulas handle this.
- **The unallocated amount is a formula.** It auto-calculates from: net take-home minus ally deposit minus doge deposit minus Wells Fargo expenses. Don't set it manually.
- **Wells Fargo deposit is a formula.** It's net minus ally minus doge. Don't set it.
- **Salary annual is the hardcoded input.** Per-check derives from `annual/24`.
- **Zero-amount discretionary items are intentional placeholders.** Don't remove them — they're budget categories the user may use later.
- **openpyxl must be installed.** If the scripts fail with import errors, run `pip3 install openpyxl --break-system-packages`.
