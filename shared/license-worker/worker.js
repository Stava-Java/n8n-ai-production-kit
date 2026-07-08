/**
 * Gumroad license verification proxy.
 *
 * One place to change validation logic later. No database. Free tier is
 * enough for early sales volume.
 *
 * POST { "license_key": "...", "product_id": "..." }
 * -> { "valid": true,  "uses": 3, "product_id": "..." }
 * -> { "valid": false, "reason": "license_not_found" | "purchase_revoked" | ... }
 *
 * Limitation (by design): license keys prove purchase, they do not stop
 * piracy. A determined buyer can remove the license node from a workflow.
 * Treat this as friction and purchase verification, not copy protection.
 */

const GUMROAD_VERIFY_URL = 'https://api.gumroad.com/v2/licenses/verify';
const GUMROAD_TIMEOUT_MS = 10000;

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') {
      return json({ valid: false, reason: 'method_not_allowed' }, 405);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ valid: false, reason: 'invalid_json' }, 400);
    }

    const licenseKey = typeof body.license_key === 'string' ? body.license_key.trim() : '';
    const productId = typeof body.product_id === 'string' ? body.product_id.trim() : '';
    if (!licenseKey || !productId) {
      return json({ valid: false, reason: 'missing_license_key_or_product_id' }, 400);
    }

    // Only verify products this worker is configured for.
    const allowed = (env.ALLOWED_PRODUCT_IDS || '')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
    if (allowed.length > 0 && !allowed.includes(productId)) {
      return json({ valid: false, reason: 'unknown_product' }, 200);
    }

    const params = new URLSearchParams({
      product_id: productId,
      license_key: licenseKey,
      // Set INCREMENT_USES_COUNT="true" to count activations (helps spot
      // widely shared keys). Leave unset for pure verification.
      increment_uses_count: env.INCREMENT_USES_COUNT === 'true' ? 'true' : 'false',
    });

    let gumroad;
    try {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), GUMROAD_TIMEOUT_MS);
      const res = await fetch(GUMROAD_VERIFY_URL, {
        method: 'POST',
        body: params,
        signal: controller.signal,
      });
      clearTimeout(timer);
      // Gumroad returns 404 for unknown keys with a JSON body; parse either way.
      gumroad = await res.json();
    } catch {
      // Never log or echo the license key.
      return json({ valid: false, reason: 'verification_unavailable' }, 502);
    }

    if (!gumroad || gumroad.success !== true) {
      return json({ valid: false, reason: 'license_not_found' }, 200);
    }

    const purchase = gumroad.purchase || {};
    if (purchase.refunded || purchase.chargebacked || purchase.disputed) {
      return json({ valid: false, reason: 'purchase_revoked' }, 200);
    }
    if (purchase.subscription_cancelled_at || purchase.subscription_failed_at) {
      return json({ valid: false, reason: 'subscription_inactive' }, 200);
    }

    // Deliberately omit buyer email and order details from the response.
    return json(
      {
        valid: true,
        product_id: productId,
        uses: typeof gumroad.uses === 'number' ? gumroad.uses : null,
      },
      200
    );
  },
};

function json(data, status) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}
