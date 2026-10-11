---
name: dev:viper-session
description: Call production Viper endpoints directly using Derek's browser session. Takes a PHPSESSID, stores it, then drives https://my.ebacon.com as him. Three modes, open (work out the endpoint from the local checkout), scope (narrow attention to a Viper scope first), and mapped domains like the case system that have a bundled endpoint spec so no source reading is needed. Triggers on, viper session, use my session, hit prod viper, call the viper api, prod case, read case in prod, add a note to case, update a case in prod, my.ebacon.com, viper endpoint, /dev:viper-session.
model: opus
---

# /dev:viper-session

Drive production Viper as Derek, over HTTP, with his browser session. There is no
API key and no wrapper service: the PHPSESSID **is** the authorization, and it
carries his full authority over every CI3 controller.

`$ARGUMENTS` is the PHPSESSID, optionally followed by a hint (`use scope`, a scope
name, or a domain like `case system`).

## Constants

- Base URL: `https://my.ebacon.com`
- Viper checkout: `/Users/derek/eBacon/Viper` (prod mirrors this, so the local
  controllers are an accurate spec for what prod serves)
- Cookie file: `~/.cache/viper/session` (0600)
- Helpers: `scripts/vcurl` and `scripts/board-batch.py` next to this file

## Step 0: take the session

Store the cookie once, then never repeat it on a command line, because every shell
call is a fresh process and the value would otherwise land in the transcript on
every request.

```bash
mkdir -p ~/.cache/viper && chmod 700 ~/.cache/viper
printf '%s' '<PHPSESSID>' > ~/.cache/viper/session && chmod 600 ~/.cache/viper/session
```

Confirm it works before doing anything else. `whoami` is the cheapest live probe:

```bash
~/dotfiles/claude/commands/dev/viper-session/scripts/vcurl GET rest/caseREST/caseFeedy
```

A 200 means the session is good. An empty 401/403 means it is expired: ask for a
fresh one rather than guessing at the failure.

Never echo the cookie back, never paste it into a file in a repo, never commit it.
When the work is done, `rm ~/.cache/viper/session`.

## Writes touch real data

Reads run freely. **Before any POST or PUT, show the exact URL and the full field
list, and wait for a yes.** `vcurl --dry-run` prints precisely what would be sent.

This is not ceremony. `newCaseCreate` and the subscriber endpoints send real email
from production, `updateCaseDetail` overwrites eighteen columns whether or not you
meant to touch them, and `caseTags` replaces the tag list outright. A malformed
call is not a failed request, it is a visibly wrong case that a human has to
notice and repair.

**Case notes go through `/writing:unslop` before they are shown for approval**,
unless Derek says otherwise for that note. The audience is teammates skimming a
case, not a reviewer: short, plain, what happened and where the work lives now.
Drop implementation detail, sproc/endpoint names, and hedging the reader cannot
act on.

## Mode routing

Pick from what was asked; when it is ambiguous, ask rather than guess.

### Mapped domain (preferred whenever one exists)

A domain with a bundled spec needs no source reading at all. Load the reference and
work from it.

| Domain | Reference | Covers |
| --- | --- | --- |
| Case system | `references/case-system.md` | cases, notes, history, todos, project grid, folders, subscribers, **Derek's master board 359690** and the plan-driven `scripts/board-batch.py` |

If a request is squarely inside a mapped domain, read that file and nothing else.
Reading production controllers you already have documented is wasted context.

### Scope mode ("use scope", or a scope name)

For work that is Viper-repo-shaped rather than one known endpoint. `cd` to
`/Users/derek/eBacon/Viper` if not already there, consult `SCOPES.md`, load the
matching `.claude/scopes/<domain>/<scope>.md`, and treat the directories it lists
as the boundary for both reading and calling. A scope with no obvious match is a
question for Derek, not a guess (that rule is the repo's, not this skill's).

### Open mode (no hint)

Work it out. Prod mirrors the local checkout, so the controller on disk is the
spec:

1. Find the controller. Case-system, notes and todo endpoints live under
   `public/application/controllers/rest/`; plenty of others sit at the root of
   `controllers/`.
2. Read the method for its exact params, which values come from the session, and
   what it writes.
3. Call it. Then, if the endpoint is one you would plausibly need again, say so:
   a domain that comes up twice has earned a reference file.

## Calling convention

`vcurl <VERB> <path-after-index.php> [key=value ...]`

```bash
vcurl GET  rest/caseREST/case CaseID=359706 Client=TAGClient
vcurl POST rest/notes/enhancedNote itemType=Case item=359706 client=TAGClient note='Deployed.'
vcurl --dry-run PUT rest/caseREST/caseTags CaseId=359706 Tags='billing,urgent'
```

Raw `curl` is fine too and sometimes necessary (multipart, binary downloads,
inspecting redirects). `vcurl` exists to keep the cookie off the command line and
to turn Viper's silent failures into readable ones, not to be the only way in.

## Gotchas

- **Form-encode every write. Never send `Content-Type: application/json`.**
  `REST_Controller::_parse_post()` reads `$_POST`, which PHP fills only for
  form-encoded bodies, so a JSON body makes every `$this->post("X")` return
  `false` and the endpoint acts as though you sent nothing. PUT is worse: a JSON
  content-type matches a supported format, so `_put_args` is never populated at
  all. `vcurl` form-encodes; if you hand-roll a curl, use `--data-urlencode`.
- **`false`, not `null`, is what a missing param looks like.** CI3 returns `false`
  from `post()`/`get()` for an absent key, and many of these endpoints do no
  validation at all, so a typo'd field name silently becomes an empty write rather
  than a 400.
- **An empty body with 401 or 403 is an expired session,** not a permissions
  problem with the endpoint. An HTML body where JSON was expected is the login
  page, same cause.
- **`User` and `Client` come from the session on nearly every endpoint.** Do not
  send them as fields expecting them to take effect; where a body field of that
  name exists it usually means something else (the case's client, not the actor's).
- **Prod returns unredacted data.** The PII masking Derek is used to is a transport
  feature of the SQL MCP, and none of it applies here. Do not dump whole rows into
  the transcript when a couple of fields answer the question.
- **Check the mapped-domain reference before reading source, and prefer it when
  the two disagree only in tone.** If they genuinely conflict on a param name, the
  source wins and the reference is stale: fix the reference in the same turn.

## Growing this skill

The value is the mapped domains. When open mode has to work out the same endpoints
a second time, that domain has earned a reference file: add
`references/<domain>.md` in the shape of `case-system.md` (shared rules, read
table, write table with payloads, recipes, traps) and list it in the table above.
Add a gotcha every time production surprises you.
