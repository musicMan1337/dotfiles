# Case system, endpoint spec

Everything needed to drive the Viper case system over HTTP. Written so no
production source reading is required. Paths are relative to
`https://my.ebacon.com/index.php/`, and `vcurl` takes them exactly as written.

## Rules that apply to every call here

- **These controllers live under `rest/`.** `caseREST/case` is a 404;
  `rest/caseREST/case` is the endpoint.
- **The actor comes from the session.** `User` / `Entity` / the acting `Client`
  are read from the PHPSESSID. Where a body field named `Client` or `CaseClient`
  exists it means *the case's* client, not who you are. `case_post` pins the
  creator to the session on purpose, so cross-client creation is not possible.
- **Form-encode. Never `Content-Type: application/json`.** CI3 reads `$_POST`,
  which PHP fills only for form-encoded bodies, so a JSON body makes every field
  arrive as `false` and the write silently does nothing.
- **A missing param is `false`, not an error.** Most of these endpoints have no
  validation, so a mistyped field name is an empty write, not a 400. Get the
  capitalization right; it is inconsistent across the file and is listed exactly
  below.
- **Notes on a case use `itemType=Case`, `item=<CaseID>`.** Confirmed against the
  case screen's own loader.
- `TAGClient` is the internal client. Several endpoints 400 with
  `{"Error":"Not logged in as TAG"}` when the session client is anything else.

## Reads

| Path | Params | Returns |
| --- | --- | --- |
| `rest/caseREST/case` | `CaseID`, `Client` | One case row, or `[]`. Cheap. No validation, so a bad id is `[]` not 404. |
| `rest/caseREST/AllCaseDetail` | `CaseID`, `User`, `Client` (all required) | The whole page in one call: case plus `Notes`, `ClientNotes`, `ToDos`, `ToDoIDs`, `History`, `files`, `Picklists`, `Subscribers`, description already decoded. 404 if no such case. Fans out to ~8 queries, so treat it as a page load, not a poll. |
| `rest/caseREST/CaseHistory` | `CaseID`, `Client` | `log_case` trail, `OldValue`/`NewValue` strip_tags'd. |
| `rest/caseREST/searchCases` | `Term`, `Client` | Title/description search. |
| `rest/caseREST/getClientCases` | `client` (lowercase, defaults to session client) | Every case for a client, each with a `Subscribers` array. |
| `rest/caseREST/caseAttributes` | `Entity` | Cases assigned to, created by, or noted on by that entity. |
| `rest/caseREST/caseFeedy` | none | Activity feed for the session's own entity. |
| `rest/caseREST/CasesInFolder` | `FolderId`, `Client`, `User` | Cases in a folder. `FolderId=SearchMe:<term>` switches it to an Elasticsearch search that can return **503** when ES is down. No validation on any param. |
| `rest/caseREST/casesInParentFolder` | `User` (required), `FolderId`, `FolderName` | Cases under a parent folder. The one endpoint that **400s on an empty result** instead of returning `[]`. |
| `rest/caseREST/menuFolder` | `FolderId` (optional), `entity` | Folder tree, or one folder when `FolderId` is given. |
| `rest/caseREST/newFolderLists` | `client` | `{names, prefixes}` across all folders. TAGClient only. |
| `rest/caseREST/caseSubscribers` | `ItemType=Case`, `Item=<CaseID>` | Subscriber rows. |
| `rest/caseREST/caseTemplate` | none | Legacy case templates. |
| `rest/caseREST/projectTemplates` | none | Project template list (metadata only). |
| `rest/caseREST/projectTemplate` | `TemplateId` | One template with full `TemplateData`. 404 if absent. |
| `rest/caseREST/newCaseLists` | `client` | Picklists for the new-case form (types, statuses, assignees, folders, milestones). TAGClient only. |
| `rest/notes/enhancedNote` | `itemType=Case`, `item`, `client` (**all lowercase**, all required) | Notes decorated with `ProfilePhoto`, `Initials`, `ConcatName`, oldest first. |
| `rest/viperToDo/list` | `itemType=Case`, `item`, `client` | Plain checklist todos. `204` when empty. |
| `rest/viperToDo/projectItems/<CaseID>` | CaseID in the **path** | Project-grid rows plus categories and metadata. Writes before it reads (reconciles todo complete-dates), so it is not a pure GET. |
| `rest/viperToDo/projectSummary/<CaseID>` | CaseID in the **path** | Per-category completion counts. |

