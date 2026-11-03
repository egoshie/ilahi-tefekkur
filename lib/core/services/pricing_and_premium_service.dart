import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegionalOffer {
  final String localeCode;
  final String regionLabel;
  final String currencySymbol;
  final String monthlyPrice;
  final String annualPrice;
  final String annualMonthlyEquivalent;
  final String lifetimePrice;

  const RegionalOffer({
    required this.localeCode,
    required this.regionLabel,
    required this.currencySymbol,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.annualMonthlyEquivalent,
    required this.lifetimePrice,
  });
}

class PremiumState {
  final bool isPremium;
  final bool isSandboxUnlocked;
  final bool isLoading;
  final bool storeAvailable;
  final String activePlanId;
  final String? statusMessage;
  final RegionalOffer regionalOffer;
  final Map<String, ProductDetails> storeProducts;

  const PremiumState({
    required this.isPremium,
    this.isSandboxUnlocked = false,
    this.isLoading = false,
    this.storeAvailable = false,
    required this.activePlanId,
    this.statusMessage,
    required this.regionalOffer,
    this.storeProducts = const {},
  });

  PremiumState copyWith({
    bool? isPremium,
    bool? isSandboxUnlocked,
    bool? isLoading,
    bool? storeAvailable,
    String? activePlanId,
    String? statusMessage,
    RegionalOffer? regionalOffer,
    Map<String, ProductDetails>? storeProducts,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      isSandboxUnlocked: isSandboxUnlocked ?? this.isSandboxUnlocked,
      isLoading: isLoading ?? this.isLoading,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      activePlanId: activePlanId ?? this.activePlanId,
      statusMessage: statusMessage,
      regionalOffer: regionalOffer ?? this.regionalOffer,
      storeProducts: storeProducts ?? this.storeProducts,
    );
  }
}

final premiumServiceProvider =
    StateNotifierProvider<PremiumServiceNotifier, PremiumState>((ref) {
  return PremiumServiceNotifier();
});

class PremiumServiceNotifier extends StateNotifier<PremiumState> {
  static const String kMonthlyId = 'com.ilahi.tefekkur.monthly';
  static const String kAnnualId = 'com.ilahi.tefekkur.annual';
  static const String kLifetimeId = 'com.ilahi.tefekkur.lifetime_access';

  static const Set<String> _productIds = {
    kMonthlyId,
    kAnnualId,
    kLifetimeId,
  };

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  late final Future<void> _initialization;

  PremiumServiceNotifier()
      : super(
          PremiumState(
            isPremium: false,
            isLoading: true,
            activePlanId: 'free',
            regionalOffer: _detectOffer(Platform.localeName),
          ),
        ) {
    _initialization = _initStoreKit();
  }

  Future<bool> ensurePremiumAccess() async {
    try {
      await _initialization;
      return state.isPremium;
    } catch (_) {
      return false;
    }
  }

