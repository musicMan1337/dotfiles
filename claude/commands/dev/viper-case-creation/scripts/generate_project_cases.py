#!/usr/bin/env python3
"""
Generate a dry-run SQL script that creates a Viper PROJECT case plus N linked
child cases and N linked todos, into /private/tmp/viper-sql/<slug>.sql.

This NEVER touches a database. It only writes a reviewable .sql file whose
transaction ROLLS BACK unless you set @Commit = 1 and re-run in SSMS.

The SQL structure here is proven schema-correct and trigger-safe against the
Viper cases / EmployeeToDo / t_folder schema. See the skill's SKILL.md for the
verified schema facts. Do not "simplify" the id-capture or milestone lookup
without re-verifying against the live schema.

Input (one of):
  --json  path/to/input.json   (project params + items; see schema below)
  --csv   path/to/items.csv     (items only; project params come from CLI flags)

JSON schema:
  {
    "project": {
      "name":          "CI3 Severe IDOR / AuthZ Findings",   # required; slug source
      "client":        "TAGClient",                          # default TAGClient
      "creator":       "TAGClient-NellisD",                  # default TAGClient-NellisD
      "assignee":      "TAGClient-NellisD",                  # default = creator
      "impact":        "High",                               # Low|Medium|High
      "todo_priority": "High",                               # Low|Medium|High|Urgent
      "milestone":     "Q3 2026",                            # folder name under t_folder 491; optional
      "confidential":  true,                                 # InternalConfidential 1/0
      "description":   "Free text project case description"  # optional
    },
    "items": [
      {"title":"...", "description":"...", "category":"...", "tags":"..."}
    ]
  }

CSV mode: the CSV must have header columns title,description,category,tags
(category/tags optional). Project params are supplied via CLI flags:
  --name, --client, --creator, --assignee, --impact, --todo-priority,
  --milestone, --confidential/--no-confidential, --description

Output: /private/tmp/viper-sql/<slug-of-project-name>.sql  (override with --out).
"""
import argparse
import csv
import json
import os
import re
import sys

OUT_DIR = os.path.expanduser("/private/tmp/viper-sql")

# Milestone folders are children of dbo.t_folder FolderId 491 (Name='Milestones');
# each child's FolderId IS cases.MilestoneId. This parent id is a verified schema fact.
MILESTONE_PARENT_FOLDER_ID = 491

IMPACTS = {"low", "medium", "high"}
PRIORITIES = {"low", "medium", "high", "urgent"}


def q(s):
    """T-SQL single-quote escape."""
    return (s or "").replace("'", "''")


def slugify(name):
    s = re.sub(r"[^a-zA-Z0-9]+", "_", (name or "").strip().lower()).strip("_")
    return s or "project_cases"


def title_case_word(v, valid, fallback):
    v = (v or "").strip()
    return v.capitalize() if v.lower() in valid else fallback


def load_json(path):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    proj = dict(data.get("project", {}))
    items = list(data.get("items", []))
    return proj, items


def load_csv(path):
    with open(path, encoding="utf-8-sig") as f:
        items = [dict(r) for r in csv.DictReader(f)]
    return items


def normalize_item(it):
    return {
        "title": (it.get("title") or "").strip(),
        "description": (it.get("description") or "").strip(),
        "category": (it.get("category") or "").strip(),
        "tags": (it.get("tags") or "").strip(),
    }


def build_project(proj, args):
    """Merge JSON project block with CLI overrides; CLI wins when provided."""
    def pick(key, cli, default):
        if cli is not None:
            return cli
        if proj.get(key) not in (None, ""):
            return proj[key]
        return default

    name = pick("name", args.name, None)
    if not name:
        sys.exit("error: project name required (JSON project.name or --name)")
    creator = pick("creator", args.creator, "TAGClient-NellisD")
    assignee = pick("assignee", args.assignee, creator)

    confidential = proj.get("confidential", True)
    if args.confidential is not None:
        confidential = args.confidential

    return {
        "name": name,
        "client": pick("client", args.client, "TAGClient"),
        "creator": creator,
        "assignee": assignee,
        "impact": title_case_word(pick("impact", args.impact, "High"), IMPACTS, "High"),
        "todo_priority": title_case_word(
            pick("todo_priority", args.todo_priority, "High"), PRIORITIES, "High"
        ),
        "milestone": pick("milestone", args.milestone, "") or "",
        "confidential": 1 if confidential else 0,
        "description": pick("description", args.description, "") or "",
    }


