---
name: dev:verify-viper
description: Drive a running Viper worktree the way a user does and capture the evidence, doctor the stack, run the repo's Playwright integration harness against it, and collect the JSON report plus screenshots. Use before calling any Viper change done. Triggers on, verify viper, prove the viper change works, drive the viper app, run viper integration tests, playwright viper, is the worktree healthy, viper doctor, check the stack, exercise the feature, /dev:verify-viper.
---

# dev:verify-viper

Shape adapted from the `create-verification-skill` skill in [pstack](https://github.com/cursor/plugins/tree/main/pstack) (MIT, Lauren Tan). The harness it drives is Viper's own.

Satisfies the "nothing is done until it's exercised" rule for Viper work. Viper already ships a Playwright integration harness, so this skill wires it to a worktree and owns doctor, evidence, and cleanup. It does not own launch.

## Launch

`dev:viper-worktree` owns bring-up: compose services, the static-versus-hotreload build, the one-shot host build, the named URL, and the CI4 `server/vendor` provisioning. Do not restate any of it here. Reach that skill first if no stack is running.

This skill assumes an `-app-1` container in `running` state.

## Doctor

One read-only pass that answers "is this instance worth driving?" Run all three before any drive.

```bash
docker ps --filter "name=viper-worktree-" --filter "name=-app-1" --format '{{.Names}}\t{{.State}}'
PORT=$(docker port viper-worktree-<slug>-app-1 | awk -F: '/^80\/tcp/ {print $2}')
curl -s -o /dev/null -w 'http_code=%{http_code} bytes=%{size_download}\n' "http://localhost:$PORT/"
curl -s -m 10 "http://localhost:$PORT/api/health"
```

Healthy looks like this (measured 2026-08-19 against `derek-355629-scheduleremployee500`):

- container state `running`
- root returns `http_code=200` with a few KB of body, and `<title>eBacon Login</title>` when the session is anonymous. A login title is a PASS, not a failure.
- health returns `{"php":"8.5.7","version":"ci4","time":"..."}`

A health route that returns a PHP fatal instead of JSON means the CI4 sidecar has no `server/vendor/`, which is a `dev:viper-worktree` step, not a code bug. A root that returns 45 bytes means the port is wrong and the request hit the stray system Apache on `:80`.

## Drive

The harness is `playwright.config.ts` at the repo root, tests in `tests/integration/`. Three projects run in order: `setup` (auth plus environment), `chromium-rendering` (`rendering/*.spec.ts`), `chromium-e2e` (`domains/*.spec.ts`). The setup project logs in once and saves `storageState` to `playwright/.auth/user.json`; every later project reuses it.

Run from the worktree root, never the main checkout, so the specs and the app being driven are the same commit.

```bash
# wiring check, no browser and no credentials needed
INTEGRATION_BASE_URL="http://localhost:$PORT" npx playwright test --list --project=chromium-rendering

# agent-readable run: machine JSON only, no video, no trace
INTEGRATION_BASE_URL="http://localhost:$PORT" \
INTEGRATION_USERNAME=... INTEGRATION_PASSWORD=... \
npm run test:integration:json -- --project=chromium-rendering tests/integration/rendering/render-scheduler.spec.ts

# human run with the HTML report
INTEGRATION_BASE_URL="http://localhost:$PORT" npm run test:integration
```

Rules:

- `INTEGRATION_BASE_URL` must carry the worktree's own published port. Pointing it at another worktree drives the wrong commit and the run still passes, which is the worst outcome available here.
- Name the spec file. A full `chromium-rendering` sweep is 17 tests across 14 files and rebuilds auth state; a single feature is one file.
- The specs replay HAR fixtures from `tests/integration/__mocks__`, rewritten per host by the environment setup project. A network shape that changed needs the fixture updated, not the assertion loosened.
- Adding coverage is a different job: Viper's own `viper-write-integration-test` skill owns spec authoring.

## Evidence

| Artifact | Path |
|---|---|
| machine report | `tests/integration/.report/report.json` |
| HTML report | `tests/integration/.report/` (`npm run test:integration:report`) |
| failure screenshots, traces, video | `tests/integration/.results/` |
| visual snapshots | `tests/integration/__screenshots__/` |

For a change a human sees in the browser, the Playwright run is necessary and not sufficient: CLAUDE.md requires driving the flow in the Claude Chrome profile and keeping the `gif_creator` recording. Drive the named URL from `dev:viper-worktree`, not `localhost:<port>`, so the recording shows the real host.

Report the actual verdict per spec. A pass is a fact about the assertions in that file, never a claim that the feature is correct.

## Feature map

`tests/integration/rendering/` is the map, and it is the source of truth: reading it costs one `ls` and it cannot go stale. Surfaces currently covered: scheduler, employee screen, quotes, prime, job site, sidewinder, company menu, case system, dashboard, kb, payroll, system menu, report viewer. Domain flows: `tests/integration/domains/` (human resources case system).

A change to a surface with a spec gets that spec run. A change to a surface with no spec gets a Chrome drive plus a recording, and the missing spec named in the report as a coverage gap.

## Cleanup

- Never `docker compose down -v`. The `-v` deletes the `viper-sessions` volume and wipes login state.
- Never stop another worktree's stack as a side effect. Teardown belongs to `dev:viper-worktree-cleanup`.
- Evidence survives teardown. Reports and screenshots live in the worktree, not the container.

## Gotchas

- **The agent cannot read `.env`.** Reading a worktree `.env` is denied by the write/secret guards, so `DC_APP_HOST` and `DC_APP_PORT` are not available that way. Get the port from `docker port` as above, and ask the user for the named host when the human-facing URL is needed. Same for `INTEGRATION_USERNAME` and `INTEGRATION_PASSWORD`: the auth-dependent run needs the user to supply them, or to run the command themselves with `! <command>`.
- **No `timeout` binary on this Mac.** `timeout npx playwright test` dies with `command not found` and reads like a Playwright failure. Use the Bash tool's own timeout parameter.
- **`npx playwright test` without `--project` runs the dependency chain.** `chromium-e2e` depends on `chromium-rendering`, which depends on `setup`, so a domain spec drags the whole rendering sweep with it.
- **Proof state of this skill (2026-08-19).** Doctor is proven end to end against a live stack, and the harness listing is proven (Playwright 1.56.1, 17 tests in 14 files resolved against a worktree). A full authenticated drive is NOT yet proven from a session, because credentials are not agent-readable. Until one has been run, treat the Drive section as tested-in-part and paste the real output the first time it runs.
