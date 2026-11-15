import 'dart:async';
import 'dart:math' as math;
import 'dart:io' show Platform;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/point_connection.dart';
import 'package:flutter_earth_globe/point_connection_style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/prayer_service.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/services/tasbih_session_service.dart';
import 'world_country_panel.dart';
import 'dua_community_panel.dart';

class HuzurWorldScreen extends ConsumerStatefulWidget {
  final ValueChanged<int>? onSwitchTab;

  const HuzurWorldScreen({super.key, this.onSwitchTab});

  @override
  ConsumerState<HuzurWorldScreen> createState() => _HuzurWorldScreenState();
}

class _HuzurWorldScreenState extends ConsumerState<HuzurWorldScreen> {
  static const _mecca = GlobeCoordinates(21.4225, 39.8262);

  static const _gold = Color(0xFFFFCE78);
  static const _turquoise = Color(0xFF75DCCF);
  static const _background = Color(0xFF080F12);

  late final FlutterEarthGlobeController _globeController;
  MethodChannel? _appleMapChannel;
  List<Map<String, dynamic>> _countryMarkers = [];

  String? _lastCityKey;
  bool? _routeVisible;

  @override
  void initState() {
    super.initState();

    _globeController = FlutterEarthGlobeController(
      surface: const AssetImage('assets/world/earth.jpg'),
      rotationSpeed: 0.028,
      zoom: 0.15,
      minZoom: -0.35,
      maxZoom: 2.2,
      isRotating: true,
      isZoomEnabled: true,
      showAtmosphere: true,
      atmosphereColor: _gold,
      atmosphereOpacity: 0.32,
      atmosphereThickness: 0.075,
      atmosphereBlur: 24,
      surfaceLightingEnabled: true,
      lightIntensity: 0.82,
      ambientLight: 0.58,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final city = ref.read(prayerEngineProvider).selectedCity;
      final count = ref.read(userProgressProvider).dailyDhikrCount;

      _syncGlobe(city, count > 0);
    });
  }

  void _onCountryRankingChanged(
    List<Map<String, dynamic>> markers,
  ) {
    _countryMarkers = markers;
    unawaited(_sendAppleCountryMarkers());
  }

  Future<void> _sendAppleCountryMarkers() async {
    final channel = _appleMapChannel;
    if (!Platform.isIOS || channel == null) return;

    try {
      await channel.invokeMethod<void>(
        "setCountryMarkers",
        _countryMarkers,
      );
    } catch (error) {
      debugPrint("Huzur ülke noktaları güncellenemedi: $error");
    }
  }

  void _onAppleMapCreated(int viewId) {
    if (!mounted) return;

    _appleMapChannel = MethodChannel(
      "com.ilahi.tefekkur/apple-world-map/$viewId",
    );

    final city = ref.read(prayerEngineProvider).selectedCity;
    final count = ref.read(userProgressProvider).dailyDhikrCount;

    unawaited(_sendAppleMapUpdate(city, count > 0));
    unawaited(_sendAppleCountryMarkers());
  }

  Future<void> _sendAppleMapUpdate(
    CityPreset city,
    bool showRoute,
  ) async {
    final channel = _appleMapChannel;
    if (!Platform.isIOS || channel == null) return;

    try {
      await channel.invokeMethod<void>("updateCity", {
        "cityName": city.name,
        "latitude": city.latitude,
        "longitude": city.longitude,
        "showRoute": showRoute,
      });
    } catch (error) {
      debugPrint("Huzur Apple Maps güncellemesi: $error");
    }
  }

  Future<void> _focusAppleMapOnMecca() async {
    if (!Platform.isIOS) return;

    final channel = _appleMapChannel;
    if (channel == null) return;

    try {
      await channel.invokeMethod<void>("focusOnMecca");
    } catch (error) {
      debugPrint("Huzur Apple Maps kamera hareketi: $error");
    }
  }

  void _syncGlobe(CityPreset city, bool showRoute) {
    unawaited(_sendAppleMapUpdate(city, showRoute));
    final cityKey = '${city.name}|${city.latitude}|${city.longitude}';

    if (_lastCityKey == cityKey && _routeVisible == showRoute) return;

    _lastCityKey = cityKey;
    _routeVisible = showRoute;

    _globeController.removePoint('current-city');
    _globeController.removePoint('makkah');
    _globeController.removePointConnection('city-to-makkah');

    final cityCoordinates = GlobeCoordinates(city.latitude, city.longitude);

    _globeController.addPoint(
      Point(
        id: 'current-city',
        coordinates: cityCoordinates,
        label: city.name,
        isLabelVisible: true,
        style: const PointStyle(
          color: _turquoise,
          size: 7,
          altitude: 0.025,
        ),
      ),
    );

    _globeController.addPoint(
      Point(
        id: 'makkah',
        coordinates: _mecca,
        label: 'Mekke-i Mükerreme',
        isLabelVisible: true,
        style: const PointStyle(
          color: _gold,
          size: 9,
          altitude: 0.035,
        ),
      ),
    );

    if (showRoute) {
      _globeController.addPointConnection(
        PointConnection(
          id: 'city-to-makkah',
          start: cityCoordinates,
          end: _mecca,
          curveScale: 0.55,
          isMoving: true,
          style: const PointConnectionStyle(
            type: PointConnectionType.dashed,
            color: _gold,
            lineWidth: 2.2,
            dashSize: 5,
            spacing: 6,
            dashAnimateTime: 1600,
            animateOnAdd: true,
            growthAnimationDuration: 1400,
          ),
        ),
      );
    }
  }

  Future<void> _handleWorldDhikrTap() async {
    final session = ref.read(tasbihSessionProvider);

    if (session.activeRecord == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zikir kayıtları hazırlanıyor.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final nextCount =
        await ref.read(tasbihSessionProvider.notifier).incrementActive();

    if (!mounted || nextCount <= 0) return;

    if (session.hapticEnabled) {
      if (nextCount % 100 == 0) {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 80));
        if (mounted) await HapticFeedback.heavyImpact();
      } else if (nextCount % 33 == 0) {
        await HapticFeedback.mediumImpact();
      } else {
        await HapticFeedback.selectionClick();
      }
    }

    if (Platform.isIOS && mounted) {
      try {
        await _appleMapChannel?.invokeMethod<void>('animateDhikr');
      } catch (error) {
        debugPrint('Huzur Mekke animasyonu: $error');
      }
    }
  }

  Future<void> _openTasbih() async {
    await Navigator.of(context).maybePop();
    widget.onSwitchTab?.call(2);
  }

  @override
  void dispose() {
    _globeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(prayerEngineProvider, (previous, next) {
      final count = ref.read(userProgressProvider).dailyDhikrCount;
      _syncGlobe(next.selectedCity, count > 0);
    });

    ref.listen(userProgressProvider, (previous, next) {
      final wasActive = (previous?.dailyDhikrCount ?? 0) > 0;
      final isActive = next.dailyDhikrCount > 0;

      if (wasActive != isActive) {
        final city = ref.read(prayerEngineProvider).selectedCity;
        _syncGlobe(city, isActive);
      }
    });

    final prayer = ref.watch(prayerEngineProvider);
    final progress = ref.watch(userProgressProvider);
    final tasbihSession = ref.watch(tasbihSessionProvider);
    final activeTasbih = tasbihSession.activeRecord;
    final dhikrCount = activeTasbih?.count ?? 0;
    final dhikrTarget = (activeTasbih?.target ?? 33).clamp(1, 999999);
    final dhikrProgress = (dhikrCount % dhikrTarget) / dhikrTarget;
    final globeSize = math.min(
      MediaQuery.sizeOf(context).width - 28,
      370.0,
    );
    final mapHeight = (MediaQuery.sizeOf(context).height * 0.66)
        .clamp(480.0, 720.0)
        .toDouble();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _gold,
        elevation: 0,
        title: const Text(
          'Huzur Dünya',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'DÜNYANIN HER YERİNDE, AYNI NİYETLE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Birlikte edilen her zikir,\\nkalpleri Mekke’ye bağlar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: Platform.isIOS ? mapHeight : globeSize,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (Platform.isIOS)
                        UiKitView(
                          viewType: "com.ilahi.tefekkur/apple-world-map",
                          layoutDirection: TextDirection.ltr,
                          creationParams: {
                            "cityName": prayer.selectedCity.name,
                            "latitude": prayer.selectedCity.latitude,
                            "longitude": prayer.selectedCity.longitude,
                            "showRoute": progress.dailyDhikrCount > 0,
                          },
                          creationParamsCodec: const StandardMessageCodec(),
                          onPlatformViewCreated: _onAppleMapCreated,
                        )
                      else
                        Center(
                          child: SizedBox.square(
                            dimension: globeSize,
                            child: FlutterEarthGlobe(
                              controller: _globeController,
                              radius: globeSize * 0.465,
                            ),
                          ),
                        ),
                      const IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x30050A12),
                                Colors.transparent,
                                Color(0x18050A12),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xD9101721),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.45),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.public_rounded,
                                color: _gold,
                                size: 15,
                              ),
                              SizedBox(width: 7),
                              Text(
                                "HUZUR DÜNYA",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 72,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xE910151D),
                            borderRadius: BorderRadius.circular(21),
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.48),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.28),
                                blurRadius: 18,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'DÜNYA ÜZERİNDE ZİKİR',
                                      style: TextStyle(
                                        color: _gold,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      activeTasbih?.title ??
                                          'Zikir kayıtları hazırlanıyor',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          child: Text(
                                            '$dhikrCount',
                                            key: ValueKey(dhikrCount),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 25,
                                              fontWeight: FontWeight.w900,
                                              fontFeatures: [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          '/ $dhikrTarget',
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Text(
                                      'Mekke’ye yönelen her dokunuş',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Semantics(
                                button: true,
                                label: 'Zikri bir artır',
                                child: GestureDetector(
                                  onTap: activeTasbih == null
                                      ? null
                                      : _handleWorldDhikrTap,
                                  child: SizedBox(
                                    width: 62,
                                    height: 62,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox.expand(
                                          child: CircularProgressIndicator(
                                            value: dhikrProgress.toDouble(),
                                            strokeWidth: 3,
                                            backgroundColor: Colors.white12,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(_gold),
                                          ),
                                        ),
                                        Container(
                                          width: 49,
                                          height: 49,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _gold.withValues(
                                              alpha: 0.16,
                                            ),
                                            border: Border.all(
                                              color: _gold.withValues(
                                                alpha: 0.65,
                                              ),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.touch_app_rounded,
                                            color: _gold,
                                            size: 27,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xE6151B25),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.65),
                            ),
                          ),
                          child: IconButton(
                            tooltip: "Mekke konumuna odaklan",
                            onPressed: Platform.isIOS
                                ? () => unawaited(_focusAppleMapOnMecca())
                                : null,
                            icon: const Icon(
                              Icons.mosque_rounded,
                              color: _gold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  color: const Color(0xFF121F20),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BUGÜNKÜ ZİKRİN',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        progress.dailyDhikrCount.toString(),
                        key: ValueKey(progress.dailyDhikrCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 35,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 25),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: _turquoise,
                          size: 19,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Zikir konumun',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '${prayer.selectedCity.name}, '
                                '${prayer.selectedCity.country}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: _gold,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.mosque_rounded,
                          color: _gold,
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Mekke',
                          style: TextStyle(
                            color: _gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Text(
                      progress.dailyDhikrCount > 0
                          ? 'Mekke’ye uzanan ışık hattın açık.'
                          : 'Zikre başladığında Mekke’ye uzanan ışık hattın belirecek.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WorldCountryPanel(
                onRankingChanged: _onCountryRankingChanged,
              ),
              const SizedBox(height: 16),
              const DuaCommunityPanel(),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openTasbih,
                icon: const Icon(Icons.favorite_rounded),
                label: const Text('Zikre devam et'),
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: const Color(0xFF17120A),
                  minimumSize: const Size(double.infinity, 52),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                Platform.isIOS
                    ? "Apple Harita • Uydu görüntüsü"
                    : "3D Dünya görünümü",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
