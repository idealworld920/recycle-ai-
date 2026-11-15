// ReSAI Cloud Functions (Node 20, firebase-functions v2, region asia-northeast3)
//
// - revenuecatWebhook: RevenueCat 웹훅 → users/{uid}.premium 과 households/{id}.premiumUntil 갱신 (클라이언트는 못 쓴다)
// - joinHousehold / leaveHousehold / removeHouseholdMember / transferHouseholdOwner: 집 멤버십 변경 (callable)
// - deleteUserData: 내 데이터 삭제 (users/{uid} 재귀 삭제 + Storage users/{uid}/ + 집에서 제거). RevenueCat 구독자는 건드리지 않는다.
//
// 배포:   cd functions && npm install && firebase deploy --only functions
// 에뮬레이터: firebase emulators:start --only functions,firestore  (앱에서는 FirebaseFunctions.useFunctionsEmulator('localhost', 5001))
// RevenueCat 대시보드 → Integrations → Webhooks:
//   URL:  https://asia-northeast3-<project>.cloudfunctions.net/revenuecatWebhook
//   Authorization: Bearer <REVENUECAT_WEBHOOK_SECRET>   (firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET)
const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const REGION = "asia-northeast3";
const webhookSecret = defineSecret("REVENUECAT_WEBHOOK_SECRET");
const ENTITLEMENT = "premium";
const MAX_MEMBERS = 6;
const CODE_RE = /^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$/;

// ---------- RevenueCat ----------
exports.revenuecatWebhook = onRequest({ region: REGION, secrets: [webhookSecret] }, async (req, res) => {
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
  const premiumUntil = active ? expiresAt : null;

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
  // 방장이 구독한 집: 멤버 전원이 premiumUntil 로 프리미엄을 판단한다.
  for (const uid of ids) {
    const homes = await db.collection("households").where("ownerUid", "==", uid).get();
    homes.forEach((h) => batch.set(h.ref, {
      premiumUntil,
      premiumProductId: active ? (event.product_id || null) : null,
      premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true }));
  }
  await batch.commit();
  return res.status(200).send("ok");
});

// ---------- 집 멤버십 ----------
function requireUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "로그인이 필요해요.");
  return uid;
}

async function householdOf(uid) {
  const user = await db.collection("users").doc(uid).get();
  const id = user.exists ? user.data().householdId : null;
  if (!id) return null;
  const snap = await db.collection("households").doc(id).get();
  if (!snap.exists) return null;
  return { ref: snap.ref, data: snap.data() };
}

function memberList(data) {
  return Array.isArray(data.members) ? data.members : [];
}

function nextColor(members) {
  const used = new Set(members.map((m) => m.color));
  for (let i = 0; i < MAX_MEMBERS; i++) if (!used.has(i)) return i;
  return members.length % MAX_MEMBERS;
}

/** 초대 코드로 참여. { code, nickname } → { householdId } */
exports.joinHousehold = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const code = String((request.data && request.data.code) || "").toUpperCase().replace(/[\s-]/g, "");
  const nickname = String((request.data && request.data.nickname) || "").trim().slice(0, 10) || "나";
  if (!CODE_RE.test(code)) throw new HttpsError("invalid-argument", "초대 코드는 영문·숫자 6자리예요.");

  const existing = await householdOf(uid);
  if (existing) throw new HttpsError("already-exists", "이미 집에 속해 있어요.");

  const found = await db.collection("households").where("inviteCode", "==", code).limit(1).get();
  if (found.empty) throw new HttpsError("not-found", "초대 코드를 찾을 수 없어요.");
  const ref = found.docs[0].ref;

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data();
    const expires = data.inviteCodeExpiresAt ? data.inviteCodeExpiresAt.toMillis() : 0;
    if (Date.now() >= expires) throw new HttpsError("deadline-exceeded", "초대 코드가 만료됐어요.");
    const members = memberList(data);
    if (members.some((m) => m.uid === uid)) return;
    if (members.length >= MAX_MEMBERS) throw new HttpsError("resource-exhausted", "이 집은 이미 6명이에요.");
    const member = { uid, nickname, color: nextColor(members), joinedAt: Date.now() };
    tx.update(ref, {
      members: [...members, member],
      memberUids: admin.firestore.FieldValue.arrayUnion(uid),
    });
    tx.set(db.collection("users").doc(uid), { householdId: ref.id }, { merge: true });
  });
  return { householdId: ref.id };
});

