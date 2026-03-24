---
name: factory:patrol:cases
model: opus
description: Case system patrol mode. Scans assigned cases via sqlsrv MCP, checks notes for updates, generates prioritized TODO items. Designed for /loop. Triggers on: case patrol, check cases, case mode, patrol cases, my cases, case todos
---

# Factory Patrol — Case Mode

Read `factory/patrol/SKILL_BASE.txt` and internalize the shared lifecycle before proceeding. This mode extends the base with case-system-specific scanning, triage, and output.

## Constants

```
USER_ENTITY = "TAGClient-NellisD"
SPRINT_PARENT_FOLDER = 418
STATE_FILE = "case-state.json"
OUTPUT_FILE = "case-todos.md"
```

## State Schema

Extends the base `last_run` with case-specific tracking:

```json
{
  "last_run": "ISO-8601 | null",
  "current_sprint": {
    "folder_id": 999,
    "name": "Sprint Name"
  },
  "cases_seen": {
    "<case_id>": {
      "last_status": "In Progress",
      "last_case_type": "High",
      "last_note_count": 5,
      "last_checked": "ISO-8601",
      "disposition": "flagged|logged|deferred"
    }
  },
  "notes_watermark": {
    "<case_id>": "ISO-8601 of newest note seen"
  }
}
```

## Mode Phases

### Phase 1 — Detect Current Sprint

Query via sqlsrv MCP:
```
query table="t_folder" where="ParentId = 418" order="FolderId DESC" pageSize=1
```
Store the result as `current_sprint` in state. If query returns nothing, log a warning and scan all active cases without sprint filtering.

### Phase 2 — Scan Cases

Spawn a **Haiku subagent** that uses the sqlsrv MCP to run these queries:

**Query 1 — Current sprint cases assigned to me:**
```
query table="cases"
  where="VoidDate IS NULL AND CompleteDate IS NULL AND AssignedTo = 'TAGClient-NellisD' AND MilestoneId = {current_sprint.folder_id}"
  order="CASE CaseType WHEN 'Urgent' THEN 1 WHEN 'High' THEN 2 WHEN 'Medium' THEN 3 ELSE 4 END, DueDate ASC"
  pageSize=50
```

**Query 2 — Unassigned-to-sprint cases assigned to me:**
```
query table="cases"
  where="VoidDate IS NULL AND CompleteDate IS NULL AND AssignedTo = 'TAGClient-NellisD' AND (MilestoneId IS NULL OR MilestoneId = 0)"
  order="CASE CaseType WHEN 'Urgent' THEN 1 WHEN 'High' THEN 2 WHEN 'Medium' THEN 3 ELSE 4 END, DueDate ASC"
  pageSize=50
```

**Query 3 — Team-assigned cases in current sprint** (lower priority):
```
query table="t_TeamMateList" where="Employee = 'TAGClient-NellisD'"
```
Then for each team returned, query cases where `AssignedTo = {team}` using the same filters as Query 1.

The subagent returns the combined, deduplicated case list with all columns.

### Phase 3 — Scan Notes

For each case from Phase 2, spawn **Haiku subagents** (batch ~10 cases per subagent) to query:

```
query table="Notes"
  where="VoidDate IS NULL AND ItemType = 'Case' AND Item = {case_id}"
  order="CreatedDate DESC"
  pageSize=20
```

**For each case, the subagent determines:**

1. **New notes since last run** — compare `CreatedDate` against `notes_watermark[case_id]`
2. **Notes from others** — `Creator != 'TAGClient-NellisD'`
3. **Critical notes** — `Critical IS NOT NULL`
4. **Unread thread activity** — notes in a ThreadId where the latest reply is not from you
5. **Keyword signals** in note text:
   - Waiting/blocking: "waiting", "pending", "blocked", "need", "hold"
   - Questions: ends with "?"
   - Urgency: "urgent", "asap", "critical", "immediately"
   - Mentions: "Derek", "NellisD", "TAGClient-NellisD"

The subagent returns per-case note summaries:
```json
{
  "case_id": 1234,
  "total_notes": 12,
  "new_notes": 2,
  "new_notes_from_others": 1,
  "has_critical": false,
  "has_unanswered_question": true,
  "keyword_flags": ["waiting"],
  "latest_note_summary": "John asked: are we still blocked on the API change?",
  "latest_note_date": "ISO-8601",
  "latest_note_creator": "TAGClient-SomeoneElse"
}
```

### Phase 4 — Triage & Score

Calculate a priority score for each case. Higher = more urgent.

