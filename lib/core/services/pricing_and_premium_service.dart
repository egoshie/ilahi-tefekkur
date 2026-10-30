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
  final String activePlanId;
  final RegionalOffer regionalOffer;

  const PremiumState({
    required this.isPremium,
    required this.isSandboxUnlocked,
    required this.activePlanId,
    required this.regionalOffer,
  });

  PremiumState copyWith({
    bool? isPremium,
    bool? isSandboxUnlocked,
    String? activePlanId,
    RegionalOffer? regionalOffer,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      isSandboxUnlocked: isSandboxUnlocked ?? this.isSandboxUnlocked,
      activePlanId: activePlanId ?? this.activePlanId,
      regionalOffer: regionalOffer ?? this.regionalOffer,
    );
  }
}

final premiumServiceProvider =
    StateNotifierProvider<PremiumServiceNotifier, PremiumState>((ref) {
  return PremiumServiceNotifier();
});

class PremiumServiceNotifier extends StateNotifier<PremiumState> {
  PremiumServiceNotifier()
      : super(
          PremiumState(
            isPremium: false,
            isSandboxUnlocked: false,
            activePlanId: 'free',
            regionalOffer: _detectOffer(Platform.localeName),
          ),
        ) {
    _loadPersistedState();
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final sandbox = prefs.getBool('sandbox_unlock_premium') ?? false;
    final plan = prefs.getString('active_plan_id') ?? 'free';
    state = state.copyWith(
      isSandboxUnlocked: sandbox,
      activePlanId: plan,
      isPremium: sandbox || plan != 'free',
    );
  }

  Future<void> toggleSandboxMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sandbox_unlock_premium', enabled);
    state = state.copyWith(
      isSandboxUnlocked: enabled,
      isPremium: enabled || state.activePlanId != 'free',
    );
  }

  Future<void> activatePlan(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_plan_id', planId);
    state = state.copyWith(
      activePlanId: planId,
      isPremium: planId != 'free' || state.isSandboxUnlocked,
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
        regionLabel: 'Türkiye (PPP Yerel Fiyatlandırma)',
        currencySymbol: 'TL',
        monthlyPrice: '49,99 TL / ay',
        annualPrice: '299,99 TL / yıl',
        annualMonthlyEquivalent: 'Aylık sadece 24,99 TL (%50 Avantaj)',
        lifetimePrice: '749,99 TL (Tek Seferlik)',
      );
    } else if (lower.contains('de') || lower.contains('fr') || lower.contains('nl')) {
      return const RegionalOffer(
        localeCode: 'de_DE',
        regionLabel: 'Avrupa Bölgesi (EUR)',
        currencySymbol: 'EUR',
        monthlyPrice: '4.99 EUR / ay',
        annualPrice: '29.99 EUR / yıl',
        annualMonthlyEquivalent: 'Aylık 2.49 EUR (%50 Avantaj)',
        lifetimePrice: '79.99 EUR (Tek Seferlik)',
      );
    } else {
      return const RegionalOffer(
        localeCode: 'en_US',
        regionLabel: 'Küresel Standart (USD)',
        currencySymbol: 'USD',
        monthlyPrice: '4.99 USD / ay',
        annualPrice: '29.99 USD / yıl',
        annualMonthlyEquivalent: 'Aylık 2.49 USD (%50 Avantaj)',
        lifetimePrice: '79.99 USD (Tek Seferlik)',
      );
    }
  }
}