  Future<void> _initStoreKit() async {
    // Eski yerel Premium bayrakları artık yetki kaynağı değildir.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('v50_verified_premium');
      await prefs.remove('v50_active_plan_id');
    } catch (_) {
      // Yerel önbellek temizlenemese de doğrulama bundan etkilenmez.
    }

    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object error) {
        state = state.copyWith(
          isLoading: false,
          statusMessage: 'App Store ödeme iletişimi kesildi.',
        );
      },
    );

    if (!Platform.isIOS) {
      state = state.copyWith(
        isPremium: false,
        activePlanId: 'free',
        isLoading: false,
        storeAvailable: false,
        statusMessage:
            'Premium satın alımları şu anda iOS App Store üzerinden destekleniyor.',
      );
      return;
    }

    // Ürün sorgusundan bağımsız olarak mevcut Apple yetkilerini kontrol et.
    try {
      await _refreshStoreKitEntitlements();
    } catch (_) {
      state = state.copyWith(
        isPremium: false,
        activePlanId: 'free',
        isLoading: false,
        statusMessage: 'Apple Premium durumu şu anda doğrulanamadı.',
      );
    }

    try {
      final available = await _iap.isAvailable();

      if (!available) {
        state = state.copyWith(
          storeAvailable: false,
          isLoading: false,
          statusMessage:
              state.isPremium ? null : 'App Store şu anda kullanılamıyor.',
        );
        return;
      }

      final response = await _iap.queryProductDetails(_productIds);
      final products = <String, ProductDetails>{};

      for (final product in response.productDetails) {
        if (_productIds.contains(product.id)) {
          products[product.id] = product;
        }
      }

      final base = _detectOffer(Platform.localeName);

      final liveOffer = RegionalOffer(
        localeCode: base.localeCode,
        regionLabel: base.regionLabel,
        currencySymbol: base.currencySymbol,
        monthlyPrice: products[kMonthlyId]?.price ?? base.monthlyPrice,
        annualPrice: products[kAnnualId]?.price ?? base.annualPrice,
        annualMonthlyEquivalent: base.annualMonthlyEquivalent,
        lifetimePrice: products[kLifetimeId]?.price ?? base.lifetimePrice,
      );

      state = state.copyWith(
        storeAvailable: true,
        storeProducts: products,
        regionalOffer: liveOffer,
        statusMessage: response.notFoundIDs.isNotEmpty
            ? 'Bazı Premium ürünleri App Store Connect üzerinde bulunamadı.'
            : null,
      );
    } catch (_) {
      state = state.copyWith(
        storeAvailable: false,
        statusMessage:
            state.isPremium ? null : 'App Store ürünleri şu anda yüklenemedi.',
      );
    }
  }

  String? _mapPlanToStoreId(String planId) {
    switch (planId) {
      case 'monthly':
        return kMonthlyId;
      case 'annual':
        return kAnnualId;
      case 'lifetime':
        return kLifetimeId;
      default:
        return null;
    }
  }

  int _purchaseDateMillis(SK2Transaction transaction) {
    return int.tryParse(transaction.purchaseDate) ?? 0;
  }

  /// StoreKit 2'nin currentEntitlements listesi:
  /// Apple tarafından doğrulanmış ve şu anda erişim hakkı veren
  /// işlemleri döndürür.
  ///
  /// Bu listede bulunmayan bir ürün Premium erişimi açamaz.
  bool _applyCurrentEntitlements(
    List<SK2Transaction> transactions, {
    String? message,
  }) {
    final validProducts = transactions
        .where((transaction) => _productIds.contains(transaction.productId))
        .toList();

    if (validProducts.isEmpty) {
      state = state.copyWith(
        isPremium: false,
        activePlanId: 'free',
        isLoading: false,
        statusMessage: message,
      );
      return false;
    }

    // Ömür boyu ürün mevcutsa önceliği ona ver.
    final lifetime = validProducts.where(
      (transaction) => transaction.productId == kLifetimeId,
    );

    late final SK2Transaction selected;

    if (lifetime.isNotEmpty) {
      selected = lifetime.first;
    } else {
      validProducts.sort(
        (a, b) => _purchaseDateMillis(b).compareTo(_purchaseDateMillis(a)),
      );
      selected = validProducts.first;
    }

    state = state.copyWith(
      isPremium: true,
      activePlanId: selected.productId,
      isLoading: false,
      statusMessage: message,
    );

    return true;
  }

  Future<bool> _refreshStoreKitEntitlements({
    String? successMessage,
  }) async {
    if (!Platform.isIOS) {
      return false;
    }

    final transactions = await SK2Transaction.currentEntitlements();

    return _applyCurrentEntitlements(
      transactions,
      message: successMessage,
    );
  }

  Future<void> activatePlan(String planId) async {
    if (state.isLoading) return;

    if (!Platform.isIOS) {
      state = state.copyWith(
        statusMessage:
            'StoreKit 2 satın alımları yalnızca iOS üzerinde kullanılabilir.',
      );
      return;
    }

    final storeId = _mapPlanToStoreId(planId);

    if (storeId == null) {
      state = state.copyWith(
        statusMessage: 'Geçersiz Premium planı seçildi.',
      );
      return;
    }

    // Aynı aktif aboneliği tekrar satın alma isteği gönderme.
    if (state.isPremium &&
        (state.activePlanId == storeId || state.activePlanId == kLifetimeId)) {
      state = state.copyWith(
        isLoading: false,
        statusMessage: state.activePlanId == kLifetimeId
            ? 'Bu Apple hesabında ömür boyu Huzur erişimi zaten etkin.'
            : 'Seçilen Huzur planı bu Apple hesabında zaten etkin.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      statusMessage: null,
    );

    try {
      final available = await _iap.isAvailable();

      if (!available) {
        state = state.copyWith(
          isLoading: false,
          statusMessage: 'App Store şu anda kullanılamıyor.',
        );
        return;
      }

      ProductDetails? product = state.storeProducts[storeId];

      if (product == null) {
        final response = await _iap.queryProductDetails(_productIds);

        final refreshedProducts = <String, ProductDetails>{};

        for (final item in response.productDetails) {
          if (_productIds.contains(item.id)) {
            refreshedProducts[item.id] = item;
          }
        }

        state = state.copyWith(
          storeAvailable: true,
          storeProducts: refreshedProducts,
        );

        product = refreshedProducts[storeId];
      }

      if (product == null) {
        state = state.copyWith(
          isLoading: false,
          statusMessage:
              'Seçilen Premium ürünü App Store Connect üzerinde bulunamadı.',
        );
        return;
      }

      // Flutter IAP API'sinde abonelikler ve tüketilemeyen ürünler
      // buyNonConsumable ile başlatılır.
      debugPrint(
        'HUZUR_IAP purchase request: '
        'plan=$planId product=${product.id} price=${product.price}',
      );

      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );

      if (!started) {
        state = state.copyWith(
          isLoading: false,
          statusMessage: 'App Store satın alma penceresi açılamadı.',
        );
      }
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        'HUZUR_IAP activatePlan failed: '
        'plan=$planId product=$storeId '
        'code=${error.code} message=${error.message} '
        'details=${error.details}\n$stackTrace',
      );

      var message = 'App Store işlemi başlatılamadı. Kod: ${error.code}.';

      if (error.code == 'storekit_duplicate_product_object') {
        var hasPendingTransaction = false;

        try {
          final unfinished = await SK2Transaction.unfinishedTransactions();

          hasPendingTransaction = unfinished.any(
            (transaction) => transaction.productId == storeId,
          );

          await _refreshStoreKitEntitlements();
        } catch (diagnosticError, diagnosticStack) {
          debugPrint(
            'HUZUR_IAP unfinished transaction check failed: '
            '$diagnosticError\n$diagnosticStack',
          );
        }

        if (state.isPremium &&
            (state.activePlanId == storeId ||
                state.activePlanId == kLifetimeId)) {
          message = 'Bu Apple hesabında seçilen Huzur planı zaten etkin.';
        } else if (hasPendingTransaction) {
          message = 'Bu ürün için önceki bir Apple işlemi hâlâ beklemede. '
              'Satın alımları geri yükleyin ve önceki işlemin sonuçlanmasını bekleyin.';
        } else {
          message =
              'Apple önceki bir satın alma işlemini tamamlanmamış görüyor. '
              'Satın alımları geri yükleyip tekrar deneyin.';
        }
      } else {
        final details =
            '${error.message ?? ''} ${error.details ?? ''}'.toLowerCase();

        if (details.contains('3532') ||
            details.contains('already subscribed') ||
            details.contains('itemalreadyowned')) {
          try {
            await _refreshStoreKitEntitlements();
          } catch (_) {}

          message = state.isPremium
              ? 'Bu Apple hesabında zaten etkin bir Huzur planı var.'
              : 'Apple hesabınızda mevcut bir satın alma görünüyor. '
                  'Satın alımları geri yükleyin.';
        }
      }

      state = state.copyWith(
        isLoading: false,
        statusMessage: message,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'HUZUR_IAP unexpected purchase error: $error\n$stackTrace',
      );

      state = state.copyWith(
        isLoading: false,
        statusMessage: 'App Store satın alma işlemi başlatılamadı.',
      );
    }
  }

  Future<void> _onPurchaseUpdate(
    List<PurchaseDetails> detailsList,
  ) async {
    for (final purchase in detailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(
            isLoading: true,
            statusMessage: 'Apple satın alma işlemi bekleniyor...',
          );
          break;

        case PurchaseStatus.error:
          state = state.copyWith(
            isLoading: false,
            statusMessage: 'Ödeme işlemi tamamlanamadı.',
          );
          break;

        case PurchaseStatus.canceled:
          state = state.copyWith(
            isLoading: false,
            statusMessage: 'Satın alma işlemi iptal edildi.',
          );
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (!Platform.isIOS) {
            state = state.copyWith(
              isLoading: false,
              statusMessage:
                  'Bu platform için satın alma doğrulaması yapılandırılmadı.',
            );
            break;
          }

          bool exactPurchaseVerified = false;

          try {
            // PurchaseStatus tek başına doğrulama değildir.
            // Yalnızca Apple'ın doğruladığı currentEntitlements
            // listesinde aynı ürün bulunursa işlem onaylanır.
            final transactions = await SK2Transaction.currentEntitlements();

            exactPurchaseVerified = transactions.any(
              (transaction) =>
                  transaction.productId == purchase.productID &&
                  _productIds.contains(transaction.productId),
            );

            if (exactPurchaseVerified) {
              _applyCurrentEntitlements(
                transactions,
                message: 'Premium erişiminiz Apple tarafından doğrulandı.',
              );
            } else {
              // Başka geçerli bir Premium ürünü varsa onu koru.
              _applyCurrentEntitlements(transactions);

              state = state.copyWith(
                isLoading: false,
                statusMessage:
                    'Bu satın alma Apple tarafından aktif yetki olarak doğrulanamadı. Premium erişimi bu işlemle açılmadı.',
              );
            }
          } catch (_) {
            state = state.copyWith(
              isLoading: false,
              statusMessage:
                  'Apple doğrulamasına şu anda ulaşılamadı. Premium erişimi açılmadı.',
            );
          }

          // İşlem ancak doğrulanmış ve uygulamaya teslim edilmişse bitirilir.
          if (exactPurchaseVerified && purchase.pendingCompletePurchase) {
            try {
              await _iap.completePurchase(purchase);
            } catch (_) {
              state = state.copyWith(
                statusMessage:
                    'Premium doğrulandı; ancak satın alma işlemi App Store üzerinde henüz tamamlanamadı.',
              );
            }
          }
          break;
      }
    }
  }

  Future<void> restorePurchases() async {
    if (!Platform.isIOS) {
      state = state.copyWith(
        isLoading: false,
        statusMessage:
            'Satın alım geri yükleme yalnızca iOS App Store için yapılandırıldı.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      statusMessage: 'Apple satın alımlarınız kontrol ediliyor...',
    );

    try {
      await _iap.restorePurchases();

      final restored = await _refreshStoreKitEntitlements(
        successMessage: 'Satın alımlarınız Apple tarafından doğrulandı.',
      );

      if (!restored) {
        state = state.copyWith(
          isLoading: false,
          statusMessage:
              'Bu Apple hesabında aktif Huzur Premium satın alımı bulunamadı.',
        );
      }
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        statusMessage: 'Satın alımlar geri yüklenirken bir hata oluştu.',
      );
    }
  }

  static RegionalOffer _detectOffer(String locale) {
    final lower = locale.toLowerCase();

    if (lower.contains('tr')) {
      return const RegionalOffer(
        localeCode: 'tr_TR',
        regionLabel: 'Türkiye',
        currencySymbol: 'TL',
        monthlyPrice: '120 TL / ay',
        annualPrice: '799 TL / yıl',
        annualMonthlyEquivalent: 'Aylık 66,58 TL',
        lifetimePrice: '1.500 TL',
      );
    }

    return const RegionalOffer(
      localeCode: 'en_US',
      regionLabel: 'Global',
      currencySymbol: 'USD',
      monthlyPrice: '4.99 USD / mo',
      annualPrice: '29.99 USD / yr',
      annualMonthlyEquivalent: '2.49 USD / mo',
      lifetimePrice: '79.99 USD',
    );
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}