```
Score = (CaseType x 100) + (DueDate Urgency x 50) + (Note Signals x 25)

CaseType:
  Urgent = 4, High = 3, Medium = 2, Low = 1

DueDate Urgency:
  Overdue = 5
  Due today or tomorrow = 4
  Due in 2-3 days = 3
  Due in 4-7 days = 2
  Due > 7 days or no due date = 1

Note Signals (additive):
  New critical note = +4
  Unanswered question from someone else = +3
  New note from someone else (non-question) = +2
  Keyword flags (waiting/blocked/urgent) = +2
  Mention of you in note = +1
  No new notes = 0
```

**Classify into tiers:**

| Tier | Score Range | Meaning |
|---|---|---|
| **Action Needed** | 500+ | Urgent cases, overdue, critical notes, unanswered questions |
| **Attention** | 300-499 | High priority, approaching due dates, new activity |
| **Monitor** | 150-299 | Medium priority, in progress, no flags |
| **Backlog** | < 150 | Low priority, no sprint, no urgency |

**Change detection:**
- If a case was `logged` last run and now scores higher -> promote to `flagged`
- If a case has no state changes AND no new notes since last run -> skip output (don't re-notify)
- New cases (not in `cases_seen`) always get included regardless of score

### Phase 5 — Generate TODOs

**Only generate output if there are new findings** (new cases, score changes, new notes). If nothing changed, no-op per base rules.

Write to `.factory/patrol/case-todos.md` (snapshot, overwritten each run):

```markdown
# Case TODOs — {YYYY-MM-DD HH:MM}

**Sprint:** {sprint name} | **Entity:** TAGClient-NellisD
**Cases scanned:** {N} | **Action needed:** {N} | **New notes:** {N}

---

## Action Needed

### #{CaseId}: {CaseTitle}
**Type:** {CaseType} | **Status:** {DevStatus} | **Due:** {DueDate} | **Score:** {score}
**Folder:** {FolderName} | **Sprint:** {yes/no/backlog}

> **Latest note** ({Creator}, {relative time}):
> "{first 200 chars of note}"

**Why flagged:**
- {reason: e.g., "Unanswered question from John (2h ago)"}
- {reason: e.g., "Overdue by 3 days"}

**Action items:**
- [ ] {specific action based on context}

---

## Needs Attention

### #{CaseId}: {CaseTitle}
...

---

## Monitoring (no action needed)

| Case | Type | Status | Due | Last Activity |
|---|---|---|---|---|
| #{id}: {title} | {type} | {status} | {due} | {relative time} |

---

## Backlog (unassigned sprint)

| Case | Type | Status | Created |
|---|---|---|---|
| #{id}: {title} | {type} | {status} | {date} |
```

**Contextual action items:**
- DevStatus = `Need Info` + unanswered question -> "Reply to {Creator}'s question about {topic}"
- DevStatus = `Awaiting PR` -> "Check PR for review feedback"
- DevStatus = `In Discussion` + new notes -> "Read new discussion thread and respond"
- DueDate overdue -> "Update due date or complete case"
- New note with keyword "waiting" -> "Unblock: {Creator} is waiting on {context}"
- CaseType upgraded (was Medium, now Urgent) -> "Escalation: priority changed, review case"

## Notify Threshold

- `action-needed` severity if any case scores >= 500
- `info` severity if only attention-tier changes exist
- Silent (no notify) if only monitor/backlog changes

## Hard Constraints

- **Never modify cases.** This is read-only. No updating DevStatus, no reassigning, no closing. Observe and report.
- **Never create branches or code fixes from cases.** Case mode creates awareness, not work. The user decides what to act on.
- **Respect note privacy.** Summarize notes, don't dump full text. Keep excerpts under 200 chars.
- **New notes are the primary signal.** A case with no new notes since last run is not interesting unless its score changed (e.g., DueDate crossed a threshold).
- **Team cases are secondary.** Directly assigned cases always rank above team-assigned cases at the same score level.

## Gotchas

- **sqlsrv MCP is hitting a real database.** Queries are read-only SELECTs, but be mindful of volume. Batch note queries via subagents, don't query 100 cases individually.
- **Sprint detection can fail.** If `t_folder` returns nothing for ParentId=418, log a warning and scan all active cases. Don't crash.
- **Notes table uses `Item` (INT) as the FK to CaseId.** The `ItemType` must be `'Case'` to filter correctly. Other ItemTypes exist (LS1, Timesheet, PayDetail).
- **`AssignedTo` stores entity codes, not display names.** Always filter by `TAGClient-NellisD`, not "Derek Nellis".
- **DueDate can be NULL.** Cases without due dates score 1 on DueDate Urgency — not urgent but not invisible.
- **DevStatus values are case-sensitive string literals:** `'In Progress'`, `'Need Info'`, `'In Discussion'`, `'Done'`, `'Awaiting PR'`, `'Testing'`, `'Releasing'`, `'Stage'`, `'Communicate'`.
- **`CompleteDate IS NULL` filters out completed cases.** Don't rely on DevStatus='Done' alone — a case can be Done but not formally completed.
