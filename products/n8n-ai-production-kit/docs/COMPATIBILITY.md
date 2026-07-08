# Compatibility Matrix

APIs drift. This file records exactly what each release was tested against.
Rule of the house: provider changelogs are checked weekly, live templates are
re-tested monthly, and breaking changes are patched within 48 hours of
discovery.

> Rows marked `TESTED-ON: (pending)` are documented from the provider's own
> reference docs and monitored weekly, but not yet verified against a live
> paid account. Every pending integration fails safe: PK-05 records a
> `parse_error` instead of logging bad numbers, and PK-06/PK-07 stop with a
> clear credential error. Pending rows get dated the moment live keys are
> available.

## Kit Version

| Kit | Date | Status |
| --- | --- | --- |
| 0.1.0 | 2026-07-05 | Pre-release - verification pass pending |

## n8n

| Component | Tested version | TESTED-ON | Notes |
| --- | --- | --- | --- |
| n8n (Docker, self-hosted) | 2.28.6 | 2026-07-06 | Imported workflows are drafts and must be published (INSTALL.md §6). No special server flags needed - the kit uses no environment variables |
| n8n API (via built-in n8n node) | v1 | (pending) | Used by PK-06 and PK-07; needs an n8n API credential |
| n8n Data Tables | Data Table node v1.1 (table create + row insert/get/update) | 2026-07-06 | Used by PK-00..PK-05; verified live on 2.28.6: create, insert, filtered get, filtered update |

## Provider Endpoints Used

| Provider | Endpoint | API version header | Used by | TESTED-ON | Changelog to watch |
| --- | --- | --- | --- | --- | --- |
| OpenAI | `GET /v1/organization/costs` | n/a (admin bearer key) | PK-05 | (pending) | https://platform.openai.com/docs/changelog |
| Anthropic | `GET /v1/organizations/cost_report` | `anthropic-version: 2023-06-01` | PK-05 | (pending) | https://docs.anthropic.com/en/release-notes/api |
| Gumroad | `POST /v2/licenses/verify` | n/a | License worker | (pending) | https://help.gumroad.com/article/76-license-keys |
| GitHub | Contents API via n8n GitHub node | 2022-11-28 (node-managed) | PK-06 | (pending) | https://github.blog/changelog/ |
| Slack | `chat.postMessage` via n8n Slack node | n/a | PK-01, PK-02, PK-05 | (pending) | https://api.slack.com/changelog |

## Response Shapes The Kit Assumes

**OpenAI `/v1/organization/costs`** - bucketed page:

```json
{ "object": "page", "data": [ { "results": [ { "amount": { "value": 1.23, "currency": "usd" } } ] } ] }
```

**Anthropic `/v1/organizations/cost_report`** - bucketed report where each
result exposes `amount` (or `cost.amount`):

```json
{ "data": [ { "results": [ { "amount": "1.23", "currency": "USD" } ] } ] }
```

If a provider changes these shapes, PK-05 records `parse_error` on the row
instead of failing the run - that is your signal to check this file for an
update.

## Known Constraints

- n8n 2.x imports workflows as drafts; sub-workflows (PK-02, PK-04) and the
  error workflow (PK-01) must be published before other workflows can call them.
- The kit deliberately uses no `$env` variables and no filesystem access, so
  n8n 2.x hardening defaults (env access blocked, file allowlist) never
  affect it - and it runs unmodified on n8n Cloud.
- OpenAI and Anthropic **usage/cost endpoints require admin/organization
  keys.** Project or standard keys return 401/403.
- Gumroad license verification does not prevent piracy; it verifies purchase
  (see LICENSE-CHECK.md).
- n8n Data Tables are fine for early volume. For strict uniqueness or high
  concurrent write volume, move the storage nodes to Postgres with unique
  constraints where needed (INSTALL.md §7).

## Retirement Policy

Products that come to depend on unstable or hard-to-test APIs get retired
rather than half-maintained.
