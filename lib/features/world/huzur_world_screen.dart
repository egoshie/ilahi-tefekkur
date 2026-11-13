import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/point_connection.dart';
import 'package:flutter_earth_globe/point_connection_style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/prayer_service.dart';
import '../../core/services/user_progress_service.dart';
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

  void _syncGlobe(CityPreset city, bool showRoute) {
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
    final globeSize = math.min(
      MediaQuery.sizeOf(context).width - 28,
      370.0,
    );

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
                height: globeSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: globeSize,
                      height: globeSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _gold.withValues(alpha: 0.12),
                            _turquoise.withValues(alpha: 0.055),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    SizedBox.square(
                      dimension: globeSize,
                      child: FlutterEarthGlobe(
                        controller: _globeController,
                        radius: globeSize * 0.465,
                      ),
                    ),
                  ],
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
              const WorldCountryPanel(),
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
              const Text(
                'Dünya haritası: NASA Blue Marble Next Generation',
                textAlign: TextAlign.center,
                style: TextStyle(
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
