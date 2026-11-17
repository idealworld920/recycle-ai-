// ReSAI Cloud Functions (Node 22, firebase-functions v6 / v2 API, region asia-northeast3)
//
// - revenuecatWebhook: RevenueCat 웹훅 → users/{uid}.premium 과 households/{id}.premiumUntil 갱신 (클라이언트는 못 쓴다)
// - joinHousehold / leaveHousehold / removeHouseholdMember / transferHouseholdOwner: 집 멤버십 변경 (callable)
// - deleteUserData: 내 데이터 삭제 (users/{uid} 재귀 삭제 + Storage users/{uid}/ + 집에서 제거). RevenueCat 구독자는 건드리지 않는다.
// - setMemberName: 집에서 부르는 내 이름 (members[].nickname/displayName)
// - onCheckin: households/{id}/checkins/{date} 변경 → 체크한 사람 제외 가구원에게 FCM
// - householdEveningReminder: 매일 21:00 KST, 오늘 수거일인데 체크인 0건인 집 → 가구원 전원 FCM (집당 하루 1회)
// 배포 뒤 Cloud Scheduler API 가 켜져 있어야 householdEveningReminder 가 만들어진다 (첫 배포 때 CLI 가 안내).
//
// 배포:   cd functions && npm install && firebase deploy --only functions
// 에뮬레이터: firebase emulators:start --only functions,firestore  (앱에서는 FirebaseFunctions.useFunctionsEmulator('localhost', 5001))
// RevenueCat 대시보드 → Integrations → Webhooks:
//   URL:  https://asia-northeast3-<project>.cloudfunctions.net/revenuecatWebhook
//   Authorization: Bearer <REVENUECAT_WEBHOOK_SECRET>   (firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET)
const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
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

// ---------- 집: 내 이름 ----------
/** 집에서 부르는 내 이름. { name } (1~10자) */
exports.setMemberName = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const name = String((request.data && request.data.name) || "").trim();
  if (!name || name.length > 10) throw new HttpsError("invalid-argument", "이름은 1~10자로 적어 주세요.");
  const h = await householdOf(uid);
  if (!h) throw new HttpsError("not-found", "집에 속해 있지 않아요.");
  const members = memberList(h.data).map((m) => (m.uid === uid ? { ...m, nickname: name, displayName: name } : m));
  await h.ref.update({ members });
  return { ok: true };
});

// ---------- 가족 공유 푸시 (FCM) ----------
const messaging = admin.messaging();

/** 알림 문구 (assets/data/notification_lines.json 과 같은 내용). 뿅체, 이모지 없음. */
const PUSH_LINES = {
  familyCheckin: {
    title: "{이름}님이 버렸뿅",
    bodies: ["{이름}님이 오늘 {품목} 버리고 왔뿅! 든든하뿅", "{이름}님 덕분에 오늘 수거 끝났뿅!", "{이름}님이 다녀왔뿅~ 고맙다고 해주라뿅"],
  },
  familyReminder: {
    title: "아직이뿅…?",
    bodies: ["오늘 수거일인데 아직 아무도 안 버렸뿅! 누가 갈 거뿅?", "{품목} 아직 집에 있뿅… 누가 나갈 차례뿅?", "저녁 9시뿅! 오늘 안 버리면 다음 주까지 기다려야 하뿅"],
  },
};
const WASTE_LABEL = { recycle: "재활용", general: "일반쓰레기", food: "음식물" };

function fill(s, vars) {
  return Object.entries(vars).reduce((acc, [k, v]) => acc.split(`{${k}}`).join(v), s);
}
function pickLine(key, vars) {
  const l = PUSH_LINES[key];
  const body = l.bodies[Math.floor(Math.random() * l.bodies.length)];
  return { title: fill(l.title, vars), body: fill(body, vars) };
}

/** KST 기준 지금. */
function nowKst() {
  return new Date(Date.now() + 9 * 60 * 60 * 1000);
}
function kstDateKey(d = nowKst()) {
  return d.toISOString().slice(0, 10);
}
/** 1=월 … 7=일 (KST) */
function kstWeekday(d = nowKst()) {
  const w = d.getUTCDay();
  return w === 0 ? 7 : w;
}

/** 수신자의 알림 설정(users/{uid}/settings/notifications). 꺼져 있거나 방해 금지면 false. */
async function canNotify(uid, typeKey) {
  const snap = await db.collection("users").doc(uid).collection("settings").doc("notifications").get();
  const data = snap.exists ? snap.data() : {};
  const enabled = data.enabled || {};
  if (enabled[typeKey] === false) return false;
  const quiet = data.quiet || { start: 22 * 60, end: 7 * 60, enabled: true };
  if (quiet.enabled === false) return true;
  const k = nowKst();
  const m = k.getUTCHours() * 60 + k.getUTCMinutes();
  const inQuiet = quiet.start > quiet.end ? (m >= quiet.start || m < quiet.end) : (m >= quiet.start && m < quiet.end);
  return !inQuiet;
}

