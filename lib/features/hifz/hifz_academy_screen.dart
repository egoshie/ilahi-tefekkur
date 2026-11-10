import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/v42_models.dart';
import '../../core/services/database_seeder.dart';
import '../../core/services/hifz_progress_service.dart';
import '../../core/theme/glass_container.dart';

class HifzAcademyScreen extends ConsumerStatefulWidget {
  const HifzAcademyScreen({super.key});

  @override
  ConsumerState<HifzAcademyScreen> createState() => _HifzAcademyScreenState();
}

class _HifzAcademyScreenState extends ConsumerState<HifzAcademyScreen> {
  List<SurahMeta> _surahs = [];
  List<LiveAyahItem> _ayahs = [];
  SurahMeta? _selectedSurah;
  bool _loading = true;
  bool _hideTranslation = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final items = await ref.read(databaseServiceProvider).fetchAllSurahs();
      if (!mounted) return;

      setState(() {
        _surahs = items;
        _selectedSurah = items.isNotEmpty ? items.first : null;
      });

      if (_selectedSurah != null) {
        await _loadSurah(_selectedSurah!);
      } else {
        setState(() {
          _loading = false;
          _error = 'Sure kataloğu bulunamadı.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Sure listesi yüklenemedi. Yeniden deneyebilirsin.';
      });
    }
  }

  Future<void> _loadSurah(SurahMeta surah) async {
    setState(() {
      _selectedSurah = surah;
      _loading = true;
      _error = null;
      _ayahs = [];
    });

    try {
      final items =
          await ref.read(databaseServiceProvider).fetchSurahAyahs(surah.number);

      if (!mounted) return;
      setState(() {
        _ayahs = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Sure içeriği yüklenemedi. İnternet bağlantını kontrol et.';
      });
    }
  }

  Future<void> _chooseSurah() async {
    final selected = await showDialog<SurahMeta>(
      context: context,
      builder: (dialogContext) {
        return _SurahPickerDialog(surahs: _surahs);
      },
    );

    if (selected != null && mounted) {
      await _loadSurah(selected);
    }
  }

  Future<void> _changeVerseStatus(
    LiveAyahItem ayah,
    HifzVerseStatus? current,
  ) async {
    final HifzVerseStatus? next;
    if (current == null) {
      next = HifzVerseStatus.learning;
    } else if (current == HifzVerseStatus.learning) {
      next = HifzVerseStatus.memorized;
    } else if (current == HifzVerseStatus.memorized) {
      next = HifzVerseStatus.needsReview;
    } else {
      next = null;
    }

    await ref.read(hifzProgressProvider.notifier).setVerseStatus(
          ayah.surahNumber,
          ayah.numberInSurah,
          next,
        );
  }

  Color _statusColor(HifzVerseStatus? status) {
    switch (status) {
      case HifzVerseStatus.learning:
        return const Color(0xFF80D8FF);
      case HifzVerseStatus.memorized:
        return const Color(0xFFFFA21A);
      case HifzVerseStatus.needsReview:
        return const Color(0xFFFFD180);
      case null:
        return Colors.white54;
    }
  }

  String _statusLabel(HifzVerseStatus? status) {
    switch (status) {
      case HifzVerseStatus.learning:
        return 'Çalışılıyor';
      case HifzVerseStatus.memorized:
        return 'Ezberlendi';
      case HifzVerseStatus.needsReview:
        return 'Tekrar gerekli';
      case null:
        return 'Ezbere başla';
    }
  }

  IconData _statusIcon(HifzVerseStatus? status) {
    switch (status) {
      case HifzVerseStatus.learning:
        return Icons.menu_book_rounded;
      case HifzVerseStatus.memorized:
        return Icons.check_circle_rounded;
      case HifzVerseStatus.needsReview:
        return Icons.replay_rounded;
      case null:
        return Icons.add_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(hifzProgressProvider);
    final selected = _selectedSurah;

    final memorizedInSurah =
        selected == null ? 0 : progress.memorizedCountForSurah(selected.number);

    final surahRatio = _ayahs.isEmpty
        ? 0.0
        : (memorizedInSurah / _ayahs.length).clamp(0.0, 1.0);

    final dailyRatio =
        (progress.dailyRevisionCount / progress.dailyTarget).clamp(0.0, 1.0);

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hıfz Akademisi',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ezberle, takip et, düzenli tekrar et.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE082).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFFE082).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Color(0xFFFFE082),
                      size: 25,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GlassContainer(
                borderRadius: 25,
                goldAccentBorder: true,
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ezber yolculuğun',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            value: '${progress.totalMemorized}',
                            label: 'Ezberlenen',
                            icon: Icons.verified_rounded,
                            color: const Color(0xFFFFA21A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatTile(
                            value: '${progress.totalLearning}',
                            label: 'Çalışılan',
                            icon: Icons.menu_book_rounded,
                            color: const Color(0xFF80D8FF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatTile(
                            value: '${progress.totalNeedsReview}',
                            label: 'Tekrar',
                            icon: Icons.replay_rounded,
                            color: const Color(0xFFFFD180),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              GlassContainer(
                borderRadius: 23,
                emeraldGlow: true,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Günlük tekrar hedefi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${progress.dailyRevisionCount}/${progress.dailyTarget}',
                          style: const TextStyle(
                            color: Color(0xFFFFA21A),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: dailyRatio,
                        minHeight: 8,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFA21A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Hedef / gün',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hedefi azalt',
                          visualDensity: VisualDensity.compact,
                          onPressed: progress.dailyTarget > 1
                              ? () => ref
                                  .read(hifzProgressProvider.notifier)
                                  .setDailyTarget(progress.dailyTarget - 1)
                              : null,
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '${progress.dailyTarget}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hedefi artır',
                          visualDensity: VisualDensity.compact,
                          onPressed: progress.dailyTarget < 100
                              ? () => ref
                                  .read(hifzProgressProvider.notifier)
                                  .setDailyTarget(progress.dailyTarget + 1)
                              : null,
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Color(0xFFFFA21A),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => ref
                            .read(hifzProgressProvider.notifier)
                            .recordRevision(),
                        icon: const Icon(Icons.check_rounded, size: 17),
                        label: const Text('Tekrar oturumunu tamamla'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFA21A),
                          side: const BorderSide(
                            color: Color(0x5564FFDA),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Sure seçimi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _chooseSurah,
                    icon: const Icon(Icons.search_rounded, size: 17),
                    label: const Text('Ara'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFFA21A),
                    ),
                  ),
                ],
              ),
              GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(15),
                onTap: _chooseSurah,
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA21A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Color(0xFFFFA21A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected?.nameTurkish ?? 'Sure seç',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            selected == null
                                ? 'Kur’an sureleri'
                                : '${selected.ayahCount} ayet • ${selected.revelationType}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                      size: 25,
                    ),
                  ],
                ),
              ),
              if (selected != null && _ayahs.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$memorizedInSurah / ${_ayahs.length} ayet ezberlendi',
                        style: const TextStyle(
                          color: Color(0xFFFFA21A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _hideTranslation
                          ? 'Meali göster'
                          : 'Ezber kontrolü için meali gizle',
                      onPressed: () {
                        setState(() {
                          _hideTranslation = !_hideTranslation;
                        });
                      },
                      icon: Icon(
                        _hideTranslation
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: const Color(0xFFFFE082),
                      ),
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: surahRatio,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFA21A),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(34),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFA21A),
                    ),
                  ),
                )
              else if (_error != null)
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: selected == null
                            ? _loadCatalog
                            : () => _loadSurah(selected),
                        child: const Text('Yeniden dene'),
                      ),
                    ],
                  ),
                )
              else if (_ayahs.isNotEmpty) ...[
                const Text(
                  'Ayetlerin ezber durumunu değiştirmek için durum düğmesine dokun.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white60,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                for (final ayah in _ayahs)
                  _buildAyahCard(
                    ayah,
                    ref.watch(hifzProgressProvider).statusFor(
                          ayah.surahNumber,
                          ayah.numberInSurah,
                        ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAyahCard(
    LiveAyahItem ayah,
    HifzVerseStatus? status,
  ) {
    final color = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: color.withValues(alpha: status == null ? 0.13 : 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 29,
                height: 29,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.13),
                ),
                child: Text(
                  '${ayah.numberInSurah}',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _changeVerseStatus(ayah, status),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: color.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status), size: 14, color: color),
                      const SizedBox(width: 5),
                      Text(
                        _statusLabel(status),
                        style: TextStyle(
                          color: color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            ayah.arabicText,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 25,
              height: 1.9,
              color: Color(0xFFFFF4D6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          if (_hideTranslation)
            const Text(
              'Meal gizlendi • Ayeti zihninden hatırlamaya çalış.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFD180),
                fontSize: 11,
              ),
            )
          else
            Text(
              ayah.turkishText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahPickerDialog extends StatefulWidget {
  final List<SurahMeta> surahs;

  const _SurahPickerDialog({required this.surahs});

  @override
  State<_SurahPickerDialog> createState() => _SurahPickerDialogState();
}

class _SurahPickerDialogState extends State<_SurahPickerDialog> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final filtered = widget.surahs.where((surah) {
      return surah.nameTurkish.toLowerCase().contains(query) ||
          '${surah.number}'.contains(query);
    }).toList();

    return Dialog(
      backgroundColor: const Color(0xFF0B1C22),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0x4464FFDA)),
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            children: [
              const Text(
                'Sure seçimi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Sure adı veya numarası',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFFFA21A),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final surah = filtered[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 15,
                        backgroundColor:
                            const Color(0xFFFFA21A).withValues(alpha: 0.12),
                        child: Text(
                          '${surah.number}',
                          style: const TextStyle(
                            color: Color(0xFFFFA21A),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        surah.nameTurkish,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${surah.ayahCount} ayet',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(surah),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
