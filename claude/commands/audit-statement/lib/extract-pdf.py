#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.10"
# dependencies = ["pdfplumber>=0.11"]
# ///
"""
Extract text from bank/credit-card statement PDFs.

Usage:
  extract-pdf.py <file-or-dir> [--json]

Prints extracted text to stdout. With --json, prints
{"file": ..., "pages": [...], "tables": [...]} per PDF as JSONL.

Dependencies are managed via PEP 723 inline metadata; uv creates a
cached venv on first run.
"""
import argparse
import json
import re
import sys
from pathlib import Path

import pdfplumber

DATE_RE = re.compile(r"^\d{1,2}/\d{1,2}$")
AMOUNT_RE = re.compile(r"^-?\$?[\d,]+\.\d{2}$")


def extract_words_with_columns(page) -> list[dict]:
    """Return each word with its x/y position so callers can reconstruct columns."""
    words = page.extract_words(use_text_flow=True, keep_blank_chars=False)
    return [
        {
            "text": w["text"],
            "x0": round(w["x0"], 2),
            "x1": round(w["x1"], 2),
            "top": round(w["top"], 2),
            "bottom": round(w["bottom"], 2),
        }
        for w in words
    ]


def group_words_by_line(words: list[dict], y_tolerance: float = 3.0) -> list[list[dict]]:
    """Cluster words into visual rows by y-coordinate (handles 2-line wraps)."""
    if not words:
        return []
    sorted_words = sorted(words, key=lambda w: (w["top"], w["x0"]))
    lines: list[list[dict]] = []
    current: list[dict] = [sorted_words[0]]
    for w in sorted_words[1:]:
        if abs(w["top"] - current[-1]["top"]) <= y_tolerance:
            current.append(w)
        else:
            lines.append(sorted(current, key=lambda x: x["x0"]))
            current = [w]
    lines.append(sorted(current, key=lambda x: x["x0"]))
    return lines


def parse_amount(s: str) -> float | None:
    s = s.strip().replace("$", "").replace(",", "").replace(" ", "")
    if not s:
        return None
    if AMOUNT_RE.match(s.replace(" ", "")):
        try:
            return float(s)
        except ValueError:
            return None
    return None


def find_column_anchors(words: list[dict]) -> dict | None:
    """Locate column-header positions for the transaction table.

    Text columns (date, description) are left-aligned: store x0 (left edge).
    Amount columns (deposit, withdrawal, balance) are right-aligned: store x1.
    Returns None if header line not found.
    """
    targets = {
        "date": "Date",
        "description": "Description",
        "deposit": "Additions",
        "withdrawal": "Subtractions",
        "balance": "balance",
    }
    lines = group_words_by_line(words)
    best_line, best_hits = None, 0
    for line in lines:
        line_texts = {w["text"] for w in line}
        hits = sum(1 for t in targets.values() if t in line_texts)
        if hits > best_hits:
            best_hits, best_line = hits, line
    if not best_line or best_hits < 4:
        return None

    anchors: dict = {"_header_top": best_line[0]["top"]}
    for col, label in targets.items():
        for w in best_line:
            if w["text"] == label:
                # text columns: anchor on left edge; amount columns: right edge
                anchors[col] = w["x0"] if col in ("date", "description") else w["x1"]
                break
    return anchors


def assign_column(word: dict, anchors: dict) -> str:
    """Route a word to a column by its alignment.

    Amounts (parseable as $X.XX) snap to the nearest amount column's right edge.
    Other tokens snap to the nearest text column's left edge. This split avoids
    description text leaking into the deposit column and vice versa.
    """
    is_amount = parse_amount(word["text"]) is not None
    if is_amount:
        candidates = [
            (k, anchors[k]) for k in ("deposit", "withdrawal", "balance") if k in anchors
        ]
        return min(candidates, key=lambda kv: abs(kv[1] - word["x1"]))[0]
    candidates = [
        (k, anchors[k]) for k in ("date", "description") if k in anchors
    ]
    return min(candidates, key=lambda kv: abs(kv[1] - word["x0"]))[0]


def parse_transactions(words: list[dict], page_num: int) -> list[dict]:
    anchors = find_column_anchors(words)
    if not anchors:
        return []
    header_top = anchors["_header_top"]

    lines = group_words_by_line(words)
    txns: list[dict] = []
    current: dict | None = None

    for line in lines:
        if not line or line[0]["top"] <= header_top + 2:
            continue

        buckets: dict[str, list[str]] = {
            "date": [], "description": [], "deposit": [],
            "withdrawal": [], "balance": [],
        }
        for w in line:
            col = assign_column(w, anchors)
            buckets[col].append(w["text"])

        date_str = " ".join(buckets["date"]).strip()
        desc_str = " ".join(buckets["description"]).strip()
        deposit = parse_amount(" ".join(buckets["deposit"]))
        withdrawal = parse_amount(" ".join(buckets["withdrawal"]))
        balance = parse_amount(" ".join(buckets["balance"]))

        if DATE_RE.match(date_str):
            if current:
                txns.append(current)
            current = {
                "page": page_num,
                "date": date_str,
                "description": desc_str,
                "deposit": deposit,
                "withdrawal": withdrawal,
                "balance": balance,
            }
        elif current is not None:
            if desc_str:
                current["description"] = (current["description"] + " " + desc_str).strip()
            # rare: continuation line carries trailing balance
            if balance is not None and current["balance"] is None:
                current["balance"] = balance

    if current:
        txns.append(current)
    return txns


def extract_one(path: Path, as_json: bool) -> None:
    try:
        with pdfplumber.open(path) as pdf:
            pages_text = []
            transactions = []
            words_by_page = []
            for i, page in enumerate(pdf.pages, start=1):
                pages_text.append(page.extract_text() or "")
                page_words = extract_words_with_columns(page)
                words_by_page.append({"page": i, "words": page_words})
                transactions.extend(parse_transactions(page_words, i))
    except Exception as e:
        print(f"ERROR reading {path}: {e}", file=sys.stderr)
        return

    if as_json:
        print(json.dumps({
            "file": str(path),
            "pages": pages_text,
            "transactions": transactions,
            "words": words_by_page,
        }, ensure_ascii=False))
    else:
        print(f"===== {path} =====")
        for i, txt in enumerate(pages_text, start=1):
            print(f"--- page {i} ---")
            print(txt)
        if transactions:
            print(f"--- parsed transactions ({len(transactions)}) ---")
            for t in transactions:
                amt = t["deposit"] if t["deposit"] is not None else (
                    -t["withdrawal"] if t["withdrawal"] is not None else 0
                )
                bal = f"  bal={t['balance']:>9.2f}" if t["balance"] is not None else ""
                print(f"  p{t['page']} {t['date']:>5}  {amt:>+9.2f}  {t['description'][:60]:<60}{bal}")


def collect_pdfs(target: Path) -> list[Path]:
    if target.is_file():
        return [target] if target.suffix.lower() == ".pdf" else []
    if target.is_dir():
        return sorted(target.rglob("*.pdf"))
    print(f"ERROR: not a file or dir: {target}", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("target", help="PDF file or directory of PDFs")
    ap.add_argument("--json", action="store_true", help="JSONL output")
    args = ap.parse_args()

    pdfs = collect_pdfs(Path(args.target).expanduser())
    if not pdfs:
        print("No PDFs found.", file=sys.stderr)
        sys.exit(1)

    for p in pdfs:
        extract_one(p, args.json)


if __name__ == "__main__":
    main()
