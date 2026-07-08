# Client Handoff Guide

For agencies and consultants delivering n8n workflows built on this kit.
Copy this file per client, fill in the brackets, and walk through it on the
handoff call. A clean handoff is the difference between "done" and "calls you
at 11pm."

## 1. What Was Delivered

| Item | Value |
| --- | --- |
| Client | [client name] |
| Delivered workflows | [names + one-line purpose each] |
| Production kit workflows installed | PK-01 error logger, PK-02/03 dead letter, PK-04 idempotency, [PK-05 cost monitor if AI], PK-06 GitHub backup |
| n8n instance | [URL, hosting, who pays for it] |
| Storage | n8n Data Tables: `error_log`, `dead_letter`, `idempotency_ledger`, `ai_cost_log` |
| Alert channel | [Slack channel / email] |
| Backup repo | [GitHub repo URL] |
| Handoff date | [date] |

## 2. Credential Ownership

Every credential must be owned by the client before handoff is complete.

- [ ] All API keys created under **client** accounts, not yours.
- [ ] Client billing attached to OpenAI/Anthropic/etc. — never your cards.
- [ ] Your personal/agency credentials removed from the instance.
- [ ] Client has admin access to the n8n instance and the storage backend.
- [ ] Secrets live in n8n credentials or environment variables only —
      the client knows never to paste keys into nodes.

## 3. What "Normal" Looks Like

- Slack channel [#channel] receives: workflow failure alerts (immediately),
  dead-letter notices (immediately), AI spend alerts (only when over
  $[threshold]/day), and nothing else.
- The `dead_letter` Data Table is empty or all rows say `replayed`.
- The backup repo gets commits only when workflows actually change.

## 4. When An Alert Fires — Client Runbook

1. **Workflow failure alert:** open the execution link in the alert. If the
   cause is external (API down), wait and re-run. If data was lost, check the
   `dead_letter` Data Table — the payload is stored there.
2. **Dead letter stored:** fix the root cause (or wait out the outage), then
   open *PK-03 Manual Dead Letter Replay* and click Execute. Check the Data Table:
   `replayed` = done; `failed` = call [support contact].
3. **Spend alert:** review the `ai_cost_log` Data Table, identify the workflow
   driving spend, and decide whether to raise `DAILY_SPEND_ALERT_USD` or
   throttle the workflow.

## 5. Maintenance Expectations

| Task | Cadence | Owner |
| --- | --- | --- |
| Check provider API changelogs | Weekly | [you / client] |
| Re-test live workflows | Monthly | [you / client] |
| Patch breaking API changes | Within 48h of discovery | [you / client] |
| Rotate API keys | [Quarterly] | Client |
| Review error log + dead letters | Weekly | Client |

If ongoing maintenance is yours, state the retainer terms here: [terms].
If not, state clearly that support ends on [date] and what an ad-hoc
incident costs: [rate].

## 6. Handoff Checklist

- [ ] Walkthrough call done; client triggered a test failure and watched the
      alert, log row, and replay flow end to end.
- [ ] Client can locate: error log, dead-letter table, cost log, backup repo.
- [ ] Runbook (§4) tested by the *client*, not by you.
- [ ] All boxes in §2 checked.
- [ ] This document delivered as a PDF alongside the workflow exports.
