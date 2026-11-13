'use strict';

const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const admin = require('firebase-admin');
const {setGlobalOptions} = require('firebase-functions/v2');
const {onCall, onRequest, HttpsError} =
  require('firebase-functions/v2/https');
const {defineString, defineSecret} =
  require('firebase-functions/params');

const {
  AppStoreServerAPIClient,
  Environment,
  SignedDataVerifier,
  Status,
} = require('@apple/app-store-server-library');

admin.initializeApp();

const db = admin.firestore();
const {FieldValue, Timestamp} = admin.firestore;

const REGION = 'europe-west3';
const BUNDLE_ID = 'com.ilahi.tefekkur.ilahiTefekkur';

const PRODUCT_IDS = new Set([
  'com.ilahi.tefekkur.monthly',
  'com.ilahi.tefekkur.annual',
  'com.ilahi.tefekkur.lifetime_access',
]);

const LIFETIME_ID = 'com.ilahi.tefekkur.lifetime_access';

const APPLE_APP_ID = defineString('APPLE_APP_ID', {
  default: '',
});

const APPLE_API_ISSUER_ID = defineSecret('APPLE_API_ISSUER_ID');
const APPLE_API_KEY_ID = defineSecret('APPLE_API_KEY_ID');
const APPLE_API_PRIVATE_KEY = defineSecret('APPLE_API_PRIVATE_KEY');

const APPLE_API_SECRETS = [
  APPLE_API_ISSUER_ID,
  APPLE_API_KEY_ID,
  APPLE_API_PRIVATE_KEY,
];

const APPLE_ROOTS = [
  fs.readFileSync(
    path.join(__dirname, 'certificates', 'AppleRootCA-G3.cer'),
  ),
];

setGlobalOptions({
  region: REGION,
  maxInstances: 20,
});

function requireUser(request) {
  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'Bu işlem için oturum açmalısın.',
    );
  }

  return request.auth.uid;
}

function requireAppCheck(request) {
  if (!request.app) {
    throw new HttpsError(
      'permission-denied',
      'Uygulama doğrulaması başarısız.',
    );
  }
}

function decodeJwsPayload(jws) {
  if (
    typeof jws !== 'string' ||
    jws.length > 100000 ||
    jws.split('.').length !== 3
  ) {
    throw new HttpsError(
      'invalid-argument',
      'Apple işlem verisi geçersiz.',
    );
  }

  try {
    return JSON.parse(
      Buffer.from(jws.split('.')[1], 'base64url').toString('utf8'),
    );
  } catch (_) {
    throw new HttpsError(
      'invalid-argument',
      'Apple işlem verisi okunamadı.',
    );
  }
}

function resolveEnvironment(payload) {
  const value =
    payload.environment ||
    payload.data?.environment ||
    payload.summary?.environment;

  if (value === 'Sandbox') return Environment.SANDBOX;
  if (value === 'Production') return Environment.PRODUCTION;

  throw new HttpsError(
    'failed-precondition',
    'Apple işlem ortamı doğrulanamadı.',
  );
}

function getVerifier(environment) {
  let appAppleId;

  if (environment === Environment.PRODUCTION) {
    appAppleId = Number(APPLE_APP_ID.value());

    if (!Number.isSafeInteger(appAppleId) || appAppleId <= 0) {
      throw new HttpsError(
        'failed-precondition',
        'Üretim doğrulaması için App Store App Apple ID yapılandırılmalı.',
      );
    }
  }

  return new SignedDataVerifier(
    APPLE_ROOTS,
    true,
    environment,
    BUNDLE_ID,
    appAppleId,
  );
}

function getAppleApiClient(environment) {
  const issuerId = APPLE_API_ISSUER_ID.value();
  const keyId = APPLE_API_KEY_ID.value();
  const privateKey = APPLE_API_PRIVATE_KEY.value();

  if (!issuerId || !keyId || !privateKey) {
    throw new HttpsError(
      'failed-precondition',
      'Apple In-App Purchase API anahtarları yapılandırılmamış.',
    );
  }

  return new AppStoreServerAPIClient(
    privateKey,
    keyId,
    issuerId,
    BUNDLE_ID,
    environment,
  );
}

