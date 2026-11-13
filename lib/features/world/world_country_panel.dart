import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/huzur_api_service.dart';

class WorldCountryPanel extends StatefulWidget {
  const WorldCountryPanel({super.key});

  @override
  State<WorldCountryPanel> createState() => _WorldCountryPanelState();
}

class _WorldCountryPanelState extends State<WorldCountryPanel> {
  static const _gold = Color(0xFFFFCE78);
  static const _turquoise = Color(0xFF75DCCF);
  static const _panel = Color(0xFF121F20);
  static const _countryKey = 'huzur_world_country_code';

  final HuzurApiService _api = HuzurApiService();

  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _ranking = [];

  String _selectedCode = 'TR';
  int _totalCount = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_countryKey) ?? 'TR';

      final results = await Future.wait([
        _api.getCountries(),
        _api.getWorldRanking(),
      ]);

      final countryResponse = results[0];
      final rankingResponse = results[1];

      final countries = (countryResponse['countries'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final ranking = (rankingResponse['countries'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (!mounted) return;

      final availableCodes = countries
          .map((item) => item['country_code']?.toString())
          .whereType<String>()
          .toSet();

      setState(() {
        _countries = countries;
        _ranking = ranking;
        _selectedCode =
            availableCodes.contains(savedCode) ? savedCode : 'TR';
        _totalCount = (rankingResponse['total_count'] as num?)?.toInt() ?? 0;
        _error = null;
        _loading = false;
      });

      if (_selectedCode != savedCode) {
        await prefs.setString(_countryKey, _selectedCode);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Dünya verileri şu anda yüklenemedi.';
        _loading = false;
      });
      debugPrint('Huzur World yükleme hatası: $error');
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await _loadData();
  }

  Future<void> _selectCountry(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countryKey, code);

    if (!mounted) return;
    setState(() => _selectedCode = code);

    // Oturum açıksa profil ülkesini de sunucuya kaydet.
    // Oturum yoksa yerel seçim korunur.
    try {
      await _api.updateMyCountry(code);
    } catch (error) {
      debugPrint('Huzur ülke profili senkronizasyonu beklemede: $error');
    }
  }

  String _countryName(String code) {
    for (final country in _countries) {
      if (country['country_code']?.toString() == code) {
        return country['country_name']?.toString() ?? code;
      }
    }
    return code;
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validCodes = _countries
        .map((item) => item['country_code']?.toString())
        .whereType<String>()
        .toSet();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: _gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'HUZUR DÜNYA SIRALAMASI',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _refresh,
                tooltip: 'Yenile',
                icon: const Icon(Icons.refresh_rounded, color: _turquoise),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'DÜNYA GENELİNDE BUGÜNKÜ ZİKİR',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _totalCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Divider(color: Colors.white12, height: 26),
          const Text(
            'ÜLKENİ SEÇ',
            style: TextStyle(
              color: _gold,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: validCodes.contains(_selectedCode)
                ? _selectedCode
                : null,
            isExpanded: true,
            dropdownColor: const Color(0xFF1B2B2C),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.045),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 5,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: _gold),
              ),
            ),
            hint: const Text(
              'Ülke seç',
              style: TextStyle(color: Colors.white54),
            ),
            items: _countries.map((country) {
              final code = country['country_code'].toString();
              final name = country['country_name'].toString();

              return DropdownMenuItem<String>(
                value: code,
                child: Text('$name ($code)'),
              );
            }).toList(),
            onChanged: _loading
                ? null
                : (code) {
                    if (code != null) unawaited(_selectCountry(code));
                  },
          ),
          const SizedBox(height: 20),
          const Text(
            'BUGÜNÜN ÜLKE SIRALAMASI',
            style: TextStyle(
              color: _gold,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: _gold),
              ),
            )
          else if (_error != null)
            Column(
              children: [
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                TextButton(
                  onPressed: _refresh,
                  child: const Text(
                    'Tekrar dene',
                    style: TextStyle(color: _gold),
                  ),
                ),
              ],
            )
          else if (_ranking.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Text(
                'Bugün henüz dünya sıralamasına yansıyan zikir yok.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            )
          else
            ..._ranking.take(10).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final code = item['country_code']?.toString() ?? '';
              final count = (item['total_count'] as num?)?.toInt() ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 27,
                      child: Text(
                        '${index + 1}.',
                        style: TextStyle(
                          color: index == 0 ? _gold : Colors.white54,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${_countryName(code)} ($code)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        color: _turquoise,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 5),
          const Text(
            'Sıralama günlük olarak sunucudan güncellenir.',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
