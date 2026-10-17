// RevenueCat 웹훅 → users/{uid}.premium 갱신. 클라이언트는 이 필드를 못 쓴다(firestore.rules).
//
// 배포: cd functions && npm install && firebase deploy --only functions
// RevenueCat 대시보드 → Integrations → Webhooks 에 아래 URL 과 Authorization 헤더 값을 등록:
//   URL:  https://<region>-<project>.cloudfunctions.net/revenuecatWebhook
//   Authorization: Bearer <REVENUECAT_WEBHOOK_SECRET>
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

admin.initializeApp();
const webhookSecret = defineSecret("REVENUECAT_WEBHOOK_SECRET");
const ENTITLEMENT = "premium";

exports.revenuecatWebhook = onRequest({ region: "asia-northeast3", secrets: [webhookSecret] }, async (req, res) => {
  if (req.method !== "POST") return res.status(405).send("POST only");
  const auth = req.get("Authorization") || "";
  if (auth !== `Bearer ${webhookSecret.value()}`) return res.status(401).send("unauthorized");

  const event = req.body && req.body.event;
  if (!event) return res.status(400).send("no event");

  // app_user_id 와 aliases 전부에 반영 (익명 uid → 구글 uid alias)
  const ids = new Set([event.app_user_id, event.original_app_user_id, ...(event.aliases || [])].filter(Boolean));
  const active = Array.isArray(event.entitlement_ids) && event.entitlement_ids.includes(ENTITLEMENT)
    && !["EXPIRATION", "CANCELLATION_EXPIRED", "BILLING_ISSUE_EXPIRED"].includes(event.type);
  const expiresAt = event.expiration_at_ms ? admin.firestore.Timestamp.fromMillis(event.expiration_at_ms) : null;

  const db = admin.firestore();
  const batch = db.batch();
  for (const uid of ids) {
    batch.set(db.collection("users").doc(uid), {
      premium: {
        active,
        productId: event.product_id || null,
        expiresAt,
        store: event.store || null,
        lastEvent: event.type,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    }, { merge: true });
  }
  await batch.commit();
  return res.status(200).send("ok");
});