async function verifySignedTransaction(jws) {
  const payload = decodeJwsPayload(jws);
  const environment = resolveEnvironment(payload);
  const verifier = getVerifier(environment);

  const transaction = await verifier.verifyAndDecodeTransaction(jws);

  if (transaction.bundleId !== BUNDLE_ID) {
    throw new HttpsError(
      'permission-denied',
      'Satın alma başka bir uygulamaya ait.',
    );
  }

  if (!PRODUCT_IDS.has(transaction.productId)) {
    throw new HttpsError(
      'permission-denied',
      'Bu ürün Huzur Premium ürünü değil.',
    );
  }

  return {transaction, environment, verifier};
}

async function getCurrentAppleEntitlement(transaction, environment, verifier) {
  const client = getAppleApiClient(environment);
  const now = Date.now();

  if (transaction.productId === LIFETIME_ID) {
    const response = await client.getTransactionInfo(
      transaction.transactionId,
    );

    if (!response.signedTransactionInfo) return null;

    const current = await verifier.verifyAndDecodeTransaction(
      response.signedTransactionInfo,
    );

    if (
      current.productId !== LIFETIME_ID ||
      current.originalTransactionId !== transaction.originalTransactionId ||
      current.revocationDate
    ) {
      return null;
    }

    return {
      transaction: current,
      expiresAt: null,
      productId: current.productId,
    };
  }

  const response = await client.getAllSubscriptionStatuses(
    transaction.originalTransactionId,
  );

  for (const group of response.data || []) {
    for (const item of group.lastTransactions || []) {
      if (
        item.status !== Status.ACTIVE &&
        item.status !== Status.BILLING_GRACE_PERIOD
      ) {
        continue;
      }

      if (!item.signedTransactionInfo) continue;

      const current = await verifier.verifyAndDecodeTransaction(
        item.signedTransactionInfo,
      );

      if (
        current.originalTransactionId !== transaction.originalTransactionId ||
        !PRODUCT_IDS.has(current.productId) ||
        current.productId === LIFETIME_ID ||
        current.revocationDate
      ) {
        continue;
      }

      let validUntil = Number(current.expiresDate || 0);

      if (item.status === Status.BILLING_GRACE_PERIOD) {
        if (!item.signedRenewalInfo) continue;

        const renewal = await verifier.verifyAndDecodeRenewalInfo(
          item.signedRenewalInfo,
        );

        validUntil = Number(renewal.gracePeriodExpiresDate || 0);
      }

      if (validUntil > now) {
        return {
          transaction: current,
          expiresAt: Timestamp.fromMillis(validUntil),
          productId: current.productId,
        };
      }
    }
  }

  return null;
}

function makeTransactionOwnerRef(originalTransactionId) {
  return db.collection('appleTransactionOwners').doc(
    originalTransactionId,
  );
}

function makeEntitlementRef(uid) {
  return db.collection('userEntitlements').doc(uid);
}

