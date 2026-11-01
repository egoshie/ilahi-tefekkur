import '../../core/services/notification_support_compat.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/huzur_live_support_api.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/glass_container.dart';
import '../../core/theme/liquid_glass_theme.dart';

class HuzurLiveSupportSheet extends ConsumerStatefulWidget {
  const HuzurLiveSupportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HuzurLiveSupportSheet(),
    );
  }

  @override
  ConsumerState<HuzurLiveSupportSheet> createState() =>
      _HuzurLiveSupportSheetState();
}

class _HuzurLiveSupportSheetState extends ConsumerState<HuzurLiveSupportSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _initialMsgController = TextEditingController();
  final TextEditingController _chatInputController = TextEditingController();
  final TextEditingController _ratingCommentController =
      TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  int _selectedStars = 5;

  @override
  void dispose() {
    _nameController.dispose();
    _initialMsgController.dispose();
    _chatInputController.dispose();
    _ratingCommentController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final supportState = ref.watch(huzurLiveSupportProvider);
    final supportNotifier = ref.read(huzurLiveSupportProvider.notifier);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.90,
        minChildSize: 0.68,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, sheetScrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(34)),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xF0041E1B),
                      Color(0xF5030914),
                      Color(0xF802060D),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFF64FFDA).withOpacity(0.45),
                      width: 1.2,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 46,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cam Başlık Kartı (Yalnızca "Huzur Canlı Destek")
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: GlassContainer(
                          borderRadius: 24,
                          emeraldGlow: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              const EgeDenizDeveloperAvatar(size: 42),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Text(
                                          'Huzur Canlı Destek',
                                          style: TextStyle(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        BespokeVectorIcon(
                                          type: BespokeIconType.verifiedSeal,
                                          color: Color(0xFF64FFDA),
                                          size: 15,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF64FFDA),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            supportState.shortCode != null &&
                                                    supportState
                                                        .shortCode!.isNotEmpty
                                                ? 'Ege Deniz • Oturum #${supportState.shortCode}'
                                                : 'Ege Deniz • Doğrudan Geliştirici Hattı',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white
                                                  .withOpacity(0.75),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (supportState.hasActiveSession)
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    supportNotifier.closeSessionForRating();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE082)
                                          .withOpacity(0.16),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFFFE082)
                                            .withOpacity(0.65),
                                      ),
                                    ),
                                    child: const Text(
                                      'Bitir',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFFE082),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const BespokeVectorIcon(
                                      type: BespokeIconType.closeCross,
                                      color: Colors.white70,
                                      size: 15,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (supportState.isPushPermissionDenied)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                          child: GlassContainer(
                            borderRadius: 16,
                            goldAccentBorder: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            onTap: () async {
                              await NotificationAndWidgetService.instance
                                  .openSystemNotificationSettings();
                              await supportNotifier
                                  .refreshPushPermissionStatus();
                            },
                            child: Row(
                              children: [
                                const BespokeVectorIcon(
                                  type: BespokeIconType.shieldCheck,
                                  color: Color(0xFFFFE082),
                                  size: 16,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Ege size yazdığında anında bildirim almak için Ayarlar üzerinden bildirim iznini etkinleştirin.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.white.withOpacity(0.88),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Ayarlar',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64FFDA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // İçerik Alanı
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          child: supportState.isClosedForRating
                              ? _buildGlassRatingView(
                                  context,
                                  supportState,
                                  supportNotifier,
                                  sheetScrollController,
                                )
                              : supportState.hasActiveSession
                                  ? _buildGlassActiveChatView(
                                      context,
                                      supportState,
                                      supportNotifier,
                                    )
                                  : _buildGlassConsentStartView(
                                      context,
                                      supportState,
                                      supportNotifier,
                                      sheetScrollController,
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassConsentStartView(
    BuildContext context,
    SupportSessionState state,
    HuzurLiveSupportNotifier notifier,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      children: [
        GlassContainer(
          borderRadius: 26,
          goldAccentBorder: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  BespokeVectorIcon(
                    type: BespokeIconType.supportChat,
                    color: Color(0xFFFFE082),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Yeni Destek Görüşmesi Başlat',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFE082),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Uygulama ile ilgili soru, öneri veya geri bildirimlerinizi doğrudan geliştirici Ege Deniz ile paylaşabilirsiniz.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: Colors.white.withOpacity(0.78),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Adınız',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64FFDA),
                ),
              ),
              const SizedBox(height: 6),
              GlassContainer(
                borderRadius: 16,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Örn: Deniz',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Mesajınız',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64FFDA),
                ),
              ),
              const SizedBox(height: 6),
              GlassContainer(
                borderRadius: 16,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: TextField(
                  controller: _initialMsgController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Size nasıl yardımcı olabiliriz?',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Zorunlu Gizlilik Onayı (Başlangıçta İşaretsiz)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.setPrivacyConsent(!state.privacyConsentGiven);
                },
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: state.privacyConsentGiven
                        ? const Color(0xFF64FFDA).withOpacity(0.12)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: state.privacyConsentGiven
                          ? const Color(0xFF64FFDA)
                          : Colors.white24,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: state.privacyConsentGiven
                              ? const Color(0xFF64FFDA)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: state.privacyConsentGiven
                                ? const Color(0xFF64FFDA)
                                : Colors.white54,
                            width: 1.4,
                          ),
                        ),
                        child: state.privacyConsentGiven
                            ? const Center(
                                child: BespokeVectorIcon(
                                  type: BespokeIconType.checkBadge,
                                  color: Color(0xFF030914),
                                  size: 15,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Canlı destek kapsamında paylaştığım ad ve mesaj verilerimin yalnızca destek talebimin yanıtlanması amacıyla işlenmesini ve gizlilik aydınlatma metnini okuduğumu onaylıyorum.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Colors.white.withOpacity(0.88),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A80).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF8A80).withOpacity(0.55),
                    ),
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFE082),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),
              GlassContainer(
                borderRadius: 18,
                emeraldGlow: state.privacyConsentGiven,
                goldAccentBorder: state.privacyConsentGiven,
                padding: const EdgeInsets.symmetric(vertical: 14),
                onTap: () async {
                  if (state.isLoading) return;
                  HapticFeedback.mediumImpact();
                  final ok = await notifier.startSession(
                    fullName: _nameController.text,
                    privacyConsent: state.privacyConsentGiven,
                    initialMessage: _initialMsgController.text,
                  );
                  if (ok) {
                    _scrollToBottom();
                  }
                },
                child: Center(
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF64FFDA),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BespokeVectorIcon(
                              type: BespokeIconType.shieldCheck,
                              color: state.privacyConsentGiven
                                  ? const Color(0xFF64FFDA)
                                  : Colors.white54,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Görüşmeyi Başlat',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: state.privacyConsentGiven
                                    ? const Color(0xFFFFE082)
                                    : Colors.white54,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassActiveChatView(
    BuildContext context,
    SupportSessionState state,
    HuzurLiveSupportNotifier notifier,
  ) {
    final timeFmt = DateFormat('HH:mm');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFF64FFDA).withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF64FFDA).withOpacity(0.32),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    BespokeVectorIcon(
                      type: BespokeIconType.shieldCheck,
                      color: Color(0xFF64FFDA),
                      size: 15,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Canlı Destek Oturumu Aktif',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64FFDA),
                      ),
                    ),
                  ],
                ),
                if (state.shortCode != null && state.shortCode!.isNotEmpty)
                  Text(
                    'Kod: ${state.shortCode}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFE082),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            controller: _chatScrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            itemCount: state.messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final msg = state.messages[index];
              final isDev = msg.isFromDeveloper;

              if (isDev) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: EgeDenizDeveloperAvatar(size: 36),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: GlassContainer(
                        borderRadius: 20,
                        emeraldGlow: true,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Ege Deniz',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFFFE082),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const BespokeVectorIcon(
                                  type: BespokeIconType.verifiedSeal,
                                  color: Color(0xFF64FFDA),
                                  size: 13,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  timeFmt.format(msg.createdAt),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.white.withOpacity(0.55),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              msg.text,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.42,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.76,
                  ),
                  child: GlassContainer(
                    borderRadius: 20,
                    goldAccentBorder: true,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              msg.senderName,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64FFDA),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeFmt.format(msg.createdAt),
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.white.withOpacity(0.55),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          msg.text,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.42,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
          child: GlassContainer(
            borderRadius: 22,
            emeraldGlow: true,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatInputController,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(notifier),
                    decoration: const InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _handleSend(notifier),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF64FFDA),
                          Color(0xFF00BFA5),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF64FFDA).withOpacity(0.35),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const BespokeVectorIcon(
                      type: BespokeIconType.sendPlane,
                      color: Color(0xFF030914),
                      size: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSend(HuzurLiveSupportNotifier notifier) async {
    final txt = _chatInputController.text.trim();
    if (txt.isEmpty) return;
    HapticFeedback.lightImpact();
    _chatInputController.clear();
    await notifier.sendMessage(txt);
    _scrollToBottom();
  }

  Widget _buildGlassRatingView(
    BuildContext context,
    SupportSessionState state,
    HuzurLiveSupportNotifier notifier,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        GlassContainer(
          borderRadius: 28,
          goldAccentBorder: true,
          emeraldGlow: true,
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const EgeDenizDeveloperAvatar(size: 56),
              const SizedBox(height: 14),
              const Text(
                'Görüşmeyi Değerlendirin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFE082),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ege Deniz ile gerçekleştirdiğiniz canlı destek görüşmesinden memnun kaldınız mı?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Colors.white.withOpacity(0.78),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(5, (index) {
                  final starNum = index + 1;
                  final isSelected = starNum <= _selectedStars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedStars = starNum);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFFFFE082).withOpacity(0.18)
                              : Colors.white.withOpacity(0.05),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFFE082)
                                : Colors.white24,
                            width: 1.1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFFE082)
                                        .withOpacity(0.28),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                        child: BespokeVectorIcon(
                          type: isSelected
                              ? BespokeIconType.starFilled
                              : BespokeIconType.starOutline,
                          color: isSelected
                              ? const Color(0xFFFFE082)
                              : Colors.white38,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              GlassContainer(
                borderRadius: 18,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _ratingCommentController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13.5, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Görüş ve önerilerinizi buraya yazabilirsiniz...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 12.5),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              GlassContainer(
                borderRadius: 18,
                goldAccentBorder: true,
                emeraldGlow: true,
                padding: const EdgeInsets.symmetric(vertical: 14),
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  await notifier.submitRating(
                    stars: _selectedStars,
                    comment: _ratingCommentController.text,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BespokeVectorIcon(
                        type: BespokeIconType.checkBadge,
                        color: Color(0xFF64FFDA),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Değerlendirmeyi Gönder',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFFE082),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EgeDenizDeveloperAvatar extends StatelessWidget {
  final double size;

  const EgeDenizDeveloperAvatar({
    super.key,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0E3A34),
            Color(0xFF061B24),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFFE082).withOpacity(0.75),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64FFDA).withOpacity(0.22),
            blurRadius: 10,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'ED',
            style: TextStyle(
              fontSize: size * 0.34,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: const Color(0xFFFFE082),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: const Color(0xFF64FFDA),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF030914),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
