import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final String activePlanId;
  final String? statusMessage;
  final RegionalOffer regionalOffer;

  const PremiumState({
    required this.isPremium,
    required this.isSandboxUnlocked,
    this.isLoading = false,
    required this.activePlanId,
    this.statusMessage,
    required this.regionalOffer,
  });

  PremiumState copyWith({
    bool? isPremium,
    bool? isSandboxUnlocked,
    bool? isLoading,
    String? activePlanId,
    String? statusMessage,
    RegionalOffer? regionalOffer,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      isSandboxUnlocked: isSandboxUnlocked ?? this.isSandboxUnlocked,
      isLoading: isLoading ?? this.isLoading,
      activePlanId: activePlanId ?? this.activePlanId,
      statusMessage: statusMessage,
      regionalOffer: regionalOffer ?? this.regionalOffer,
    );
  }
}

final premiumServiceProvider =
    StateNotifierProvider< PremiumServiceNotifier, PremiumState >((ref) {
  return PremiumServiceNotifier();
});

class PremiumServiceNotifier extends StateNotifier< PremiumState > {
  PremiumServiceNotifier()
      : super(
          PremiumState(
            isPremium: true,
            isSandboxUnlocked: true,
            activePlanId: 'annual',
            regionalOffer: _detectOffer(Platform.localeName),
          ),
        ) {
    _loadPersistedState();
  }

  Future< void > _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getBool('sandbox_unlock_premium') ?? true;
    final plan = prefs.getString('active_plan_id') ?? 'annual';
    state = state.copyWith(
      isSandboxUnlocked: unlocked,
      activePlanId: plan,
      isPremium: unlocked || plan != 'free',
    );
  }

  Future< void > toggleSandboxMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sandbox_unlock_premium', enabled);
    state = state.copyWith(
      isSandboxUnlocked: enabled,
      isPremium: enabled || state.activePlanId != 'free',
      statusMessage: enabled
          ? "Huzur Özel içerik erişimi etkinleştirildi."
          : "Standart erişim moduna geçildi.",
    );
  }

  Future< void > activatePlan(String planId) async {
    state = state.copyWith(isLoading: true, statusMessage: null);
    await Future.delayed(const Duration(milliseconds: 250));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_plan_id', planId);
    state = state.copyWith(
      isLoading: false,
      activePlanId: planId,
      isPremium: planId != 'free' || state.isSandboxUnlocked,
      statusMessage: "Seçilen Huzur Özel planı etkinleştirildi.",
    );
  }

  Future< void > restorePurchases() async {
    state = state.copyWith(
      isLoading: true,
      statusMessage: "Satın alımlar kontrol ediliyor...",
    );
    await Future.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(
      isLoading: false,
      isPremium: true,
      isSandboxUnlocked: true,
      statusMessage: "Mevcut Huzur Özel erişiminiz geri yüklendi.",
    );
  }

  void switchSimulatedRegion(String localeCode) {
    state = state.copyWith(regionalOffer: _detectOffer(localeCode));
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
    } else if (lower.contains('de') ||
        lower.contains('fr') ||
        lower.contains('nl')) {
      return const RegionalOffer(
        localeCode: 'de_DE',
        regionLabel: 'Avrupa (EUR)',
        currencySymbol: 'EUR',
        monthlyPrice: '4.99 EUR / ay',
        annualPrice: '29.99 EUR / yıl',
        annualMonthlyEquivalent: 'Aylık 2.49 EUR (%50 Avantaj)',
        lifetimePrice: '79.99 EUR',
      );
    } else {
      return const RegionalOffer(
        localeCode: 'en_US',
        regionLabel: 'Uluslararası (USD)',
        currencySymbol: 'USD',
        monthlyPrice: '4.99 USD / ay',
        annualPrice: '29.99 USD / yıl',
        annualMonthlyEquivalent: 'Aylık 2.49 USD (%50 Avantaj)',
        lifetimePrice: '79.99 USD',
      );
    }
  }
}
