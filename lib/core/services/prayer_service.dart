import 'dart:async';
import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/liquid_glass_theme.dart';

class CityPreset {
  final String name;
  final String country;
  final double latitude;
  final double longitude;

  const CityPreset(this.name, this.country, this.latitude, this.longitude);
}

class PrayerNotificationTime {
  final String prayerName;
  final DateTime time;
  final int dayOffset;
  final int prayerIndex;

  const PrayerNotificationTime({
    required this.prayerName,
    required this.time,
    required this.dayOffset,
    required this.prayerIndex,
  });
}

const List<CityPreset> kGlobalCityPresets = [
  CityPreset("Adana", "Türkiye", 37.0000, 35.3213),
  CityPreset("Adıyaman", "Türkiye", 37.7648, 38.2786),
  CityPreset("Afyonkarahisar", "Türkiye", 38.7507, 30.5567),
  CityPreset("Ağrı", "Türkiye", 39.7191, 43.0506),
  CityPreset("Aksaray", "Türkiye", 38.3687, 34.0370),
  CityPreset("Amasya", "Türkiye", 40.6499, 35.8353),
  CityPreset("Ankara", "Türkiye", 39.9334, 32.8597),
  CityPreset("Antalya", "Türkiye", 36.8969, 30.7133),
  CityPreset("Ardahan", "Türkiye", 41.1105, 42.7022),
  CityPreset("Artvin", "Türkiye", 41.1828, 41.8183),
  CityPreset("Aydın", "Türkiye", 37.8560, 27.8416),
  CityPreset("Balıkesir", "Türkiye", 39.6484, 27.8826),
  CityPreset("Bartın", "Türkiye", 41.6344, 32.3375),
  CityPreset("Batman", "Türkiye", 37.8812, 41.1351),
  CityPreset("Bayburt", "Türkiye", 40.2552, 40.2249),
  CityPreset("Bilecik", "Türkiye", 40.0567, 30.0665),
  CityPreset("Bingöl", "Türkiye", 38.8854, 40.4966),
  CityPreset("Bitlis", "Türkiye", 38.4006, 42.1095),
  CityPreset("Bolu", "Türkiye", 40.7395, 31.6116),
  CityPreset("Burdur", "Türkiye", 37.7203, 30.2908),
  CityPreset("Bursa", "Türkiye", 40.1885, 29.0610),
  CityPreset("Çanakkale", "Türkiye", 40.1553, 26.4142),
  CityPreset("Çankırı", "Türkiye", 40.6013, 33.6134),
  CityPreset("Çorum", "Türkiye", 40.5506, 34.9556),
  CityPreset("Denizli", "Türkiye", 37.7765, 29.0864),
  CityPreset("Diyarbakır", "Türkiye", 37.9144, 40.2306),
  CityPreset("Düzce", "Türkiye", 40.8438, 31.1565),
  CityPreset("Edirne", "Türkiye", 41.6818, 26.5623),
  CityPreset("Elazığ", "Türkiye", 38.6748, 39.2225),
  CityPreset("Erzincan", "Türkiye", 39.7500, 39.5000),
  CityPreset("Erzurum", "Türkiye", 39.9055, 41.2658),
  CityPreset("Eskişehir", "Türkiye", 39.7667, 30.5256),
  CityPreset("Gaziantep", "Türkiye", 37.0662, 37.3833),
  CityPreset("Giresun", "Türkiye", 40.9128, 38.3895),
  CityPreset("Gümüşhane", "Türkiye", 40.4603, 39.4814),
  CityPreset("Hakkari", "Türkiye", 37.5744, 43.7408),
  CityPreset("Hatay", "Türkiye", 36.2021, 36.1600),
  CityPreset("Iğdır", "Türkiye", 39.9237, 44.0450),
  CityPreset("Isparta", "Türkiye", 37.7648, 30.5566),
  CityPreset("İstanbul", "Türkiye", 41.0082, 28.9784),
  CityPreset("İzmir", "Türkiye", 38.4237, 27.1428),
  CityPreset("Kahramanmaraş", "Türkiye", 37.5858, 36.9371),
  CityPreset("Karabük", "Türkiye", 41.2000, 32.6333),
  CityPreset("Karaman", "Türkiye", 37.1759, 33.2287),
  CityPreset("Kars", "Türkiye", 40.6167, 43.1000),
  CityPreset("Kastamonu", "Türkiye", 41.3887, 33.7827),
  CityPreset("Kayseri", "Türkiye", 38.7312, 35.4787),
  CityPreset("Kırıkkale", "Türkiye", 39.8468, 33.5153),
  CityPreset("Kırklareli", "Türkiye", 41.7351, 27.2252),
  CityPreset("Kırşehir", "Türkiye", 39.1458, 34.1639),
  CityPreset("Kilis", "Türkiye", 36.7184, 37.1212),
  CityPreset("Kocaeli", "Türkiye", 40.7654, 29.9408),
  CityPreset("Konya", "Türkiye", 37.8746, 32.4932),
  CityPreset("Kütahya", "Türkiye", 39.4167, 29.9833),
  CityPreset("Malatya", "Türkiye", 38.3552, 38.3095),
  CityPreset("Manisa", "Türkiye", 38.6191, 27.4289),
  CityPreset("Mardin", "Türkiye", 37.3212, 40.7245),
  CityPreset("Mersin", "Türkiye", 36.8121, 34.6415),
  CityPreset("Muğla", "Türkiye", 37.2153, 28.3636),
  CityPreset("Muş", "Türkiye", 38.9462, 41.7539),
  CityPreset("Nevşehir", "Türkiye", 38.6244, 34.7239),
  CityPreset("Niğde", "Türkiye", 37.9698, 34.6766),
  CityPreset("Ordu", "Türkiye", 40.9839, 37.8764),
  CityPreset("Osmaniye", "Türkiye", 37.0742, 36.2478),
  CityPreset("Rize", "Türkiye", 41.0201, 40.5234),
  CityPreset("Sakarya", "Türkiye", 40.7569, 30.3781),
  CityPreset("Samsun", "Türkiye", 41.2867, 36.3300),
  CityPreset("Siirt", "Türkiye", 37.9333, 41.9500),
  CityPreset("Sinop", "Türkiye", 42.0231, 35.1531),
  CityPreset("Sivas", "Türkiye", 39.7477, 37.0179),
  CityPreset("Şanlıurfa", "Türkiye", 37.1674, 38.7955),
  CityPreset("Şırnak", "Türkiye", 37.5164, 42.4611),
  CityPreset("Tekirdağ", "Türkiye", 40.9780, 27.5110),
  CityPreset("Tokat", "Türkiye", 40.3167, 36.5500),
  CityPreset("Trabzon", "Türkiye", 41.0015, 39.7178),
  CityPreset("Tunceli", "Türkiye", 39.1079, 39.5401),
  CityPreset("Uşak", "Türkiye", 38.6823, 29.4082),
  CityPreset("Van", "Türkiye", 38.4891, 43.4089),
  CityPreset("Yalova", "Türkiye", 40.6500, 29.2667),
  CityPreset("Yozgat", "Türkiye", 39.8181, 34.8147),
  CityPreset("Zonguldak", "Türkiye", 41.4564, 31.7987),
  CityPreset("Kadirli, Osmaniye", "Türkiye", 37.3739, 36.0961),
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
    StateNotifierProvider<PrayerEngineNotifier, PrayerEngineState>((ref) {
  return PrayerEngineNotifier();
});

class PrayerEngineNotifier extends StateNotifier<PrayerEngineState> {
  Timer? _ticker;
  CityPreset _city = kGlobalCityPresets.first;
  CalculationMethodChoice _method = CalculationMethodChoice.diyanet;
  String _maqam = "Hicaz Makamı";
  int _preReminder = 30;
  PrayerPeriod? _manualPreviewPeriod;
  bool _cityWasExplicitlyChanged = false;

  PrayerEngineNotifier()
      : super(_compute(
          kGlobalCityPresets.first,
          CalculationMethodChoice.diyanet,
          "Hicaz Makamı",
          30,
          null,
        )) {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
    _restoreSavedCity();
  }

  Future<void> _restoreSavedCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_cityWasExplicitlyChanged) return;

      final name = prefs.getString('huzur_selected_city_name');
      final country = prefs.getString('huzur_selected_city_country');
      final latitude = prefs.getDouble('huzur_selected_city_latitude');
      final longitude = prefs.getDouble('huzur_selected_city_longitude');

      if (name == null ||
          country == null ||
          latitude == null ||
          longitude == null ||
          _cityWasExplicitlyChanged) {
        return;
      }

      _city = CityPreset(name, country, latitude, longitude);
      _refresh();
    } catch (_) {}
  }

  Future<void> _persistCity(CityPreset city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('huzur_selected_city_name', city.name);
    await prefs.setString('huzur_selected_city_country', city.country);
    await prefs.setDouble('huzur_selected_city_latitude', city.latitude);
    await prefs.setDouble('huzur_selected_city_longitude', city.longitude);
  }

  void _refresh() {
    state =
        _compute(_city, _method, _maqam, _preReminder, _manualPreviewPeriod);
  }

  Future<void> setCity(CityPreset city) async {
    _cityWasExplicitlyChanged = true;
    _city = city;
    _refresh();
    await _persistCity(city);
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

  List<PrayerNotificationTime> upcomingPrayerNotificationTimes({
    int days = 5,
  }) {
    final currentState = state;
    final coordinates = Coordinates(
      currentState.selectedCity.latitude,
      currentState.selectedCity.longitude,
    );
    final parameters = _paramsFor(currentState.methodChoice)
      ..madhab = Madhab.shafi;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <PrayerNotificationTime>[];

    for (var dayOffset = 0; dayOffset < days; dayOffset++) {
      final date = today.add(Duration(days: dayOffset));
      final times = PrayerTimes(
        coordinates,
        DateComponents.from(date),
        parameters,
      );

      final dayTimes = <PrayerNotificationTime>[
        PrayerNotificationTime(
          prayerName: 'İmsak',
          time: times.fajr,
          dayOffset: dayOffset,
          prayerIndex: 0,
        ),
        PrayerNotificationTime(
          prayerName: 'Öğle',
          time: times.dhuhr,
          dayOffset: dayOffset,
          prayerIndex: 1,
        ),
        PrayerNotificationTime(
          prayerName: 'İkindi',
          time: times.asr,
          dayOffset: dayOffset,
          prayerIndex: 2,
        ),
        PrayerNotificationTime(
          prayerName: 'Akşam',
          time: times.maghrib,
          dayOffset: dayOffset,
          prayerIndex: 3,
        ),
        PrayerNotificationTime(
          prayerName: 'Yatsı',
          time: times.isha,
          dayOffset: dayOffset,
          prayerIndex: 4,
        ),
      ];

      for (final entry in dayTimes) {
        if (entry.time.isAfter(now)) {
          result.add(entry);
        }
      }
    }

    return result;
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

  Future<void> detectGpsLocation() async {
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
        _cityWasExplicitlyChanged = true;
        _city = CityPreset(
          resolvedName,
          "Türkiye",
          pos.latitude,
          pos.longitude,
        );
        await _persistCity(_city);
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