/** 수신자들에게 발송. 꺼둔 사람·방해 금지 제외, 무효 토큰 삭제. */
async function sendToUsers(uids, typeKey, { title, body, data }) {
  let sent = 0;
  for (const uid of uids) {
    if (!(await canNotify(uid, typeKey))) continue;
    const tokens = await db.collection("users").doc(uid).collection("fcmTokens").get();
    if (tokens.empty) continue;
    const list = tokens.docs.map((d) => ({ ref: d.ref, token: d.data().token })).filter((t) => t.token);
    if (list.length === 0) continue;
    const res = await messaging.sendEachForMulticast({
      tokens: list.map((t) => t.token),
      notification: { title, body },
      data: { type: typeKey, ...(data || {}) },
      android: { priority: "high", notification: { channelId: "family", icon: "ic_launcher" } },
    });
    res.responses.forEach((r, i) => {
      if (r.success) {
        sent++;
        return;
      }
      const code = r.error && r.error.code;
      if (code === "messaging/registration-token-not-registered" || code === "messaging/invalid-registration-token") {
        list[i].ref.delete().catch(() => {});
      }
    });
  }
  return sent;
}

/** households/{id}/checkins/{date} 가 바뀌면: 새로 체크된 품목마다 체크한 사람 제외 가구원에게. */
exports.onCheckin = onDocumentWritten({ region: REGION, document: "households/{hid}/checkins/{date}" }, async (event) => {
  const after = event.data && event.data.after && event.data.after.exists ? event.data.after.data() : null;
  if (!after) return;
  const before = event.data.before && event.data.before.exists ? event.data.before.data() : {};
  const beforeTypes = (before && before.types) || {};
  const afterTypes = after.types || {};
  const newKeys = Object.keys(afterTypes).filter((k) => !beforeTypes[k]);
  if (newKeys.length === 0) return;
  // 오늘(KST) 체크인만 알린다 (과거 날짜 보정은 조용히).
  if (event.params.date !== kstDateKey()) return;
  const h = await db.collection("households").doc(event.params.hid).get();
  if (!h.exists) return;
  const members = memberList(h.data());
  for (const key of newKeys) {
    const entry = afterTypes[key] || {};
    const actorUid = entry.uid;
    const actor = members.find((m) => m.uid === actorUid);
    const name = (actor && (actor.displayName || actor.nickname)) || entry.nickname || "가족";
    const others = members.map((m) => m.uid).filter((u) => u && u !== actorUid);
    if (others.length === 0) continue;
    const line = pickLine("familyCheckin", { "이름": name, "품목": WASTE_LABEL[key] || "재활용" });
    await sendToUsers(others, "family_checkin", { ...line, data: { householdId: event.params.hid, waste: key } });
  }
});

/** 매일 21:00 KST: 오늘 수거일인 집 중 체크인 0건 → 가구원 전원. 집당 하루 1회 (reminderSentDate). */
exports.householdEveningReminder = onSchedule({ region: REGION, schedule: "0 21 * * *", timeZone: "Asia/Seoul" }, async () => {
  const today = kstDateKey();
  const weekday = kstWeekday();
  const homes = await db.collection("households").get();
  let count = 0;
  for (const doc of homes.docs) {
    const data = doc.data();
    if (data.reminderSentDate === today) continue;
    const sched = data.schedule && data.schedule.days ? data.schedule.days : null;
    if (!sched) continue;
    const todayTypes = Object.entries(sched).filter(([, days]) => Array.isArray(days) && days.includes(weekday)).map(([k]) => k);
    if (todayTypes.length === 0) continue;
    const checkins = await doc.ref.collection("checkins").doc(today).get();
    const done = checkins.exists ? Object.keys(checkins.data().types || {}) : [];
    const remaining = todayTypes.filter((t) => !done.includes(t));
    if (remaining.length === 0) continue;
    const uids = memberList(data).map((m) => m.uid).filter(Boolean);
    const line = pickLine("familyReminder", { "품목": remaining.map((t) => WASTE_LABEL[t] || t).join("·") });
    const sent = await sendToUsers(uids, "family_reminder", { ...line, data: { householdId: doc.id } });
    await doc.ref.set({ reminderSentDate: today }, { merge: true });
    if (sent > 0) count++;
  }
  console.log(`evening reminder: ${count} households`);
});
