import 'dart:async';
import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/liquid_glass_theme.dart';

class CityPreset {
  final String name;
  final String country;
  final double latitude;
  final double longitude;

  const CityPreset(this.name, this.country, this.latitude, this.longitude);
}

const List< CityPreset > kGlobalCityPresets = [
  CityPreset("Kadirli, Osmaniye", "Türkiye", 37.3739, 36.0961),
  CityPreset("Osmaniye", "Türkiye", 37.0742, 36.2478),
  CityPreset("İstanbul", "Türkiye", 41.0082, 28.9784),
  CityPreset("Ankara", "Türkiye", 39.9334, 32.8597),
  CityPreset("İzmir", "Türkiye", 38.4237, 27.1428),
  CityPreset("Adana", "Türkiye", 37.0000, 35.3213),
  CityPreset("Bursa", "Türkiye", 40.1885, 29.0610),
  CityPreset("Konya", "Türkiye", 37.8746, 32.4932),
  CityPreset("Gaziantep", "Türkiye", 37.0662, 37.3833),
  CityPreset("Antalya", "Türkiye", 36.8969, 30.7133),
  CityPreset("Mekke-i Mükerreme", "Suudi Arabistan", 21.4225, 39.8262),
  CityPreset("Medine-i Münevvere", "Suudi Arabistan", 24.4672, 39.6112),
  CityPreset("Kudüs", "Filistin", 31.7683, 35.2137),
];

enum CalculationMethodChoice { diyanet, mwl, isna, ummAlQura, egyptian }

class PrayerEngineState {
  final CityPreset selectedCity;
  final CalculationMethodChoice methodChoice;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final PrayerPeriod activePeriod;
  final String nextPrayerName;
  final Duration timeUntilNext;
  final double cycleProgress;
  final double qiblaDirection;
  final String selectedMaqam;
  final int preReminderMinutes;

  const PrayerEngineState({
    required this.selectedCity,
    required this.methodChoice,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.activePeriod,
    required this.nextPrayerName,
    required this.timeUntilNext,
    required this.cycleProgress,
    required this.qiblaDirection,
    required this.selectedMaqam,
    required this.preReminderMinutes,
  });
}

final prayerEngineProvider =
    StateNotifierProvider< PrayerEngineNotifier, PrayerEngineState >((ref) {
  return PrayerEngineNotifier();
});

class PrayerEngineNotifier extends StateNotifier< PrayerEngineState > {
  Timer? _ticker;
  CityPreset _city = kGlobalCityPresets.first;
  CalculationMethodChoice _method = CalculationMethodChoice.diyanet;
  String _maqam = "Hicaz Makamı";
  int _preReminder = 30;
  PrayerPeriod? _manualPreviewPeriod;

