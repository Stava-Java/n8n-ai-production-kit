# Installation Guide

No server, no Docker, no database, no command line. If you can use n8n's
editor, you can install this kit. Time: 20–30 minutes.

## 1. Get n8n (skip if you already have it)

**Recommended: n8n Cloud.** Go to n8n.io, create an account, done — n8n runs
in your browser. The kit is verified on n8n 2.x.

**Advanced alternative:** self-hosting with Docker works too — see Appendix A
at the bottom. Everything else in this guide is identical either way.

## 2. Import The 8 Workflow Files

In n8n: **Workflows → Create Workflow dropdown → Import from File**, once for
each file in the `workflows/` folder, in order:

1. `00-setup-data-tables.json`
2. `01-central-error-logger.json`
3. `02-dead-letter-writer.json`
4. `03-dead-letter-replay.json`
5. `04-idempotency-ledger.json`
6. `05-ai-cost-monitor.json`
7. `06-github-workflow-backup.json`
8. `07-pre-export-security-scanner.json`

Every workflow has a yellow **Setup Note** on its canvas telling you exactly
what to click. This guide is the same information in one place.

## 3. Run PK-00 Once

Open **PK-00 Setup Data Tables** and click **Execute workflow**. That creates
the kit's four storage tables inside n8n itself. Check the left sidebar →
**Data Tables**: you should see `error_log`, `dead_letter`,
`idempotency_ledger`, and `ai_cost_log`. Safe to re-run — it never duplicates.

## 4. Type Your Settings Into The Settings Nodes

No environment variables. Each workflow that needs configuration has a
purple **Settings** node — open it, type your values, save:

| Workflow | Node | What to type |
| --- | --- | --- |
| PK-01 | Alert Settings | Slack channel ID, alert from/to emails |
| PK-02 | Alert Settings | Slack channel ID |
| PK-03 | Replay Settings | Max replay attempts (default 5 is fine) |
| PK-05 | Cost Monitor Settings | Daily spend alert in USD, Slack channel ID |
| PK-06 | Backup Settings | Your GitHub username and backup repo name |

Tip: a Slack channel ID looks like `C0123456789` — right-click the channel in
Slack → View channel details → bottom of the About tab.

## 5. Connect Your Accounts (credentials)

The kit ships with **no credentials** — you connect your own accounts by
clicking each node and picking "Create new credential":

| Where | Credential | Notes |
| --- | --- | --- |
| Slack nodes (PK-01, 02, 05) | Slack | Bot token with `chat:write`, bot invited to your alert channel |
| Email Fallback Alert (PK-01) | SMTP | Any email provider's SMTP settings |
| List n8n Workflows (PK-06) and List Workflows To Scan (PK-07) | n8n API | In n8n: Settings → n8n API → Create key, paste it in. One credential, reused by both |
| GitHub nodes (PK-06) | GitHub | Personal access token with `repo` scope |
| Fetch OpenAI Costs (PK-05) | Header Auth | Name `Authorization`, value `Bearer <your OpenAI ADMIN key>` |
| Fetch Anthropic Costs (PK-05) | Header Auth | Name `x-api-key`, value `<your Anthropic ADMIN key>` |

Only set up what you use: no GitHub? Skip PK-06. Only OpenAI? Delete the
Anthropic branch in PK-05. The core kit (PK-00–PK-04, PK-07) needs at most
Slack + email.

⚠️ The PK-05 provider endpoints require **admin/organization** API keys.
Regular project keys get a 401 — that's the provider's rule, not a bug.

## 6. Wire The Workflows Together

1. **PK-05 → PK-04:** open PK-05, click **Check Idempotency Ledger**, and
   pick your imported *PK-04 Idempotency Ledger* from the workflow list.
2. **Protect your workflows:** open any workflow you want protected
   (including your own), go to its Settings (three dots, top right) →
   **Error Workflow** → pick *PK-01 Central Error Logger*.
3. **Publish** (top-right button) PK-01, PK-02, PK-04, PK-05, and PK-06.
   n8n imports files as drafts, and a draft cannot be called by another
   workflow or run on a schedule. PK-00, PK-03, and PK-07 stay manual —
   drafts run fine from the editor's Execute button.

## 7. Test With Fake Data (before connecting anything real)

`test-data/sample-data.json` has fake values for every test:

1. **PK-04:** create a scratch workflow: Manual Trigger → Execute Workflow →
   pick PK-04, map `source` = `stripe-invoice-sync`, `event_id` = `in_FAKE001`.
   Run twice: first returns `duplicate: false`, second `duplicate: true`, and
   the ledger table has exactly one row.
2. **PK-02:** same pattern with values from `dead_letter_examples`. Confirm a
   `pending` row appears in the `dead_letter` Data Table.
3. **PK-03:** click Execute. The fake row (no real replay URL) ends as
   `skipped_no_target` or increments `retry_count` — both prove the status
   tracking works.
4. **PK-01:** in a scratch workflow set the Error Workflow to PK-01, add a
   Code node containing `throw new Error('test')`, run it. Confirm the row in
   `error_log` and the Slack alert.
5. **PK-07:** click Execute. Every kit workflow should report `pass`.
6. **PK-06:** run once against an empty repo — files appear. Run again — no
   new commits (that's the change detection working).

## 8. Go-Live Checklist

- [ ] PK-00 run once; four Data Tables exist
- [ ] Settings nodes filled in (§4)
- [ ] Credentials connected for what you use (§5)
- [ ] PK-05 linked to PK-04; error workflow set on your workflows (§6)
- [ ] PK-01, PK-02, PK-04 (+ PK-05, PK-06 if used) published
- [ ] Fake-data tests passed (§7)

## Appendix A: Self-Hosting With Docker (advanced, optional)

If you prefer running n8n on your own machine: install Docker Desktop, copy
`.env.example` to `.env` (set your timezone), then from the kit folder run
`docker compose up -d` and open http://localhost:5678. The included
`docker-compose.yml` is all you need — the kit uses no special server flags.
Continue from §2.

## Appendix B: Higher Volume Storage

n8n Data Tables are perfect for getting started. If you outgrow them
(hundreds of thousands of rows, heavy concurrent writes), replace the Data
Table nodes with Postgres nodes and keep the same column names — every
read/write is isolated in a single node to make that swap painless.