def milestone_block(milestone):
    """Resolve milestone by name -> MilestoneId. If none given, MilestoneId stays NULL.
    Never invent an id: if the name doesn't resolve, leave a commented manual-set line."""
    if not milestone:
        return (
            "/* No milestone requested; MilestoneId left NULL. To attach one, set it manually. */\n"
            "DECLARE @MilestoneId INT = NULL;"
        )
    return (
        "/* Milestone folder '{ms}' -> cases.MilestoneId. Milestone folders are children of the\n"
        "   'Milestones' folder (FolderId {parent}) in dbo.t_folder; the child's FolderId IS the MilestoneId. */\n"
        "DECLARE @MilestoneId INT;\n"
        "SELECT @MilestoneId = FolderId FROM dbo.t_folder WHERE Name = '{ms}' AND ParentId = {parent};\n"
        "/* If the SELECT above found nothing, @MilestoneId is NULL. Do NOT invent an id:\n"
        "   uncomment and set the correct FolderId by hand if you know it.\n"
        "-- IF @MilestoneId IS NULL SET @MilestoneId = <FolderId of '{ms}'>;\n"
        "*/"
    ).format(ms=q(milestone), parent=MILESTONE_PARENT_FOLDER_ID)


def build_script(proj, items):
    n = len(items)
    values = ",\n".join(
        "    ('{t}', '{d}', '{c}', '{g}')".format(
            t=q(it["title"]), d=q(it["description"]), c=q(it["category"]), g=q(it["tags"])
        )
        for it in items
    )
    proj_desc = proj["description"] or (
        "Project case grouping {n} child cases. Generated by "
        "dev:viper-case-creation.".format(n=n)
    )

    return """/**********************************************************************
 * Viper project case + {n} child cases + {n} linked todos
 *
 *   dbo.cases  (project)        DevStatus='Project'{ms_comment}
 *   dbo.cases  ({n} children)     one case per item, grouped via CaseProject
 *   dbo.EmployeeToDo ({n} todos)  on the project case; each LinkedCaseId ->
 *                               its child case (the "#<caseid>" link, set
 *                               programmatically since a raw INSERT bypasses
 *                               the app's "#" text-parser)
 *
 * SAFE BY DEFAULT: the transaction ROLLS BACK unless @Commit = 1. Run as-is to
 * preview the 3 result sets, then set @Commit = 1 and re-run to persist.
 *
 * Generated by dev:viper-case-creation. Review before committing.
 **********************************************************************/
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Commit      BIT          = 0;                      -- <== set to 1 to persist
DECLARE @User        VARCHAR(25)  = '{creator}';
DECLARE @Assignee    VARCHAR(25)  = '{assignee}';
DECLARE @Client      VARCHAR(25)  = '{client}';
DECLARE @Impact      VARCHAR(25)  = '{impact}';
DECLARE @Priority    VARCHAR(25)  = '{todo_priority}';
DECLARE @TodoStatus  VARCHAR(50)  = 'To Do';
DECLARE @Confidential BIT         = {confidential};
DECLARE @ProjectName VARCHAR(255) = '{project_name}';

{milestone_block}

BEGIN TRAN;

/* 1) Project (parent) case. CaseType uses the impact word; DevStatus='Project'
   marks it as a project so child cases can group under it via CaseProject. */
DECLARE @ProjectCaseId INT;
INSERT INTO dbo.cases
    (Client, AssignedTo, DateCreated, Creator, CaseTitle, CaseDescription,
     CaseType, CaseClient, CaseImpact, DevStatus, DevCaseType, MilestoneId,
     PublicYn, CommunicateLevel, InternalConfidential)
VALUES
    (@Client, @Assignee, GETDATE(), @User, @ProjectName, '{project_desc}',
     @Impact, @Client, @Impact, 'Project', 'Bug', @MilestoneId,
     0, 'None', @Confidential);
SET @ProjectCaseId = SCOPE_IDENTITY();

/* 2) Items staging ({n} rows) */
DECLARE @Items TABLE (Ord INT IDENTITY(1,1), Title VARCHAR(5000), Descr VARCHAR(MAX), Category VARCHAR(255), Tags VARCHAR(2000));
INSERT INTO @Items (Title, Descr, Category, Tags) VALUES
{values};

/* 3) One child case per item + its linked todo, in a per-row loop.
   Capture each child's SCOPE_IDENTITY() immediately: bulletproof, no
   OUTPUT INTO (dbo.cases has a trigger) and no watermark/re-select.
   A raw INSERT bypasses the app's "#<caseid>" text-parser, so LinkedCaseId /
   LinkedCaseTitle are set directly (the "#<caseid>" in Title is display only). */
DECLARE @i INT = 1, @n INT = (SELECT ISNULL(MAX(Ord), 0) FROM @Items), @childCount INT = 0;
DECLARE @cTitle VARCHAR(5000), @cDescr VARCHAR(MAX), @cCat VARCHAR(255), @cTags VARCHAR(2000), @childId INT;
WHILE @i <= @n
BEGIN
    SELECT @cTitle = Title, @cDescr = Descr, @cCat = Category, @cTags = Tags FROM @Items WHERE Ord = @i;

    INSERT INTO dbo.cases
        (Client, AssignedTo, DateCreated, Creator, CaseTitle, CaseDescription,
         CaseType, CaseClient, CaseImpact, DevStatus, DevCaseType, CaseProject, MilestoneId,
         PublicYn, CommunicateLevel, InternalConfidential, Tags)
    VALUES
        (@Client, @Assignee, GETDATE(), @User, @cTitle, @cDescr,
         @Impact, @Client, @Impact, 'In Discussion', 'Bug', @ProjectName, @MilestoneId,
         0, 'None', @Confidential, @cTags);
    SET @childId = SCOPE_IDENTITY();

    INSERT INTO dbo.EmployeeToDo
        (Client, Item, ItemType, Title, Status, CreatedBy, CreatedOn,
         AssignedTo, Priority, Category, Tags, LinkedCaseId, LinkedCaseTitle)
    VALUES
        (@Client, CAST(@ProjectCaseId AS VARCHAR(255)), 'Case',
         '#' + CAST(@childId AS VARCHAR(20)) + ' ' + @cTitle, @TodoStatus, @User, GETDATE(),
         @Assignee, @Priority, @cCat, @cTags, @childId, @cTitle);

    SET @childCount += 1;
    SET @i += 1;
END

/* verification result sets */
SELECT @ProjectCaseId AS ProjectCaseId, @MilestoneId AS MilestoneId, @childCount AS ChildCases,
       (SELECT COUNT(*) FROM dbo.EmployeeToDo WHERE Item = CAST(@ProjectCaseId AS VARCHAR(255)) AND ItemType='Case') AS Todos;
SELECT CaseID, CaseTitle, AssignedTo, CaseImpact, DevStatus, CaseProject, MilestoneId
FROM dbo.cases WHERE CaseProject = @ProjectName ORDER BY CaseID;
SELECT RowId, LinkedCaseId, Category, Priority, Status, AssignedTo, Title
FROM dbo.EmployeeToDo WHERE Item = CAST(@ProjectCaseId AS VARCHAR(255)) AND ItemType='Case'
ORDER BY Category, LinkedCaseId;

IF @Commit = 1
BEGIN
    COMMIT TRAN;
    PRINT 'COMMITTED: project case ' + CAST(@ProjectCaseId AS VARCHAR(20)) + ' + {n} child cases + {n} linked todos.';
END
ELSE
BEGIN
    ROLLBACK TRAN;
    PRINT 'DRY RUN - rolled back. Review the result sets, set @Commit = 1, re-run to persist.';
END
""".format(
        n=n,
        ms_comment=(", MilestoneId resolved from '%s'" % q(proj["milestone"])) if proj["milestone"] else "",
        creator=q(proj["creator"]),
        assignee=q(proj["assignee"]),
        client=q(proj["client"]),
        impact=q(proj["impact"]),
        todo_priority=q(proj["todo_priority"]),
        confidential=proj["confidential"],
        project_name=q(proj["name"]),
        project_desc=q(proj_desc),
        milestone_block=milestone_block(proj["milestone"]),
        values=values,
    )