## Writes

### Add a note, `POST rest/notes/enhancedNote`

Fields are **lowercase**: `itemType=Case`, `item=<CaseID>`, `client`, `note`.
Returns the full refreshed note list at **201**. Optional `NoteId` turns it into
an edit; `Mode=void` with a `NoteId` voids. This endpoint silently drops
`Mentions` even if sent, so for an @-mention use `rest/shared/notes` instead.

### Create a case, `POST rest/caseREST/newCaseCreate`

Prefer this over `rest/caseREST/case`; it is the one the new-case form uses and it
handles templates, attachments and linking.

Required: `Entity`, `Client`, `CaseTitle`, `CaseDescription`.
Optional with defaults: `AssignedTo=Queue`, `CaseClient=<Client>`, `CaseType=Low`,
`DevCaseType=Bug`, `DevRanking=1`, `DevStatus=In Discussion`, `FolderId=0`,
`PublicYn=0`, `ClientCreated=0`, `EmailClientsSubscription=0`,
`AdditionalFolderIds=0`, plus `DueDate`, `MilestoneId`, `ProjectDuration`, `Tags`,
`SubscriptionList`, `ClientSubscriptionList`, `LinkedCaseId`, `ProjectTemplateId`.

Answers **201**. Side effects worth knowing before firing it at production: it
sends subscriber email, it logs the entire request body verbatim to the data log,
a non-empty `ClientSubscriptionList` silently forces `PublicYn=1`, a
`ProjectTemplateId` bulk-creates child tasks, and a `LinkedCaseId` writes a todo
onto that *other* case. `ClientCreated=0` from a non-TAGClient session is a 400.

### Change fields on a case, `POST rest/caseREST/updateCaseDetail`

**This is a full replace of eighteen columns, not a patch.** Read the case first
and resend every field, or you will blank the ones you left out.

Required: `CaseID`, `AssignedTo`, `CaseTitle`, `CaseDescription`, `CaseType`,
`CaseClient`, `FolderId`, `MilestoneId`, `Duration`, `DevStatus`, `DevRanking`,
`DevCaseType`.
Optional: `DueDate` (`m/d/Y`; unparseable is silently dropped to null), `Tags`,
`PublicYn`, `ClientCreated`, `HidePrefixYN`, `InternalConfidential`,
`AdditionalFolderIds`, `ChangeLog[]`.

Errors: **422** if the result would be both public and confidential. **400** if the
case is `DevCaseType=Implementation` and you change `DevCaseType`, `DevStatus`,
`PublicYn` or `CaseClient`.

`ChangeLog` is what writes the visible history, and it is **caller-declared, not
server-diffed**. Each element is `{Attribute, OldValue, NewValue}`. Send one per
field you actually changed; send none and the edit happens with no history entry
at all.

The project columns are the exception, they patch normally, but they are split
across two endpoints (verified in `caseREST.php` 2026-09-09):
- `POST rest/caseREST/projectMetaSave`: `CaseID` plus any of `ProjectStatus`,
  `ProjectStatuses`, `ProjectCustomDates`, `ProjectCustomFields`. **It ignores
  `ProjectCategories`** and does not take `ProjectStartDate` / `ProjectTargetDate`.
- `POST rest/caseREST/projectCategoryRename`: `CaseID`, `ProjectCategories` (the
  JSON array `[{"name","sort","color"}]`). Without `OldCategoryName` /
  `NewCategoryName` it is a plain save; with them it also cascades the rename to
  every `EmployeeToDo.Category` row. Backed by sproc `ProjectCategorySave`.
`ProjectStartDate` / `ProjectTargetDate` go through `updateCaseDetail`.

### State changes

