# Optional License Check

Gumroad already gates the download ZIP after purchase. That is enough for the
first release. You do **not** need Cloudflare, a license server, or a database
to build and test this kit locally.

The optional Cloudflare Worker in `shared/license-worker/` is here for later,
if you want workflows to verify a Gumroad license key at runtime.

## When To Use It

Use the optional worker only after:

- The kit imports cleanly.
- The workflows pass the fake-data tests.
- You are close to publishing the Gumroad listing.
- You decide runtime purchase verification is worth the extra buyer setup.

Do not set this up during local validation. It is not required for PK-00
through PK-07 to import or run.

## How To Add It Later

1. Deploy `shared/license-worker/` to Cloudflare Workers.
2. Enable Gumroad license keys on the product.
3. Copy the **Verify License** HTTP node, **License Valid?** IF node, and
   **Stop - Invalid License** node from an older licensed workflow pattern or
   recreate them from `shared/license-worker/README.md`.
4. Wire the valid branch into the workflow's first real node.
5. Never hardcode buyer license keys into workflow JSON.

## Honest Limitation

Gumroad license keys prove purchase. They do not stop piracy. Anyone can
delete license nodes from an imported workflow. Treat this as friction and
purchase verification, not DRM. Do not build heavier licensing until real
sales prove it is needed.
