---
name: dev:viper-case-note
description: Leave a case note on a prod Viper case by triggering the merged `manual-case-note` GitHub workflow. Posts a `/case-note <caseId> <note>` comment on the current branch's PR; the workflow calls the `tagemployerservices/actions/case-note` action which writes the note to prod. Defaults the PR and case ID to whatever branch the session is on, unless overridden. Primarily for agents recording work on prod cases; devs can use it too. Triggers on, leave a case note, add a case note, note the case, post a case note, case note on the pr, record this on the case, viper case note, /case-note, /dev:viper-case-note.
---

# /dev:viper-case-note

Post a `/case-note <caseId> <note text>` comment on a Viper PR. That comment triggers the `manual-case-note.yml` workflow, which calls the `tagemployerservices/actions/case-note` action → `rest/api/github/caseNote` and writes the note onto the **prod** case. This command only leaves the comment; the workflow does the actual write and replies on the PR.

## Args

`$ARGUMENTS` may contain, in any order:

- A bare number (e.g. `349659`) : case ID override. Default: the case ID parsed from the current branch name (`<Name>/<CaseId>-<desc>`).
- `pr=<number|url>` : target PR override. Default: the open PR for the current branch.
- `--watch` : after posting, watch the triggered workflow run and report its result.
- `--dispatch` : trigger via `workflow_dispatch` instead of a PR comment (use when there is no PR). Requires a case ID.
- Any other free text : the note body. If omitted, compose a concise, outcome-focused note (1-2 sentences) from the current session's work.

## Steps

### 1. Resolve the case ID

Bare-number arg wins. Otherwise `git rev-parse --abbrev-ref HEAD` and take the first digits after the slash (`\/(\d+)/`, same rule the action uses on branch names). Must be numeric. If none can be derived (e.g. a `NoCase` branch) and none was given, stop and ask the user for the case ID; never guess it.

### 2. Resolve the target PR

`pr=` override wins (accept a number or a URL; extract the number). Otherwise `gh pr view --json number,url,state,headRefName` for the current branch. If there is no PR or its state is not `OPEN`, stop and offer numbered options: (1) open a PR first via `/git:pr`, (2) re-run with `pr=<n>`, (3) re-run with `--dispatch` (no PR needed), (4) cancel. Skip this step entirely under `--dispatch`.

### 3. Compose the note

Free-text note from the args is used verbatim. If none was given, write 1-2 sentences describing the outcome of the session's work, ready to stand alone on the case. Outcome-focused, no file lists, no attribution — the workflow prefixes the note with `GitHub /case-note from <actor>:` and substitutes the actor's display name, so do not add your own "by <name>".

### 4. Trigger

- **PR comment (default):** the body MUST begin with the pragma. Run from a Viper checkout so `gh` resolves the repo:
  `gh pr comment <pr-number> --body "/case-note <caseId> <note>"`
- **`--dispatch`:** `gh workflow run manual-case-note.yml -f case_id=<caseId> -f note="<note>"`

### 5. Report (and optional watch)

Print the comment URL (`gh pr comment` returns it). Note that the workflow reacts 🚀 then replies ✅/❌ on the PR. With `--watch`: find the run (`gh run list --workflow=manual-case-note.yml --limit 5 --json databaseId,status,conclusion,event,createdAt`, newest matching run), `gh run watch <id>`, and report success/failure. Watching is best-effort — matching the run to this comment is heuristic (newest `issue_comment` run).

## Gotchas

- **Prod write.** This lands a note on `my.ebacon.com`. The note's `Creator` column is `SystemUser`; only the note *text* carries the actor's display name.
- **author_association guard.** The commenter's GitHub account must be OWNER/MEMBER/COLLABORATOR or the workflow silently skips (no run, no reply). If nothing happens after posting, check that `gh auth status` is an org collaborator — or use `--dispatch`.
- **Pragma must lead.** The comment body has to *start* with `/case-note` (the workflow uses `startsWith`). Never prepend text to it.
- **Numeric case ID only.** NoCase branches have no default; the user must supply one.
- **Not on master/main.** There is no per-branch PR to comment on; use `--dispatch` or `pr=`.
