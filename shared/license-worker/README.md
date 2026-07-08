# Gumroad License Worker

A tiny Cloudflare Worker that verifies Gumroad license keys. No database, no
paid backend - the free tier covers early sales volume. The n8n workflows call
this worker as their first protected step instead of calling Gumroad directly,
so validation logic has one home when it changes later.

## What It Does

1. Accepts `POST { "license_key": "...", "product_id": "..." }`.
2. Rejects product IDs not in `ALLOWED_PRODUCT_IDS`.
3. Calls Gumroad's `/v2/licenses/verify` endpoint.
4. Treats refunded, chargebacked, or disputed purchases as invalid.
5. Returns `{ "valid": true | false, "reason": "..." }` without exposing the
   buyer's email or order details.

## Known Limitation

Gumroad license keys prove purchase. They do not stop piracy - a determined
buyer can delete the license node from an n8n workflow. This is friction and
purchase verification, not copy protection. Do not build more licensing
infrastructure until piracy is a demonstrated, revenue-relevant problem.

## Deploy (free tier)

```bash
# One-time: sign up at cloudflare.com, then
npm install -g wrangler
wrangler login

# From this folder:
# 1. Put your real Gumroad product ID in wrangler.toml (ALLOWED_PRODUCT_IDS)
# 2. Deploy
wrangler deploy
```

Wrangler prints the worker URL, e.g. `https://gumroad-license-worker.<you>.workers.dev`.
Put that URL in your `.env` as `LICENSE_WORKER_URL`.

## Test

```bash
# Should return {"valid":false,"reason":"license_not_found"}
curl -s -X POST https://gumroad-license-worker.<you>.workers.dev \
  -H "content-type: application/json" \
  -d '{"license_key":"not-a-real-key","product_id":"YOUR_PRODUCT_ID"}'
```

After your first (test) sale on Gumroad, repeat with the real license key from
the receipt - it should return `{"valid":true,...}`. Gumroad also lets you
generate a test purchase from the product dashboard.

## How n8n Uses It

Workflow 5 (AI cost monitor) sends:

```json
{
  "license_key": "{{ $env.PRODUCT_LICENSE_KEY }}",
  "product_id": "{{ $env.GUMROAD_PRODUCT_ID }}"
}
```

and stops with a clear purchase/support message when `valid` is not `true`.
See `products/n8n-ai-production-kit/docs/LICENSE-CHECK.md` for the pattern to
copy into other workflows.

## Cost Controls

- Free tier: 100,000 requests/day - orders of magnitude above early volume.
- Only move to the $5/month plan if the free tier actually becomes limiting.