exports.verifyPremium = onCall(
  {
    enforceAppCheck: true,
    consumeAppCheckToken: true,
    secrets: APPLE_API_SECRETS,
  },
  async (request) => {
    const uid = requireUser(request);
    requireAppCheck(request);

    const signedTransaction = request.data?.signedTransaction;

    const {
      transaction,
      environment,
      verifier,
    } = await verifySignedTransaction(signedTransaction);

    const current = await getCurrentAppleEntitlement(
      transaction,
      environment,
      verifier,
    );

    const ownerId =
      transaction.originalTransactionId || transaction.transactionId;

    const ownerRef = makeTransactionOwnerRef(ownerId);
    const entitlementRef = makeEntitlementRef(uid);

    const revokedRef = db.collection('revokedAppleTransactions').doc(
      transaction.transactionId,
    );

    if (!current) {
      const [ownerSnap, entitlementSnap] = await Promise.all([
        ownerRef.get(),
        entitlementRef.get(),
      ]);

      if (ownerSnap.exists && ownerSnap.data().uid !== uid) {
        throw new HttpsError(
          'permission-denied',
          'Bu Apple satın alımı başka bir hesaba bağlı.',
        );
      }

      // Yalnızca aynı Apple aboneliğine ait mevcut yetkiyi güncelle.
      if (
        ownerSnap.exists &&
        entitlementSnap.exists &&
        entitlementSnap.data().originalTransactionId === ownerId
      ) {
        await entitlementRef.set({
          isPremium: false,
          verifiedAt: Timestamp.now(),
          updatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
      }

      return {isPremium: false};
    }

    const transactionId = current.transaction.transactionId;
    const currentRevokedRef = db
      .collection('revokedAppleTransactions')
      .doc(transactionId);

    await db.runTransaction(async (tx) => {
      const [ownerSnap, revokedSnap, currentRevokedSnap] =
        await Promise.all([
          tx.get(ownerRef),
          tx.get(revokedRef),
          tx.get(currentRevokedRef),
        ]);

      if (
        (ownerSnap.exists && ownerSnap.data().uid !== uid) ||
        revokedSnap.exists ||
        currentRevokedSnap.exists
      ) {
        throw new HttpsError(
          'permission-denied',
          'Bu Apple satın alımı başka bir hesapla ilişkilendirilmiş veya iptal edilmiş.',
        );
      }

      tx.set(ownerRef, {
        uid,
        originalTransactionId: ownerId,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});

      tx.set(entitlementRef, {
        isPremium: true,
        productId: current.productId,
        transactionId,
        originalTransactionId: ownerId,
        environment:
          environment === Environment.SANDBOX ? 'Sandbox' : 'Production',
        expiresAt: current.expiresAt,
        purchaseDateMillis: Number(
          current.transaction.purchaseDate || 0,
        ),
        verifiedAt: Timestamp.now(),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
    });

    return {
      isPremium: true,
      productId: current.productId,
      expiresAt: current.expiresAt?.toMillis() ?? null,
    };
  },
);

exports.createDua = onCall(
  {enforceAppCheck: true, consumeAppCheckToken: true},
  async (request) => {
    const uid = requireUser(request);
    requireAppCheck(request);

    const body = String(request.data?.body || '').trim();
    const countryCode = String(
      request.data?.countryCode || '',
    ).toUpperCase();

    if (body.length < 8 || body.length > 600) {
      throw new HttpsError(
        'invalid-argument',
        'Dua 8 ile 600 karakter arasında olmalı.',
      );
    }

    if (!/^[A-Z]{2}$/.test(countryCode)) {
      throw new HttpsError(
        'invalid-argument',
        'Geçerli ülke kodu gerekli.',
      );
    }

    const now = Date.now();
    const entitlementRef = makeEntitlementRef(uid);
    const rateRef = db.collection('duaRateLimits').doc(uid);
    const postRef = db.collection('duaPosts').doc();

    await db.runTransaction(async (tx) => {
      const [entitlementSnap, rateSnap] = await Promise.all([
        tx.get(entitlementRef),
        tx.get(rateRef),
      ]);

      if (!entitlementSnap.exists) {
        throw new HttpsError(
          'permission-denied',
          'Dua Bırak için aktif Premium gerekli.',
        );
      }

      const entitlement = entitlementSnap.data();
      const verifiedAt = entitlement.verifiedAt?.toMillis?.() || 0;
      const expiresAt = entitlement.expiresAt?.toMillis?.() || null;

      if (
        entitlement.isPremium !== true ||
        now - verifiedAt > 15 * 60 * 1000 ||
        (expiresAt !== null && expiresAt <= now)
      ) {
        throw new HttpsError(
          'permission-denied',
          'Premium erişimini yenilemelisin.',
        );
      }

      const lastPostAt = rateSnap.exists
        ? rateSnap.data().lastPostAt?.toMillis?.() || 0
        : 0;

      if (now - lastPostAt < 5 * 60 * 1000) {
        throw new HttpsError(
          'resource-exhausted',
          'Yeni bir dua bırakmadan önce biraz beklemelisin.',
        );
      }

      tx.create(postRef, {
        authorUid: uid,
        authorLabel: 'Huzur kullanıcısı',
        body,
        countryCode,
        status: 'active',
        aminCount: 0,
        createdAt: Timestamp.now(),
        expiresAt: Timestamp.fromMillis(
          now + 24 * 60 * 60 * 1000,
        ),
      });

      tx.set(rateRef, {
        lastPostAt: Timestamp.now(),
      });
    });

    return {
      success: true,
      postId: postRef.id,
      expiresAt: now + 24 * 60 * 60 * 1000,
    };
  },
);

exports.listDuas = onCall(
  {enforceAppCheck: true},
  async (request) => {
    requireUser(request);
    requireAppCheck(request);

    const now = Timestamp.now();

    const snapshot = await db.collection('duaPosts')
      .where('status', '==', 'active')
      .where('expiresAt', '>', now)
      .orderBy('expiresAt', 'asc')
      .limit(100)
      .get();

    const posts = snapshot.docs.map((doc) => {
      const data = doc.data();

      return {
        postId: doc.id,
        body: data.body,
        authorLabel: data.authorLabel || 'Huzur kullanıcısı',
        countryCode: data.countryCode,
        aminCount: data.aminCount || 0,
        createdAt: data.createdAt?.toMillis?.() || 0,
        expiresAt: data.expiresAt?.toMillis?.() || 0,
      };
    });

    posts.sort((a, b) => b.createdAt - a.createdAt);

    return {posts};
  },
);

exports.addAmin = onCall(
  {enforceAppCheck: true, consumeAppCheckToken: true},
  async (request) => {
    const uid = requireUser(request);
    requireAppCheck(request);

    const postId = String(request.data?.postId || '');

    if (!/^[A-Za-z0-9_-]{10,80}$/.test(postId)) {
      throw new HttpsError('invalid-argument', 'Dua kaydı geçersiz.');
    }

    const postRef = db.collection('duaPosts').doc(postId);
    const aminRef = postRef.collection('amens').doc(uid);

    return db.runTransaction(async (tx) => {
      const [postSnap, aminSnap] = await Promise.all([
        tx.get(postRef),
        tx.get(aminRef),
      ]);

      if (!postSnap.exists) {
        throw new HttpsError('not-found', 'Dua bulunamadı.');
      }

      const post = postSnap.data();

      if (
        post.status !== 'active' ||
        post.expiresAt.toMillis() <= Date.now()
      ) {
        throw new HttpsError(
          'failed-precondition',
          'Bu duanın 24 saatlik süresi dolmuş.',
        );
      }

      if (post.authorUid === uid) {
        throw new HttpsError(
          'failed-precondition',
          'Kendi duana Âmin ekleyemezsin.',
        );
      }

      if (aminSnap.exists) {
        return {
          added: false,
          aminCount: post.aminCount || 0,
        };
      }

      tx.create(aminRef, {
        createdAt: Timestamp.now(),
      });

      tx.update(postRef, {
        aminCount: FieldValue.increment(1),
      });

      return {
        added: true,
        aminCount: (post.aminCount || 0) + 1,
      };
    });
  },
);

exports.deleteDua = onCall(
  {enforceAppCheck: true, consumeAppCheckToken: true},
  async (request) => {
    const uid = requireUser(request);
    requireAppCheck(request);

    const postId = String(request.data?.postId || '');
    const postRef = db.collection('duaPosts').doc(postId);

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(postRef);

      if (!snap.exists || snap.data().authorUid !== uid) {
        throw new HttpsError(
          'permission-denied',
          'Bu duayı silme yetkin yok.',
        );
      }

      tx.update(postRef, {
        status: 'deleted',
        deletedAt: FieldValue.serverTimestamp(),
      });
    });

    return {success: true};
  },
);

exports.reportDua = onCall(
  {enforceAppCheck: true, consumeAppCheckToken: true},
  async (request) => {
    const uid = requireUser(request);
    requireAppCheck(request);

    const postId = String(request.data?.postId || '');
    const reason = String(request.data?.reason || '');

    const allowedReasons = new Set([
      'spam',
      'inappropriate',
      'personal_information',
      'harassment',
      'other',
    ]);

    if (!allowedReasons.has(reason)) {
      throw new HttpsError(
        'invalid-argument',
        'Bildirim nedeni geçersiz.',
      );
    }

    const postRef = db.collection('duaPosts').doc(postId);
    const reportRef = db.collection('duaReports').doc(
      `${postId}_${uid}`,
    );

    await db.runTransaction(async (tx) => {
      const [postSnap, reportSnap] = await Promise.all([
        tx.get(postRef),
        tx.get(reportRef),
      ]);

      if (!postSnap.exists || postSnap.data().status !== 'active') {
        throw new HttpsError('not-found', 'Dua bulunamadı.');
      }

      if (reportSnap.exists) {
        throw new HttpsError(
          'already-exists',
          'Bu duayı daha önce bildirdin.',
        );
      }

      tx.create(reportRef, {
        postId,
        reporterUid: uid,
        reason,
        createdAt: FieldValue.serverTimestamp(),
        status: 'open',
      });
    });

    return {success: true};
  },
);

exports.syncDhikrBatch = onCall(
  {enforceAppCheck: true, consumeAppCheckToken: true},
  async (request) => {
    const uid = requireUser(request);
    requireAppCheck(request);

    const count = Number(request.data?.count);
    const countryCode = String(
      request.data?.countryCode || '',
    ).toUpperCase();
    const requestId = String(request.data?.requestId || '');

    if (
      !Number.isSafeInteger(count) ||
      count < 1 ||
      count > 500
    ) {
      throw new HttpsError(
        'invalid-argument',
        'Zikir paketi 1 ile 500 arasında olmalı.',
      );
    }

    if (!/^[A-Z]{2}$/.test(countryCode)) {
      throw new HttpsError(
        'invalid-argument',
        'Ülke kodu geçersiz.',
      );
    }

    if (!/^[A-Za-z0-9_-]{12,80}$/.test(requestId)) {
      throw new HttpsError(
        'invalid-argument',
        'İstek kimliği geçersiz.',
      );
    }

    const dateKey = new Date().toISOString().slice(0, 10);
    const batchRef = db.collection('dhikrBatches').doc(
      `${uid}_${requestId}`,
    );
    const userDailyRef = db.collection('userDhikrDaily').doc(
      `${uid}_${dateKey}`,
    );

    const shardId = crypto.randomInt(0, 64)
      .toString()
      .padStart(2, '0');

    const shardRef = db.collection('countryDhikrDaily')
      .doc(dateKey)
      .collection('countries')
      .doc(countryCode)
      .collection('shards')
      .doc(shardId);

    const result = await db.runTransaction(async (tx) => {
      const [batchSnap, dailySnap] = await Promise.all([
        tx.get(batchRef),
        tx.get(userDailyRef),
      ]);

      if (batchSnap.exists) {
        return {processed: false, duplicate: true};
      }

      const dailyTotal = dailySnap.exists
        ? dailySnap.data().count || 0
        : 0;

      if (dailyTotal + count > 100000) {
        throw new HttpsError(
          'resource-exhausted',
          'Günlük senkronizasyon sınırına ulaşıldı.',
        );
      }

      tx.create(batchRef, {
        uid,
        requestId,
        countryCode,
        count,
        dateKey,
        createdAt: FieldValue.serverTimestamp(),
      });

      tx.set(userDailyRef, {
        uid,
        dateKey,
        count: FieldValue.increment(count),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});

      tx.set(shardRef, {
        dateKey,
        countryCode,
        count: FieldValue.increment(count),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});

      return {processed: true, duplicate: false};
    });

    return result;
  },
);

exports.getWorldRanking = onCall(
  {enforceAppCheck: true},
  async (request) => {
    requireUser(request);
    requireAppCheck(request);

    const dateKey = new Date().toISOString().slice(0, 10);

    const snapshot = await db.collectionGroup('shards')
      .where('dateKey', '==', dateKey)
      .get();

    const totals = new Map();

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const code = data.countryCode;
      const count = Number(data.count || 0);

      if (!code || count <= 0) continue;

      totals.set(code, (totals.get(code) || 0) + count);
    }

    const rankings = [...totals.entries()]
      .map(([countryCode, totalCount]) => ({
        countryCode,
        totalCount,
      }))
      .sort((a, b) => b.totalCount - a.totalCount)
      .slice(0, 50)
      .map((item, index) => ({
        rank: index + 1,
        ...item,
      }));

    return {dateKey, rankings};
  },
);

exports.appStoreServerNotifications = onRequest(
  {maxInstances: 10},
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    try {
      const signedPayload = req.body?.signedPayload;
      const untrustedPayload = decodeJwsPayload(signedPayload);
      const environment = resolveEnvironment(untrustedPayload);
      const verifier = getVerifier(environment);

      const notification =
        await verifier.verifyAndDecodeNotification(signedPayload);

      const notificationId = notification.notificationUUID;

      if (!notificationId) {
        res.status(400).send('Missing notification identifier');
        return;
      }

      const notificationRef = db
        .collection('appStoreNotifications')
        .doc(notificationId);

      const existingNotification = await notificationRef.get();

      if (existingNotification.exists) {
        res.status(200).send('Already processed');
        return;
      }

      const signedTransaction =
        notification.data?.signedTransactionInfo;

      if (!signedTransaction) {
        await notificationRef.set({
          notificationType: notification.notificationType || 'UNKNOWN',
          processedAt: FieldValue.serverTimestamp(),
        });

        res.status(200).send('Notification recorded');
        return;
      }

      const transaction =
        await verifier.verifyAndDecodeTransaction(signedTransaction);

      if (!PRODUCT_IDS.has(transaction.productId)) {
        res.status(200).send('Unrelated product');
        return;
      }

      const originalId =
        transaction.originalTransactionId || transaction.transactionId;

      const ownerRef = makeTransactionOwnerRef(originalId);
      const ownerSnap = await ownerRef.get();

      if (!ownerSnap.exists) {
        await notificationRef.set({
          notificationType: notification.notificationType || 'UNKNOWN',
          processedAt: FieldValue.serverTimestamp(),
        });

        res.status(200).send('No linked user');
        return;
      }

      const uid = ownerSnap.data().uid;
      const entitlementRef = makeEntitlementRef(uid);
      const revoked = Boolean(transaction.revocationDate) ||
        ['REFUND', 'REVOKE', 'EXPIRED', 'GRACE_PERIOD_EXPIRED']
          .includes(notification.notificationType);

      let active = !revoked;
      let expiresAt = null;

      if (transaction.productId !== LIFETIME_ID) {
        const expiry = Number(transaction.expiresDate || 0);
        active = active && expiry > Date.now();

        if (
          !active &&
          notification.data?.status === Status.BILLING_GRACE_PERIOD &&
          notification.data?.signedRenewalInfo
        ) {
          const renewal = await verifier.verifyAndDecodeRenewalInfo(
            notification.data.signedRenewalInfo,
          );
          const graceExpiry = Number(
            renewal.gracePeriodExpiresDate || 0,
          );

          active = graceExpiry > Date.now();
          if (active) expiresAt = Timestamp.fromMillis(graceExpiry);
        }

        if (active && expiresAt === null) {
          expiresAt = Timestamp.fromMillis(expiry);
        }
      }

      const notificationRefForTxn = notificationRef;

      await db.runTransaction(async (tx) => {
        const [alreadyProcessed, entitlementSnap] = await Promise.all([
          tx.get(notificationRefForTxn),
          tx.get(entitlementRef),
        ]);

        if (alreadyProcessed.exists) return;

        const currentPurchaseDate = entitlementSnap.exists
          ? entitlementSnap.data().purchaseDateMillis || 0
          : 0;

        const incomingPurchaseDate = Number(
          transaction.purchaseDate || 0,
        );

        if (incomingPurchaseDate >= currentPurchaseDate) {
          tx.set(entitlementRef, {
            isPremium: active,
            productId: transaction.productId,
            transactionId: transaction.transactionId,
            originalTransactionId: originalId,
            environment:
              environment === Environment.SANDBOX
                ? 'Sandbox'
                : 'Production',
            expiresAt,
            purchaseDateMillis: incomingPurchaseDate,
            verifiedAt: Timestamp.now(),
            updatedAt: FieldValue.serverTimestamp(),
          }, {merge: true});
        }

        if (revoked) {
          tx.set(
            db.collection('revokedAppleTransactions')
              .doc(transaction.transactionId),
            {
              originalTransactionId: originalId,
              notificationType: notification.notificationType,
              revokedAt: FieldValue.serverTimestamp(),
            },
            {merge: true},
          );
        }

        tx.create(notificationRefForTxn, {
          notificationType: notification.notificationType || 'UNKNOWN',
          processedAt: FieldValue.serverTimestamp(),
        });
      });

      res.status(200).send('Notification processed');
    } catch (error) {
      console.error(
        'App Store notification verification failed:',
        error?.message || 'unknown error',
      );

      res.status(400).send('Invalid notification');
    }
  },
);
