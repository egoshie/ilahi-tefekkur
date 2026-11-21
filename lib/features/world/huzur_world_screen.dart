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
import 'dua_community_screen.dart';

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
      rotationSpeed: 0.045,
      zoom: 0.42,
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
        isLabelVisible: false,
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
        isLabelVisible: false,
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

  Future<void> _openDuaCommunity() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DuaCommunityScreen(),
      ),
    );
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final globeSize = math.min(
              constraints.maxWidth - 4,
              constraints.maxHeight * 0.78,
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: Platform.isIOS
                      ? UiKitView(
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
                      : Center(
                          child: SizedBox.square(
                            dimension: globeSize,
                            child: FlutterEarthGlobe(
                              controller: _globeController,
                              radius: globeSize * 0.49,
                            ),
                          ),
                        ),
                ),

                // Keep the country-ranking fetch alive to supply map markers,
                // but do not render a text panel over or under the map.
                Positioned(
                  left: 0,
                  top: 0,
                  child: Offstage(
                    child: WorldCountryPanel(
                      onRankingChanged: _onCountryRankingChanged,
                    ),
                  ),
                ),

                // Only two icon buttons remain on the map. No slogans,
                // counter cards or explanatory text cover the world view.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _WorldMapActionButton(
                          icon: Icons.touch_app_rounded,
                          tooltip: 'Zikir çek',
                          semanticLabel: 'Zikir çek, mevcut sayacı artır',
                          onTap: _handleWorldDhikrTap,
                        ),
                        const SizedBox(width: 16),
                        _WorldMapActionButton(
                          icon: Icons.volunteer_activism_rounded,
                          tooltip: 'Dua bırak',
                          semanticLabel: 'Dua bırak sayfasını aç',
                          onTap: _openDuaCommunity,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WorldMapActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final String semanticLabel;
  final VoidCallback onTap;

  const _WorldMapActionButton({
    required this.icon,
    required this.tooltip,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFCE78);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: const Color(0xE9101721),
          shape: CircleBorder(
            side: BorderSide(color: gold.withValues(alpha: 0.78), width: 1.4),
          ),
          elevation: 12,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 62,
              child: Icon(icon, color: gold, size: 29),
            ),
          ),
        ),
      ),
    );
  }
}
