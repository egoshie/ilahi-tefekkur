import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
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

final premiumServiceProvider = StateNotifierProvider<PremiumServiceNotifier, PremiumState>((ref) {
  return PremiumServiceNotifier();
});

class PremiumServiceNotifier extends StateNotifier<PremiumState> {
  static const String kMonthlyId = 'com.ilahi.tefekkur.monthly';
  static const String kAnnualId = 'com.ilahi.tefekkur.annual';
  static const String kLifetimeId = 'com.ilahi.tefekkur.lifetime';
  static const Set<String> _productIds = {kMonthlyId, kAnnualId, kLifetimeId};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  PremiumServiceNotifier()
      : super(PremiumState(
          isPremium: false,
          activePlanId: 'free',
          regionalOffer: _detectOffer(Platform.localeName),
        )) {
    _initStoreKit();
  }

  Future<void> _initStoreKit() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPremium = prefs.getBool('v50_verified_premium') ?? false;
    final savedPlan = prefs.getString('v50_active_plan_id') ?? 'free';
    state = state.copyWith(isPremium: savedPremium, activePlanId: savedPlan);

    _purchaseSub = _iap.purchaseStream.listen(_onPurchaseUpdate, onError: (_) {
      state = state.copyWith(isLoading: false, statusMessage: 'App Store ödeme iletişimi kesildi.');
    });

    try {
      final available = await _iap.isAvailable();
      if (!available) {
        state = state.copyWith(storeAvailable: false);
        return;
      }
      final response = await _iap.queryProductDetails(_productIds);
      final map = <String, ProductDetails>{};
      for (final p in response.productDetails) {
        map[p.id] = p;
      }
      final base = _detectOffer(Platform.localeName);
      final liveOffer = RegionalOffer(
        localeCode: base.localeCode,
        regionLabel: base.regionLabel,
        currencySymbol: base.currencySymbol,
        monthlyPrice: map[kMonthlyId]?.price ?? base.monthlyPrice,
        annualPrice: map[kAnnualId]?.price ?? base.annualPrice,
        annualMonthlyEquivalent: base.annualMonthlyEquivalent,
        lifetimePrice: map[kLifetimeId]?.price ?? base.lifetimePrice,
      );
      state = state.copyWith(storeAvailable: true, storeProducts: map, regionalOffer: liveOffer);
    } catch (_) {}
  }

  String _mapPlanToStoreId(String planId) {
    switch (planId) {
      case 'monthly': return kMonthlyId;
      case 'lifetime': return kLifetimeId;
      default: return kAnnualId;
    }
  }

  Future<void> activatePlan(String planId) async {
    state = state.copyWith(isLoading: true, statusMessage: null);
    final storeId = _mapPlanToStoreId(planId);
    final product = state.storeProducts[storeId];

    if (product != null) {
      final param = PurchaseParam(productDetails: product);
      try {
        if (planId == 'lifetime') {
          await _iap.buyNonConsumable(purchaseParam: param);
        } else {
          await _iap.buyNonConsumable(purchaseParam: param);
        }
      } catch (_) {
        state = state.copyWith(isLoading: false, statusMessage: 'App Store satın alma penceresi açılamadı.');
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
      state = state.copyWith(
        isLoading: false,
        statusMessage: 'App Store Connect ürün kimliği (\$storeId) onay bekliyor.',
      );
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> detailsList) async {
    for (final purchase in detailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        state = state.copyWith(isLoading: true, statusMessage: 'Apple StoreKit işlemi onaylanıyor...');
      } else if (purchase.status == PurchaseStatus.error) {
        state = state.copyWith(isLoading: false, statusMessage: 'Ödeme işlemi tamamlanamadı.');
      } else if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('v50_verified_premium', true);
        await prefs.setString('v50_active_plan_id', purchase.productID);
        state = state.copyWith(
          isLoading: false,
          isPremium: true,
          activePlanId: purchase.productID,
          statusMessage: 'Huzur Özel aboneliğiniz Apple tarafından doğrulandı.',
        );
      } else if (purchase.status == PurchaseStatus.canceled) {
        state = state.copyWith(isLoading: false, statusMessage: 'Satın alma işlemi iptal edildi.');
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, statusMessage: 'Apple ID satın alımlarınız sorgulanıyor...');
    try {
      await _iap.restorePurchases();
      await Future.delayed(const Duration(milliseconds: 600));
      if (!state.isPremium) {
        state = state.copyWith(isLoading: false, statusMessage: 'Bu Apple kimliğine ait aktif abonelik bulunamadı.');
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, statusMessage: 'Geri yükleme sırasında bağlantı hatası oluştu.');
    }
  }

  static RegionalOffer _detectOffer(String locale) {
    final lower = locale.toLowerCase();
    if (lower.contains('tr')) {
      return const RegionalOffer(
        localeCode: 'tr_TR',
        regionLabel: 'Türkiye',
        currencySymbol: 'TL',
        monthlyPrice: '49,99 TL / ay',
        annualPrice: '299,99 TL / yıl',
        annualMonthlyEquivalent: 'Aylık 24,99 TL (%50 Avantaj)',
        lifetimePrice: '749,99 TL',
      );
    }
    return const RegionalOffer(
      localeCode: 'en_US',
      regionLabel: 'Global',
      currencySymbol: 'USD',
      monthlyPrice: '4.99 USD / mo',
      annualPrice: '29.99 USD / yr',
      annualMonthlyEquivalent: '2.49 USD / mo (Save 50%)',
      lifetimePrice: '79.99 USD',
    );
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}