`POST rest/caseREST/completeCase`, `.../voidCase`, `.../reOpenCase`, each taking
`CaseId` and `Client`. Note the casing: **`CaseId`**, not `CaseID` as everywhere
else. All three answer **200 whatever happens**, including when nothing matched,
so confirm the result by re-reading the case rather than trusting the status.

### Tags, `PUT rest/caseREST/caseTags`

`CaseId`, `Tags`. Full replace of the tag column; sending it without `Tags` wipes
them. Merge client-side by reading the case first.

### Subscribers

- `POST rest/caseREST/caseSubscribers`: `ItemType=Case`, `Item`, `SubscriptionList`,
  `caseTitle`, `description`. Likely sends notification email.
- `PUT rest/caseREST/changeCaseSubscriber`: `ItemType`, `Item`, `caseTitle`,
  `description` required, plus `Added` and `Removed`. **`Added` is pipe-delimited
  and `Removed` is comma-delimited.** Not a typo, and an easy way to get it wrong.
- `PUT rest/caseREST/caseSubscribers`: `ItemType`, `Item`, `EntityList` to remove only.

### Project grid, `POST rest/viperToDo/projectItem`

`Mode` and `CaseID` required; entity and client come from the session. `Mode` is
`Create`, `Update`, `Status`, `Delete`, or `ConvertToCase`. Row fields: `RowId`
(everything but Create), `Title`, `Category`, `AssignedTo`, `Priority`, `DueDate`,
`StartDate`, `SortOrder`, `Effort`, `Dependencies`, `Tags`, `Status`,
`LinkedDocumentId`, `FolderId`, `LinkedCaseId`.

`Create` answers 201 and returns the new row; everything else answers 200.
`ConvertToCase` creates a whole new case and links it.

**`Dependencies` is a JSON array of `RowId`s on the same project, e.g. `[57533, 57540]`**,
not free text: sproc `ProjectItemUpsert` runs `OPENJSON` over it for the cycle walk, so any
other shape is a **400 with the generic body `An Error Has occurred`** (measured 2026-09-09).
A real cycle comes back as 400 `CIRCULAR_DEPENDENCY`. The walk also `OPENJSON`s the
`Dependencies` of every row it reaches, so a board whose rows were seeded with prose in that
column (354820 and 193273 as of 2026-09-09) will 400 on any later JSON dependency that points
at one of them.

`Status` is not written on `Create` (the sproc's INSERT omits it; the row reads `''`); use
`Mode=Status` afterwards. A `Create` or `Update` carrying `LinkedCaseId` then runs
`setLinkedCase`, which copies `LinkedCaseTitle`, `AssignedTo` and `DueDate` from the case over
whatever you sent; omit `LinkedCaseId` on an `Update` that only fixes card fields.

**`Update` zeroes `SortOrder` unless you send it.** The sproc declares `@SortOrder INT = 0` and
writes `SortOrder = @SortOrder` unconditionally, while every other card column is
`ISNULL(@x, x)`. Always include `SortOrder` on an `Update` (measured 2026-09-09: three cards
dropped to 0 from a Priority-only Update).

**Card `Priority` is not settable here.** Whatever you send, the stored value ends up equal to
the linked case's `CaseType` (Create and Update both, 2026-09-09; the mechanism is not in
`viperToDo.php`, `viperToDoModel.php` or a Stage trigger). Change the case's `CaseType` via
`updateCaseDetail` if the card's priority matters.

## The master board, case 359690 (Derek's hub)

One project case (`DevStatus = Project`) carrying a card for every thread Derek owns,
grouped by subject rather than sprint. Start every "what am I carrying" question here,
and give every new case of his a card here unless the membership rule below says not to.

**Lanes** (`ProjectCategories`, exact strings): `Access Control`, `Secrets Management`,
`Data Protection`, `Vulnerability Management`, `Security Governance`,
`CI3 to CI4 Migration`, `Database Platform`, `Product & Support`.

**Membership rule.** A card is either a *project anchor* (a case with its own board) or a
case that lives on no other board. Children of an anchor's board never get a second card
here: CI4 ports under 349659, Snout services under 354820, OSV repos under 355681,
encryption work under 193273, audit work under 359770. Cases Derek only subscribes to go
in `Product & Support` or nowhere.