def main():
    ap = argparse.ArgumentParser(description="Generate a dry-run Viper project-case SQL script.")
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--json", help="path to JSON input (project + items)")
    src.add_argument("--csv", help="path to CSV of items (project params via flags)")
    ap.add_argument("--out", help="output .sql path (default /private/tmp/viper-sql/<slug>.sql)")
    # project-param overrides (also the only way to set them in CSV mode)
    ap.add_argument("--name")
    ap.add_argument("--client")
    ap.add_argument("--creator")
    ap.add_argument("--assignee")
    ap.add_argument("--impact")
    ap.add_argument("--todo-priority", dest="todo_priority")
    ap.add_argument("--milestone")
    ap.add_argument("--description")
    ap.add_argument("--confidential", dest="confidential", action="store_true", default=None)
    ap.add_argument("--no-confidential", dest="confidential", action="store_false")
    args = ap.parse_args()

    if args.json:
        proj_raw, items_raw = load_json(args.json)
    else:
        proj_raw, items_raw = {}, load_csv(args.csv)

    items = [normalize_item(it) for it in items_raw]
    items = [it for it in items if it["title"]]
    if not items:
        sys.exit("error: no items with a non-empty title found in input")
    # child cases are correlated to items by Title, so titles must be unique
    titles = [it["title"] for it in items]
    dupes = {t for t in titles if titles.count(t) > 1}
    if dupes:
        sys.exit(
            "error: item titles must be unique (child cases are joined back to items by "
            "Title). Duplicates: " + ", ".join(sorted(dupes))
        )

    proj = build_project(proj_raw, args)
    script = build_script(proj, items)

    out = args.out or os.path.join(OUT_DIR, slugify(proj["name"]) + ".sql")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        f.write(script)
    print("wrote {} | project='{}' | items: {}".format(out, proj["name"], len(items)))


if __name__ == "__main__":
    main()
