# Changelog

Format per release: date, changed workflows/nodes, and tested provider
versions (see COMPATIBILITY.md for the full matrix). Buyers are emailed
through Gumroad whenever an updated ZIP is published.

## 0.2.0 — 2026-07-06 (pre-release)

Made the kit fully non-technical friendly: no server, no Docker, no
environment variables, no command line. Runs on n8n Cloud unmodified.

**Changed**

- All configuration moved from environment variables to visible **Settings**
  nodes on each canvas (PK-01, PK-02, PK-03, PK-05, PK-06). Buyers type
  values into a form instead of editing `.env` files.
- Every workflow now carries a plain-English **Setup Note** sticky on the
  canvas with its exact click-by-click setup steps.
- PK-06 GitHub Backup: workflow listing now uses the built-in **n8n API
  node** with an n8n API credential instead of an HTTP call + env vars.
- PK-07 Security Scanner: rebuilt to scan **all workflows in the instance
  via the n8n API** instead of reading exported files from disk — works on
  n8n Cloud, needs no file mounts or `EXPORT_SCAN_DIR`.
- Because no `$env` or filesystem access remains, the previously required
  server flags (`N8N_BLOCK_ENV_ACCESS_IN_NODE`, `N8N_RESTRICT_FILE_ACCESS_TO`)
  are gone; the optional docker-compose is now minimal.
- INSTALL.md rewritten cloud-first; Docker demoted to an appendix.
- Release ZIP now includes `docker-compose.yml` and `.env.example` for the
  self-host appendix (they were referenced but missing in 0.1.0).

**Verified 2026-07-06 on n8n 2.28.6 (live regression run)**

- PK-02 dead-letter write, PK-04 duplicate detection, PK-03 replay
  (success + skipped paths), and PK-01 error logging with secret redaction
  all pass using Settings nodes on a default n8n with no special flags.

## 0.1.0 — 2026-07-05 (pre-release)

Initial build. Not yet published.

**Added**

- PK-01 Central Error Logger — global error workflow, sanitized log to
  `error_log`, Slack alert with SMTP email fallback.
- PK-00 Setup Data Tables — creates `error_log`, `dead_letter`,
  `idempotency_ledger`, and `ai_cost_log` inside n8n with no Google Cloud or
  external database.
- PK-02 Dead Letter Queue Writer — validated sub-workflow storing failed
  payloads to `dead_letter` with `pending` status.
- PK-03 Manual Dead Letter Replay — capped retries (`DLQ_MAX_RETRIES`),
  per-row statuses: `replayed`, `pending`, `failed`, `skipped_no_target`.
- PK-04 Idempotency Ledger — deterministic FNV-1a event keys over
  `source::event_id`, duplicate reporting for callers.
- PK-05 AI Token And Cost Monitor — daily OpenAI + Anthropic cost pull;
  idempotent logging via PK-04; threshold alerts to Slack.
- PK-06 GitHub Workflow Backup — nightly export of all workflows through the
  n8n public API; JSON-normalized change detection; commits only real diffs.
- PK-07 Pre-Export Security Scanner — pattern scan of exported JSON for keys,
  tokens, and non-example email addresses with masked previews.
- Storage converted to n8n Data Tables by default, removing Google Sheets,
  Google Drive API, and Google Cloud OAuth setup from the install path.
- Cloudflare/Gumroad license verification moved to an optional publishing
  add-on instead of a local test blocker.
- Docs: README, INSTALL, TROUBLESHOOTING, COMPATIBILITY, LICENSE-CHECK,
  CLIENT-HANDOFF. Fake sample data. Release build script with secret gate.

**Verified 2026-07-06 on a clean n8n 2.28.6 instance (Docker)**

- All 8 workflows import cleanly; PK-00 creates all four Data Tables.
- PK-02 stores dead letters (Slack alert degrades gracefully without creds).
- PK-03 replay: HTTP replay to a live target marks rows `replayed`; rows
  without a target become `skipped_no_target`.
- PK-04: two identical calls → one ledger row, `duplicate: false` then `true`.
- PK-01 fires as error workflow, logs to `error_log`, and redacts a planted
  fake API key from the stored message.
- PK-07 scans all 8 export files: zero findings.
- Fixes from testing: PK-02 return payload now reads from the validated
  record; PK-07 reports real file names; docker-compose sets
  `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` and `N8N_RESTRICT_FILE_ACCESS_TO`;
  INSTALL/TROUBLESHOOTING document n8n 2.x draft-vs-published behavior.

**Known-pending at release**

- Live verification of PK-05 provider fetches (needs OpenAI/Anthropic admin
  keys) and PK-06 (needs GitHub repo + n8n API key). Both fail safe and are
  marked `(pending)` in COMPATIBILITY.md until verified against live accounts.
