# Pre-Export Security Checklist

Run this on EVERY workflow JSON before it goes into a release ZIP. Workflow 7
(the pre-export security scanner) automates the pattern search; this checklist
is the human pass on top of it. The release build script
(`products/n8n-ai-production-kit/release/build-release.ps1`) refuses to build
a ZIP if the automated scan finds anything.

## Pattern Search

Search every exported file for these strings and patterns:

- `api_key`
- `bearer`
- `token`
- `secret`
- `password`
- `sk-` (OpenAI-style keys)
- `xoxb` (Slack bot tokens)
- `ghp_` and `github_pat_` (GitHub tokens)
- `AKIA` (AWS access key IDs)
- Real email addresses (anything not `@example.com` / `@example.org`)
- Real customer or client names, domains, and IDs

A hit is not automatically a failure — `"authentication": "genericCredentialType"`
is fine — but every hit must be looked at and explained.

## Structural Checks

- [ ] HTTP Request nodes use credential objects or environment variables,
      never inline keys or headers with literal secrets.
- [ ] Code nodes contain no hardcoded test keys, tokens, or passwords.
- [ ] Webhook URLs do not call infrastructure you control unless the buyer
      explicitly configures them (placeholders + env vars only).
- [ ] No `credentials` blocks with real credential IDs from your own instance
      that leak instance metadata you care about.
- [ ] All sample data is fake: fake names, fake emails on example.com,
      fake IDs, fake amounts.
- [ ] `pinData` is empty or contains only fake data (pinned executions can
      embed real API responses).
- [ ] Sticky notes contain no internal URLs, client names, or credentials.
- [ ] Exported JSON was re-read top to bottom by a human, once, slowly.

## Final Gate

- [ ] Automated scan (workflow 7 or build script) reports zero findings.
- [ ] Import test: file imports into a clean n8n instance without errors.
- [ ] The workflow fails clearly (not silently) when credentials are missing.

If any box is unchecked, the file does not ship.