async function removeFromHousehold(ref, uid, { byOwner }) {
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const data = snap.data();
    const members = memberList(data).filter((m) => m.uid !== uid);
    if (members.length === 0) {
      // 마지막 멤버: 집 삭제 (하위 컬렉션은 트랜잭션 밖에서)
      tx.delete(ref);
    } else {
      const update = {
        members,
        memberUids: admin.firestore.FieldValue.arrayRemove(uid),
      };
      if (data.ownerUid === uid) {
        // 방장이 나가면 가장 먼저 들어온 멤버에게 위임. 프리미엄은 새 방장 기준으로 다시 계산되므로 비운다.
        const next = [...members].sort((a, b) => (a.joinedAt || 0) - (b.joinedAt || 0))[0];
        update.ownerUid = next.uid;
        update.premiumUntil = null;
        update.premiumProductId = null;
      }
      tx.update(ref, update);
    }
    tx.set(db.collection("users").doc(uid), { householdId: admin.firestore.FieldValue.delete() }, { merge: true });
  });
  const after = await ref.get();
  if (!after.exists) {
    await db.recursiveDelete(ref).catch(() => {});
  }
  return { byOwner };
}

/** 내가 집을 나간다. 마지막 멤버면 집 삭제, 방장이면 다음 멤버에게 위임. */
exports.leaveHousehold = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const h = await householdOf(uid);
  if (!h) return { ok: true };
  await removeFromHousehold(h.ref, uid, { byOwner: false });
  return { ok: true };
});

/** 방장: 멤버 내보내기. { uid } */
exports.removeHouseholdMember = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const target = String((request.data && request.data.uid) || "");
  const h = await householdOf(uid);
  if (!h || h.data.ownerUid !== uid) throw new HttpsError("permission-denied", "방장만 할 수 있어요.");
  if (!target || target === uid) throw new HttpsError("invalid-argument", "내보낼 멤버를 골라 주세요.");
  if (!memberList(h.data).some((m) => m.uid === target)) throw new HttpsError("not-found", "그 멤버는 이 집에 없어요.");
  await removeFromHousehold(h.ref, target, { byOwner: true });
  return { ok: true };
});

/** 방장: 다른 멤버에게 방장 위임. { uid } */
exports.transferHouseholdOwner = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const target = String((request.data && request.data.uid) || "");
  const h = await householdOf(uid);
  if (!h || h.data.ownerUid !== uid) throw new HttpsError("permission-denied", "방장만 할 수 있어요.");
  if (!memberList(h.data).some((m) => m.uid === target)) throw new HttpsError("not-found", "그 멤버는 이 집에 없어요.");
  // 새 방장의 구독으로 프리미엄을 다시 계산한다 (웹훅이 다음 이벤트에서 채움). 그 전까지는 새 방장의 users.premium 을 본다.
  const owner = await db.collection("users").doc(target).get();
  const p = owner.exists ? owner.data().premium : null;
  const premiumUntil = p && p.active && p.expiresAt ? p.expiresAt : null;
  await h.ref.update({ ownerUid: target, premiumUntil, premiumProductId: premiumUntil ? (p.productId || null) : null });
  return { ok: true };
});

// ---------- 내 데이터 삭제 ----------
/**
 * 호출한 uid 의 서버 데이터 전부 삭제. 앱은 성공하면 Auth 계정 삭제 → RevenueCat logOut → 기기 초기화 → 온보딩으로 간다.
 * - users/{uid} 문서 + 모든 하위 컬렉션(history, usage, checkins, collection, reports, settings, events, guide …) 재귀 삭제
 * - Storage users/{uid}/ 아래 파일 삭제 (버킷이 없으면 건너뜀)
 * - 집 멤버에서 제거 (마지막 멤버면 집 삭제, 방장이면 다음 멤버에게 위임)
 * - RevenueCat 구독자는 삭제하지 않는다 (구독은 Google Play 에 남아 복원 가능해야 함)
 */
exports.deleteUserData = onCall({ region: REGION, timeoutSeconds: 60 }, async (request) => {
  const uid = requireUid(request);
  const started = Date.now();
  const h = await householdOf(uid);
  if (h) await removeFromHousehold(h.ref, uid, { byOwner: false }).catch((e) => console.warn("household leave failed", e));
  await db.recursiveDelete(db.collection("users").doc(uid));
  try {
    await admin.storage().bucket().deleteFiles({ prefix: `users/${uid}/` });
  } catch (e) {
    // 기본 버킷이 없거나 Storage 를 안 쓰는 프로젝트: 무시
    console.warn("storage delete skipped", e && e.message);
  }
  return { ok: true, ms: Date.now() - started };
});
