# n8n AI Workflow Production Kit

Turn fragile AI demo workflows into client-safe n8n systems with cost tracking,
retries, dead-letter replay, idempotency, central error logs, GitHub backup,
and handoff docs.

## Who This Is For

- AI automation agencies delivering client workflows
- Freelance n8n builders and consultants
- Technical founders running AI workflows in n8n
- Small teams moving AI automations from demo to production

## The Problem

Most n8n demos work once in the editor, then fail in production because they
lack retries, dead-letter storage, idempotency, observability, backup, and
clean handoff docs. This kit is a reusable operating layer that makes client
workflows safer to run.

## What Is In The Box

| File | Workflow | What it does |
| --- | --- | --- |
| `workflows/00-setup-data-tables.json` | PK-00 | Creates the four local n8n Data Tables used by the kit |
| `workflows/01-central-error-logger.json` | PK-01 | Global error workflow: sanitized error log + Slack alert with email fallback |
| `workflows/02-dead-letter-writer.json` | PK-02 | Sub-workflow that stores failed payloads so they are never lost |
| `workflows/03-dead-letter-replay.json` | PK-03 | Manual replay with capped retries and per-row status tracking |
| `workflows/04-idempotency-ledger.json` | PK-04 | Deterministic event keys; repeated runs never duplicate records |
| `workflows/05-ai-cost-monitor.json` | PK-05 | Daily OpenAI + Anthropic spend tracking with threshold alerts |
| `workflows/06-github-workflow-backup.json` | PK-06 | Nightly backup of all workflows to GitHub, committing only real changes |
| `workflows/07-pre-export-security-scanner.json` | PK-07 | Scans exported workflow JSON for keys, tokens, and real emails |

Docs: `INSTALL.md` (start here), `TROUBLESHOOTING.md`, `COMPATIBILITY.md`,
`CHANGELOG.md`, `LICENSE-CHECK.md`, `CLIENT-HANDOFF.md`.
Test data: `test-data/sample-data.json` - fake records only.

## Hardening Patterns Baked In

- Input validation after every trigger - bad calls fail loudly, not silently.
- Retries on external HTTP calls, capped to short waits.
- Error branches on nodes that talk to the outside world.
- Dead-letter storage for failed payloads, with manual replay.
- Idempotency keys so repeated runs do not duplicate records.
- A global error workflow that alerts Slack with an email fallback.
- Sanitized logs: no API keys, license keys, buyer emails, or raw customer data.

## Quick Start

1. Read `INSTALL.md` and follow it top to bottom (about 20-30 minutes).
2. Import the 8 workflow files into n8n (n8n Cloud or self-hosted).
3. Run PK-00 once to create the local n8n Data Tables.
4. Type your values into the purple **Settings** node on each canvas -
   no environment variables, no config files.
5. Connect your own accounts (Slack, SMTP, GitHub, AI providers) by clicking
   the nodes that need them.
6. Run each workflow once against `test-data/sample-data.json` before
   connecting anything real.

## Design Choices

- **No server required.** Works on n8n Cloud in the browser - no Docker, no
  database, no command line. (Self-hosting still works; see INSTALL Appendix A.)
- **Standard n8n nodes only.** Nothing to install, nothing to trust blindly.
- **All settings live on the canvas** in visible Settings nodes with a
  Setup Note on every workflow - if you can fill in a form, you can
  configure this kit.
- **n8n Data Tables as default storage** so setup stays local and free. Swap
  in Postgres for higher volume - the workflows isolate storage in single
  nodes to make that swap easy.
- **Optional license check.** Gumroad already gates file delivery. If you later
  want extra purchase verification inside workflows, use the optional worker in
  `shared/license-worker/`. See `LICENSE-CHECK.md`.

## Support And Updates

- Compatibility promises live in `COMPATIBILITY.md`; every release is recorded
  in `CHANGELOG.md` with dates, changed nodes, and tested provider versions.
- Breaking provider API changes are patched within 48 hours of discovery, and
  buyers get the updated ZIP through Gumroad.
- Support: reply to your Gumroad receipt email.
