import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/daily_planner_service.dart';
import '../../core/theme/glass_container.dart';

class DailyPlannerScreen extends ConsumerWidget {
  const DailyPlannerScreen({super.key});

  static const Color _mint = Color(0xFFFFA21A);

  String _weekday(int weekday) {
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return days[weekday - 1];
  }

  void _showAddTask(BuildContext context, WidgetRef ref, bool isDark) {
    final controller = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isDark ? const Color(0xFF10251F) : const Color(0xFFF3F8F4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              22,
              20,
              20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yeni görev',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF18372C),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 70,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    if (value.trim().isEmpty) return;
                    ref.read(dailyPlanProvider.notifier).addTask(value);
                    Navigator.pop(sheetContext);
                  },
                  decoration: InputDecoration(
                    hintText: 'Örneğin: Bir sayfa kitap oku',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (controller.text.trim().isEmpty) return;
                      ref
                          .read(dailyPlanProvider.notifier)
                          .addTask(controller.text);
                      Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Görevi ekle'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Kur’an':
        return Icons.menu_book_outlined;
      case 'Hıfz':
        return Icons.auto_stories_outlined;
      case 'Zikir':
        return Icons.fingerprint;
      case 'Tefekkür':
        return Icons.spa_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(dailyPlanProvider);
    final notifier = ref.read(dailyPlanProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : const Color(0xFF18372C);
    final muted = isDark ? Colors.white70 : const Color(0xFF587064);
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HUZUR • GÜNLÜK RİTİM',
                      style: TextStyle(
                        color: _mint,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.7,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Günlük Planım',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_weekday(today.weekday)} • '
                      '${today.day.toString().padLeft(2, '0')}.'
                      '${today.month.toString().padLeft(2, '0')}.'
                      '${today.year}',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Görev ekle',
                onPressed: () => _showAddTask(context, ref, isDark),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (plan.isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  GlassContainer(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(18),
                    gradientColors: isDark
                        ? const [
                            Color(0xE01B4438),
                            Color(0xD00B211D),
                          ]
                        : const [
                            Color(0xFFF0F8F2),
                            Color(0xFFDCEDE2),
                          ],
                    borderColor: isDark
                        ? const Color(0x5564FFDA)
                        : const Color(0x5580A995),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Bugünkü ilerlemen',
                                style: TextStyle(
                                  color: foreground,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              '${(plan.progress * 100).round()}%',
                              style: const TextStyle(
                                color: _mint,
                                fontWeight: FontWeight.w900,
                                fontSize: 21,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: plan.progress,
                            minHeight: 9,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : const Color(0xFFB9D4C5),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(_mint),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.task_alt_rounded,
                              color: _mint,
                              size: 17,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              '${plan.completedCount} / ${plan.tasks.length} görev tamamlandı',
                              style: TextStyle(
                                color: muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Bugünün görevleri',
                          style: TextStyle(
                            color: foreground,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddTask(context, ref, isDark),
                        icon: const Icon(Icons.add, size: 17),
                        label: const Text('Ekle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (plan.tasks.isEmpty)
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Bugün için görev bulunmuyor. Yeni bir görev ekleyebilirsin.',
                        style: TextStyle(color: muted),
                      ),
                    ),
                  for (final task in plan.tasks) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: GlassContainer(
                        borderRadius: 18,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 12,
                        ),
                        onTap: () => notifier.toggleTask(task.id),
                        tintColor: isDark
                            ? const Color(0xFF102D25)
                            : const Color(0xFFEAF3ED),
                        borderColor: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : const Color(0x3380A995),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 29,
                              height: 29,
                              decoration: BoxDecoration(
                                color: task.completed
                                    ? _mint.withValues(alpha: 0.20)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: task.completed
                                      ? _mint
                                      : muted.withValues(alpha: 0.55),
                                  width: 1.4,
                                ),
                              ),
                              child: task.completed
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: _mint,
                                      size: 19,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              _categoryIcon(task.category),
                              color: task.completed ? _mint : muted,
                              size: 19,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          task.completed ? muted : foreground,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      decoration: task.completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    task.category,
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (task.category == 'Kişisel')
                              IconButton(
                                tooltip: 'Görevi sil',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => notifier.removeTask(task.id),
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Planın bu cihazda saklanır. Yeni gün için ayrı bir liste açılır.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