**Anchors and their own boards** (2026-09-09): 349659 CI3-to-CI4 (wave lanes), 354820 Snout
Rollout (4 lanes), 355681 Vuln-OSV-2026 (quarter lanes), 193273 Encryption (`Prerequisites`,
`Replica & Testing`, `Encryption at Rest`, `Backups`), 353886 tempdb, 359770 SQL Server
Audit (`Statement Audit`, `Human Session Controls`). 354820 and 193273 carry prose in
`Dependencies` on most cards; see the trap under Project grid.

**What each card field means on the hub.** `Category` is the lane. `SortOrder` is the
position within the lane, 0-based, gaps allowed. `Effort` is `S`/`M`/`L`. `Dependencies`
is the RowIds of the cards that gate this one, and the board draws the chain from it.
`Priority` is derived from the case's `CaseType` and cannot be set. Hub cards carry no
`StartDate`/`DueDate`; dates live on the case.

**Scoping rule Derek applies before a case earns a card** (stated 2026-09-09): one case
gathers or builds, another executes or tests; a case with two owners' work in it is too
wide. When a case is too wide, narrow it with `updateCaseDetail` (full field list plus a
`ChangeLog` entry per changed field) and create the split-off cases, each with its own
card gated on the original.

### Hub recipes

```bash
# the board, by linked case
vcurl GET rest/viperToDo/projectItems/359690
vcurl GET rest/viperToDo/projectSummary/359690          # counts per lane

# card for an existing case: read the lane's max SortOrder first; omit Priority (derived)
vcurl POST rest/viperToDo/projectItem Mode=Create CaseID=359690 Title='Case #359850' \
  Category='Access Control' LinkedCaseId=359850 AssignedTo=TAGClient-NellisD \
  SortOrder=3 Effort=L Dependencies='[57381]'

# new case + card: no LinkedCaseId on newCaseCreate (that todo would land without a lane);
# capture the id, then the Create above. A card created earlier in the same run can be a
# dependency once its RowId is read back from projectItems.
vcurl POST rest/caseREST/newCaseCreate Entity=TAGClient-NellisD Client=TAGClient \
  AssignedTo=TAGClient-NellisD CaseClient=All DevCaseType=Security DevStatus='In Discussion' \
  MilestoneId=1160 CaseTitle='...' CaseDescription='<h3>Why</h3>...'

# a note that references a case created in the same run: create first, post the note last
```

Milestone ids that matter here: `1159` Q3 2026, `1160` Q4 2026, `1211` Q1 2027, `1156`
the year 2026 (used for long-lived project anchors). Weekly sprint folders (`1221` = Sep
7-11 2026, under parent 418) also satisfy `MilestoneId`; the hub deliberately does not use
them.

### The batch driver, `scripts/board-batch.py`

Every multi-write change to the hub on 2026-09-08/09 (24, 19, 11, 3, 2, 3, 3, 11 POSTs) ran
through the same shape, now kept as `scripts/board-batch.py <plan.json> --dry-run|--live`.
The plan declares `board`, `lane`, `common` case fields, `new_cases` (each with
`DependsOnCases` = existing case ids and `DependsOnKeys` = keys of cases earlier in the same
plan), `patches` (`updateCaseDetail` from the live row, guarded on a phrase in the stored
description), and `notes` (posted last, `<KEY>` placeholders replaced by created ids,
idempotent by a `marker` substring; keep the marker free of backslashes, the stored JSON
escapes them). `--dry-run` runs the GETs and prints every POST with its full field list;
Derek approves that; `--live` aborts on the first non-2xx, writes created ids to
`<plan>-ids.json` as it goes, skips anything that already exists (by id file, by
`LinkedCaseId` on the board, by note marker), clears prose `Dependencies` on any card a new
card will depend on, and ends with a VERIFY pass that re-reads the lane and `Update`s any
card whose `SortOrder` drifted (sending `SortOrder`, `Category`, `Effort`, `Dependencies`).
Re-running a finished plan is a no-op.

