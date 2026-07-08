# Troubleshooting

Symptoms are grouped by workflow. If your issue is not here, reply to your
Gumroad receipt email with the workflow name, the failing node, and the error
text (redact anything sensitive first).

## General

**"Data table not found" or "specified column does not exist"**
PK-00 was not run, the table name was changed, or the column names do not
match exactly (`error_log`, `dead_letter`, `idempotency_ledger`,
`ai_cost_log` — lowercase with underscores). Open **PK-00 Setup Data Tables**,
click Execute once, then check the **Data Tables** sidebar.

**"Workflow is not active and cannot be executed" from an Execute Workflow node**
n8n imports files as drafts, and drafts cannot be called by other workflows.
Publish PK-02 and PK-04 (and PK-01 so it can run as the error workflow) —
INSTALL.md §6.

**Alerts have wrong/empty channel, or emails go nowhere**
You skipped a Settings node. Every configurable workflow has a purple
Settings node on the canvas (INSTALL.md §4) — open it and replace the
`REPLACE_WITH_...` placeholders with your real values.

**A node fails with "no credentials set"**
Deliberate. The kit ships without credentials so nothing of ours leaks into
your instance and nothing of yours leaks into exports. Connect your own
accounts (INSTALL.md §5).

**A schedule never fires**
The workflow is not published, or (self-host only) the container timezone is
off — check `GENERIC_TIMEZONE` in your `.env`.

## PK-01 Central Error Logger

**Errors happen but nothing is logged**
PK-01 must be set as the *Error Workflow* of the failing workflow (its
Settings → Error Workflow), and PK-01 must be published. Setting it once does
not apply to workflows created afterwards — check each one.

**Slack alert missing, email arrived**
That is the designed fallback. Fix the Slack side: bot not in the channel,
wrong channel ID in **Alert Settings**, or missing `chat:write` scope.

## PK-02 / PK-03 Dead Letter Queue

**"Dead-letter write rejected: missing required field(s)"**
The caller did not map `source_workflow`, `event_key`, and `payload`. Map all
three in the Execute Workflow node that calls PK-02.

**Replay marks rows `skipped_no_target`**
Those rows were stored without a `replay_target_url`. Add the target URL to
the row in the Data Table and set `status` back to `pending`, or handle those
rows manually.

**Replay keeps failing and stops retrying**
After the max attempts (see **Replay Settings** in PK-03) the row is marked
`failed` on purpose. Fix the root cause, then set `status` to `pending` and
`retry_count` to `0` to re-arm it.

## PK-04 Idempotency Ledger

**Everything comes back `duplicate: true`**
Your `event_id` is not unique per event (e.g. you passed a static string).
Use a stable per-event value: an invoice ID, a webhook delivery ID, a
`provider::date` pair.

**Duplicates still appear in downstream data**
The ledger only reports; the *caller* must branch on `duplicate` and skip.
Check the IF node after your Execute Workflow call. Also note n8n Data Tables
do not enforce a unique constraint — two runs at the exact same second can
race. For strict guarantees, swap the ledger storage to Postgres with a
UNIQUE index (INSTALL.md Appendix B).

## PK-05 AI Cost Monitor

**401/403 from OpenAI or Anthropic**
Org usage/cost endpoints require **admin** keys, not project keys. OpenAI: an
Admin key from the organization settings. Anthropic: an Admin key from the
console. Regular keys will never work here.

**`parse_error: No cost values found in response`**
The provider changed the response shape, or the account genuinely had zero
spend in the window. Compare the raw response against `COMPATIBILITY.md`;
if the shape drifted, check for a kit update.

**Costs recorded twice for one day**
Should be impossible while PK-04 is linked. Confirm **Check Idempotency
Ledger** points at your imported PK-04 (not the placeholder), and PK-04 is
published.

## PK-06 GitHub Backup / PK-07 Security Scanner

**"unauthorized" / 401 from the n8n API node**
The n8n API credential is missing or the key was revoked. Create a key under
Settings → n8n API and put it in the credential. Self-host note: the Base URL
is your n8n address plus `/api/v1`.

**PK-06: 404 on create/update**
GitHub username/repo wrong in **Backup Settings**, the repo does not exist,
or the token lacks `repo` scope on it.

**PK-06: every run commits every file**
Change detection compares parsed JSON. If repo files were edited by hand, the
first run after that legitimately rewrites them once. If it persists, check
that the repo files are valid JSON.

**PK-07 flags a workflow but the "secret" is a placeholder**
The scanner is intentionally paranoid. Rename placeholders so they do not
match real key shapes (use `REPLACE_WITH_...`) and use `@example.com` for
sample emails — then it passes.
