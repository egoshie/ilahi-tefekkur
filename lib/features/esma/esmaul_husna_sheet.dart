import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/v42_models.dart';
import '../../core/services/offline_sacred_repository.dart';
import '../../core/services/tasbih_session_service.dart';
import '../../core/theme/glass_container.dart';
import '../../core/theme/liquid_glass_theme.dart';
import '../../core/theme/story_share_sheet.dart';

class EsmaulHusnaSheet extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToTasbih;

  const EsmaulHusnaSheet({
    super.key,
    this.onNavigateToTasbih,
  });

  static Future< void > show(
    BuildContext context, {
    VoidCallback? onNavigateToTasbih,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EsmaulHusnaSheet(
        onNavigateToTasbih: onNavigateToTasbih,
      ),
    );
  }

  @override
  ConsumerState< EsmaulHusnaSheet > createState() => _EsmaulHusnaSheetState();
}

class _EsmaulHusnaSheetState extends ConsumerState< EsmaulHusnaSheet > {
  String _searchQuery = '';

  List< EsmaulHusnaItem > get _filteredEsmas {
    const List< EsmaulHusnaItem > all =
        OfflineSacredRepository.kAll99EsmaulHusna;
    if (_searchQuery.trim().isEmpty) return all;

    return all.where((item) {
      final combined =
          '${item.id} ${item.transliteration} ${item.turkishMeaning} ${item.reference}';
      return TurkishSearchNormalizer.matches(combined, _searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredEsmas;

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.65,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return GlassContainer(
          borderRadius: 34,
          enableBlur: true,
          blurSigma: 26,
          emeraldGlow: true,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "99 Esmaül Hüsna",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "İlahi isimler, anlamları, kaynakları ve zikir hedefleri",
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64FFDA).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${list.length} İsim",
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64FFDA),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: Row(
                  children: [
                    const BespokeVectorIcon(
                      type: BespokeIconType.searchLens,
                      color: Color(0xFF64FFDA),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(fontSize: 13.5),
                        decoration: const InputDecoration(
                          hintText: "Esma adı, anlamı veya numara ara...",
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: 12.5,
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final esma = list[index];
                    return GlassContainer(
                      borderRadius: 22,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "${esma.id}. ${esma.transliteration}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFFFE082),
                                  ),
                                ),
                              ),
                              Text(
                                esma.arabic,
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64FFDA),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            esma.turkishMeaning,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.42,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Zikir Adedi: ${esma.dhikrCount} • Kaynak: ${esma.reference}",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.65),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GlassContainer(
                                  borderRadius: 14,
                                  emeraldGlow: true,
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  onTap: () async {
                                    HapticFeedback.mediumImpact();
                                    await ref
                                        .read(tasbihSessionProvider.notifier)
                                        .startEsmaTarget(esma);
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                    widget.onNavigateToTasbih?.call();
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      BespokeVectorIcon(
                                        type: BespokeIconType.tasbihRipple,
                                        color: Color(0xFF64FFDA),
                                        size: 15,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        "Zikre Başla",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF64FFDA),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GlassContainer(
                                  borderRadius: 14,
                                  goldAccentBorder: true,
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  onTap: () {
                                    HuzurStoryShareSheet.show(
                                      context,
                                      arabic: esma.arabic,
                                      turkish:
                                          "${esma.transliteration}: ${esma.turkishMeaning}",
                                      reference:
                                          "Esmaül Hüsna #${esma.id} (${esma.reference})",
                                      category: "Esmaül Hüsna",
                                    );
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      BespokeVectorIcon(
                                        type: BespokeIconType.instagramStory,
                                        color: Color(0xFFFFE082),
                                        size: 15,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        "Hikâye Paylaş",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFFFE082),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