## Recipes

**Read a case, everything at once**
```bash
vcurl GET rest/caseREST/AllCaseDetail CaseID=359706 User=TAGClient-NellisD Client=TAGClient
```

**Add a note**
```bash
vcurl GET  rest/notes/enhancedNote itemType=Case item=359706 client=TAGClient
vcurl POST rest/notes/enhancedNote itemType=Case item=359706 client=TAGClient note='Deployed and verified.'
```

**Change one field (the read-modify-write that a full replace forces)**
```bash
# 1. read current values
vcurl GET rest/caseREST/case CaseID=359706 Client=TAGClient
# 2. resend all twelve required fields, changing only DevStatus, and declare the history
vcurl POST rest/caseREST/updateCaseDetail \
  CaseID=359706 AssignedTo='TAGClient-NellisD' CaseTitle='<current>' \
  CaseDescription='<current>' CaseType='Low' CaseClient='TAGClient' \
  FolderId='<current>' MilestoneId='<current>' Duration='<current>' \
  DevStatus='Ready For Testing' DevRanking='<current>' DevCaseType='<current>' \
  'ChangeLog[0][Attribute]=DevStatus' 'ChangeLog[0][OldValue]=In Progress' \
  'ChangeLog[0][NewValue]=Ready For Testing'
# 3. confirm
vcurl GET rest/caseREST/CaseHistory CaseID=359706 Client=TAGClient
```

**Complete a case, then verify (the endpoint always says 200)**
```bash
vcurl POST rest/caseREST/completeCase CaseId=359706 Client=TAGClient
vcurl GET  rest/caseREST/case CaseID=359706 Client=TAGClient   # CompleteDate should be set
```

**Project case, read the grid**
```bash
vcurl GET rest/viperToDo/projectItems/359706
vcurl GET rest/viperToDo/projectSummary/359706
```

## Traps

- `CaseId` on complete/void/reopen, `CaseID` almost everywhere else, `caseId` on
  the zip downloads. Copy the casing from the tables above.
- `rest/notes/enhancedNote` wants lowercase `itemType`/`item`/`client`, while
  `rest/caseREST/*` wants capitalized `CaseID`/`Client`. Same concepts, different
  shells.
- `CaseDescription` is stored with `%` escaped as `/%/`. `AllCaseDetail` decodes it
  for you; `rest/caseREST/case` does not. Writes run `encodeText()` (always escapes),
  so decode `/%/` back to `%` before resending or it double-escapes.
- `updateCaseDetail` syncs only `LinkedCaseTitle` onto linked board cards, not
  `AssignedTo`/`DueDate`. After a reassign, `projectItem Mode=Update` with `RowId`,
  `SortOrder`, `Category`, `LinkedCaseId` re-runs `setLinkedCase` to copy them.
- Weekly sprints live in `MilestoneId` (e.g. `1225` = Oct 5-9 2026), not `FolderId`;
  `newCaseLists` → `Milestones[label=Sprints]` lists them.
- Omitting `InternalConfidential` from `updateCaseDetail` **clears** the flag. The
  guard meant to preserve it is dead code, because CI3 returns `false` rather than
  `null` for an absent field.
- `PublicYn` and `ClientCreated` come back from reads as the strings `'True'` and
  `'False'`, and `MilestoneId`/`FolderId` come back as `'0'` when null. Convert
  before echoing them into a write.
- `projectItems` and `Mode=Status` both write while you are reading. Harmless, but
  do not treat them as side-effect-free.
- `rest/viperToDo/batchEmpToDo` returns only the **last** created todo, not the
  batch. Re-read the list to see them all.
- Stage and prod assign different ids to the same generator script: the case set that
  is 359453-359458 on Stage is 359685-359690 on prod. Never quote a Stage id as a prod
  case, and never run a hub write against the SQL MCP (Stage) expecting it to show here.
- A note-verification marker with a backslash never matches: the stored note is JSON-escaped
  (`TAGBIODOME\\viper`). Pick a marker substring without one.