  PrayerEngineNotifier()
      : super(_compute(
          kGlobalCityPresets.first,
          CalculationMethodChoice.diyanet,
          "Hicaz Makamı",
          30,
          null,
        )) {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  void _refresh() {
    state = _compute(_city, _method, _maqam, _preReminder, _manualPreviewPeriod);
  }

  void setCity(CityPreset city) {
    _city = city;
    _refresh();
  }

  void setMethod(CalculationMethodChoice method) {
    _method = method;
    _refresh();
  }

  void setMaqam(String maqam) {
    _maqam = maqam;
    _refresh();
  }

  void setPreReminder(int minutes) {
    _preReminder = minutes;
    _refresh();
  }

  void setManualPeriodPreview(PrayerPeriod? period) {
    _manualPreviewPeriod = period;
    _refresh();
  }

  static String _resolveCityNameFromCoords(double lat, double lon) {
    CityPreset closest = kGlobalCityPresets.first;
    double minDistance = double.infinity;

    for (final preset in kGlobalCityPresets) {
      final dLat = lat - preset.latitude;
      final dLon = lon - preset.longitude;
      final dist = math.sqrt(dLat * dLat + dLon * dLon);
      if (dist < minDistance) {
        minDistance = dist;
        closest = preset;
      }
    }

    if (minDistance <= 1.2) {
      return closest.name;
    }
    return "Türkiye";
  }

  Future< void > detectGpsLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition();
        final resolvedName =
            _resolveCityNameFromCoords(pos.latitude, pos.longitude);
        _city = CityPreset(
          resolvedName,
          "Türkiye",
          pos.latitude,
          pos.longitude,
        );
        _refresh();
      }
    } catch (_) {}
  }

  static CalculationParameters _paramsFor(CalculationMethodChoice choice) {
    switch (choice) {
      case CalculationMethodChoice.diyanet:
        return CalculationMethod.turkey.getParameters();
      case CalculationMethodChoice.mwl:
        return CalculationMethod.muslim_world_league.getParameters();
      case CalculationMethodChoice.isna:
        return CalculationMethod.north_america.getParameters();
      case CalculationMethodChoice.ummAlQura:
        return CalculationMethod.umm_al_qura.getParameters();
      case CalculationMethodChoice.egyptian:
        return CalculationMethod.egyptian.getParameters();
    }
  }

  static PrayerEngineState _compute(
    CityPreset city,
    CalculationMethodChoice method,
    String maqam,
    int preReminder,
    PrayerPeriod? manualPeriod,
  ) {
    final coords = Coordinates(city.latitude, city.longitude);
    final params = _paramsFor(method)..madhab = Madhab.shafi;
    final now = DateTime.now();
    final prayerTimes = PrayerTimes.today(coords, params);
    final qibla = Qibla(coords).direction;

    PrayerPeriod currentPeriod;
    String nextName;
    DateTime prevTime;
    DateTime nextTime;

    if (now.isBefore(prayerTimes.fajr)) {
      currentPeriod = PrayerPeriod.yatsi;
      nextName = "İmsak";
      prevTime = prayerTimes.fajr.subtract(const Duration(hours: 6));
      nextTime = prayerTimes.fajr;
    } else if (now.isBefore(prayerTimes.sunrise)) {
      currentPeriod = PrayerPeriod.imsak;
      nextName = "Güneş";
      prevTime = prayerTimes.fajr;
      nextTime = prayerTimes.sunrise;
    } else if (now.isBefore(prayerTimes.dhuhr)) {
      currentPeriod = PrayerPeriod.gunes;
      nextName = "Öğle";
      prevTime = prayerTimes.sunrise;
      nextTime = prayerTimes.dhuhr;
    } else if (now.isBefore(prayerTimes.asr)) {
      currentPeriod = PrayerPeriod.ogle;
      nextName = "İkindi";
      prevTime = prayerTimes.dhuhr;
      nextTime = prayerTimes.asr;
    } else if (now.isBefore(prayerTimes.maghrib)) {
      currentPeriod = PrayerPeriod.ikindi;
      nextName = "Akşam";
      prevTime = prayerTimes.asr;
      nextTime = prayerTimes.maghrib;
    } else if (now.isBefore(prayerTimes.isha)) {
      currentPeriod = PrayerPeriod.aksam;
      nextName = "Yatsı";
      prevTime = prayerTimes.maghrib;
      nextTime = prayerTimes.isha;
    } else {
      currentPeriod = PrayerPeriod.yatsi;
      nextName = "İmsak";
      prevTime = prayerTimes.isha;
      nextTime = prayerTimes.fajr.add(const Duration(days: 1));
    }

    final totalSpan = nextTime.difference(prevTime).inSeconds.clamp(1, 86400);
    final elapsed = now.difference(prevTime).inSeconds.clamp(0, totalSpan);
    final progress = (elapsed / totalSpan).clamp(0.05, 0.98);

    return PrayerEngineState(
      selectedCity: city,
      methodChoice: method,
      fajr: prayerTimes.fajr,
      sunrise: prayerTimes.sunrise,
      dhuhr: prayerTimes.dhuhr,
      asr: prayerTimes.asr,
      maghrib: prayerTimes.maghrib,
      isha: prayerTimes.isha,
      activePeriod: manualPeriod ?? currentPeriod,
      nextPrayerName: nextName,
      timeUntilNext: nextTime.difference(now),
      cycleProgress: progress,
      qiblaDirection: qibla,
      selectedMaqam: maqam,
      preReminderMinutes: preReminder,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
