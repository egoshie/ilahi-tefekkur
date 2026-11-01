import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/glass_container.dart';
import 'huzur_live_support_api.dart';

Future<void> showHuzurInAppLiveChatModal(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _HuzurLiveSupportSheet(),
  );
}

class HuzurLiveSupportButton extends StatelessWidget {
  const HuzurLiveSupportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 22,
      enableBlur: true,
      blurSigma: 24,
      emeraldGlow: true,
      goldAccentBorder: true,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
      onTap: () => showHuzurInAppLiveChatModal(context),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: Color(0x223F9D7B),
            child: Icon(Icons.support_agent_rounded, color: Color(0xFF9CE5C9)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Geliştirici ile sohbet etmek istiyorum',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Sorunu veya önerini doğrudan ilet',
                  style: TextStyle(color: Color(0xFFB8CEC7), fontSize: 11.5),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              color: Color(0xFFFFE082), size: 15),
        ],
      ),
    );
  }
}

class _HuzurLiveSupportSheet extends StatefulWidget {
  const _HuzurLiveSupportSheet();

  @override
  State<_HuzurLiveSupportSheet> createState() => _HuzurLiveSupportSheetState();
}

class _HuzurLiveSupportSheetState extends State<_HuzurLiveSupportSheet> {
  bool _showDeveloperConnectForm = false;
  bool _privacyConsentAccepted = false;
  static const String _privacyPolicyVersion = 'v1.0';
  bool _isHuzurAiTyping = false;
  int _huzurAiReqToken = 0;

    final List<Map<String, String>> _huzurAiThread = <Map<String, String>>[];

  Widget _buildHuzurAiOptionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isConnect = label == HuzurAiGuideData.optConnectDeveloper;
    return GlassContainer(
      borderRadius: 14,
      blurSigma: 18,
      goldAccentBorder: isConnect,
      emeraldGlow: isConnect,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15.5,
            color: isConnect ? const Color(0xFF9CE5C9) : const Color(0xFFFFE082),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: isConnect ? const Color(0xFFFFE082) : Colors.white,
                fontSize: 12.3,
                fontWeight: isConnect ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHuzurAiThreadItem(Map<String, String> item) {
    final q = item['question'] ?? '';
    final a = item['answer'] ?? '';
    final isTyping = item['status'] == 'typing';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GlassContainer(
              borderRadius: 14,
              blurSigma: 16,
              goldAccentBorder: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                q,
                style: const TextStyle(
                  color: Color(0xFFFFE082),
                  fontSize: 12.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (isTyping)
            const Align(
              alignment: Alignment.centerLeft,
              child: HuzurAiTypingBubble(),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: HuzurAiCrescentAvatar(size: 28),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GlassContainer(
                    borderRadius: 14,
                    blurSigma: 18,
                    emeraldGlow: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(
                      a,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12.4,
                        height: 1.48,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHuzurAiSection() {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      borderRadius: 22,
      blurSigma: 24,
      emeraldGlow: true,
      goldAccentBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HuzurAiCrescentAvatar(size: 40),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          HuzurAiGuideData.title,
                          style: TextStyle(
                            color: Color(0xFFFFE082),
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9CE5C9).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Rehber',
                            style: TextStyle(
                              color: Color(0xFF9CE5C9),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      HuzurAiGuideData.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          GlassContainer(
            borderRadius: 16,
            blurSigma: 18,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Text(
              HuzurAiGuideData.welcomeMessage,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 12.8,
                height: 1.48,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHuzurAiOptionChip(
                icon: Icons.self_improvement_rounded,
                label: HuzurAiGuideData.optWhatIsHuzur,
                onTap: () => _onSelectHuzurAiPrompt(
                  HuzurAiGuideData.optWhatIsHuzur,
                  HuzurAiGuideData.ansWhatIsHuzur,
                ),
              ),
              _buildHuzurAiOptionChip(
                icon: Icons.auto_awesome_rounded,
                label: HuzurAiGuideData.optWhatDoesHuzurOffer,
                onTap: () => _onSelectHuzurAiPrompt(
                  HuzurAiGuideData.optWhatDoesHuzurOffer,
                  HuzurAiGuideData.ansWhatDoesHuzurOffer,
                ),
              ),
              _buildHuzurAiOptionChip(
                icon: Icons.support_agent_rounded,
                label: HuzurAiGuideData.optConnectDeveloper,
                onTap: () {
                  setState(() {
                    _showDeveloperConnectForm = true;
                  });
                },
              ),
            ],
          ),
          if (_huzurAiThread.isNotEmpty) ...[
            const SizedBox(height: 10),
            ..._huzurAiThread.map(_buildHuzurAiThreadItem),
          ] else if (_isHuzurAiTyping) ...[
            const SizedBox(height: 8),
            const HuzurAiTypingBubble(),
          ],
        ],
      ),
    );
  }

  Future<void> _onSelectHuzurAiPrompt(String question, String answer) async {
    final int token = ++_huzurAiReqToken;
    setState(() {
      // Aynı soru tekrar seçilirse listeyi şişirmemek için önceki cevabı yenile
      _huzurAiThread.removeWhere((item) => item['question'] == question);
      _huzurAiThread.add({
        'question': question,
        'answer': '',
        'status': 'typing',
      });
      _isHuzurAiTyping = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || token != _huzurAiReqToken) return;

    setState(() {
      final idx = _huzurAiThread.indexWhere((item) => item['question'] == question);
      if (idx != -1) {
        _huzurAiThread[idx] = {
          'question': question,
          'answer': answer,
          'status': 'done',
        };
      }
      _isHuzurAiTyping = false;
    });
  }

  final _api = HuzurLiveSupportApi();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _reviewController = TextEditingController();

  Timer? _pollTimer;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  String? _sessionId;
  HuzurSupportSessionSnapshot? _snapshot;

  bool _starting = false;
  bool _sending = false;
  bool _reviewSending = false;
  bool _reviewSubmitted = false;
  bool _polling = false;
  int _stars = 5;

  static const _background = Color(0xFF08120F);
  static const _surface = Color(0xFF12221D);
  static const _accent = Color(0xFF9CE5C9);

  @override
  void dispose() {
    _pollTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _reviewController.dispose();

    unawaited(_tokenSubscription?.cancel());
    unawaited(_foregroundSubscription?.cancel());
    unawaited(_openedSubscription?.cancel());
    unawaited(_api.dispose());

    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: const Color(0xFF8B3434),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_restoreSession());
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString("huzur_live_support_session_id");
      if (!mounted || id == null || id.isEmpty) return;

      setState(() => _sessionId = id);

      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _refreshSession(),
      );

      await _refreshSession();
      await _initializePushNotifications();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _startSession() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _starting = true);

    try {
      final result = await _api.createSession(
        name: _nameController.text,
        email: _emailController.text,
      );

      if (!mounted) return;

      setState(() {
        _sessionId = result.sessionId;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        "huzur_live_support_session_id",
        result.sessionId,
      );

      _pollTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _refreshSession(),
      );

      await _refreshSession();
      await _initializePushNotifications();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _refreshSession() async {
    final id = _sessionId;

    if (id == null || _polling) return;

    _polling = true;

    try {
      final result = await _api.getSession(id);

      if (!mounted) return;

      setState(() => _snapshot = result);

      if (result.closed) {
        _pollTimer?.cancel();
      }

      final unreadIds = result.messages
          .where((message) => message.isFromDeveloper && !message.isRead)
          .map((message) => message.id)
          .where((id) => id.isNotEmpty)
          .toList();

      if (unreadIds.isNotEmpty) {
        try {
          await _api.markMessagesRead(
            sessionId: id,
            messageIds: unreadIds,
          );
        } catch (error) {
          debugPrint('Huzur read receipt: $error');
        }
      }
    } catch (error) {
      debugPrint('Huzur live support poll: $error');
    } finally {
      _polling = false;
    }
  }

  Future<void> _initializePushNotifications() async {
    final id = _sessionId;
    if (id == null) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = FirebaseMessaging.instance;

      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Huzur notifications: permission denied.');
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken;

        for (var attempt = 0; attempt < 10; attempt++) {
          apnsToken = await messaging.getAPNSToken();

          if (apnsToken != null) break;

          await Future.delayed(
            const Duration(milliseconds: 500),
          );
        }

        if (apnsToken == null) {
          debugPrint('Huzur notifications: APNs token unavailable.');
          return;
        }
      }

      final token = await messaging.getToken();

      if (token != null) {
        await _api.registerDeviceToken(
          sessionId: id,
          token: token,
        );
      }

      _tokenSubscription = messaging.onTokenRefresh.listen((newToken) async {
        try {
          await _api.registerDeviceToken(
            sessionId: id,
            token: newToken,
          );
        } catch (error) {
          debugPrint('Huzur token refresh: $error');
        }
      });

      _foregroundSubscription = FirebaseMessaging.onMessage.listen((_) {
        _refreshSession();
      });

      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((_) {
        _refreshSession();
      });

      final initialMessage = await messaging.getInitialMessage();

      if (initialMessage != null) {
        await _refreshSession();
      }
    } catch (error) {
      // Firebase kurulmamış olsa da canlı mesajlaşma çalışabilir.
      debugPrint('Huzur push setup: $error');
    }
  }

  Future<void> _sendMessage() async {
    final id = _sessionId;
    final text = _messageController.text.trim();

    if (id == null || text.isEmpty || _sending) return;

    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    } catch (_) {}
    setState(() => _sending = true);

    try {
      await _api.sendMessage(
        sessionId: id,
        text: text,
      );

      _messageController.clear();
      await _refreshSession();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submitReview() async {
    final id = _sessionId;

    if (id == null || _reviewSending || _reviewSubmitted) return;

    setState(() => _reviewSending = true);

    try {
      await _api.submitReview(
        sessionId: id,
        stars: _stars,
        review: _reviewController.text,
      );

      if (!mounted) return;

      setState(() => _reviewSubmitted = true);
      await _api.clearSavedSession();
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _reviewSending = false);
    }
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 12, 15),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1C4236),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: _accent,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Huzur Canlı Destek • Liquid Glass',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Geliştirici ile doğrudan görüşme',
                  style: TextStyle(
                    color: Color(0xFF9FB5AA),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

    Widget _entryView() {
    if (!_showDeveloperConnectForm) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHuzurAiSection(),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EgeDenizDeveloperHeaderBadge(),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassContainer(
                borderRadius: 12,
                blurSigma: 14,
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                onTap: () => setState(() => _showDeveloperConnectForm = false),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: Color(0xFFFFE082)),
                    SizedBox(width: 6),
                    Text(
                      'Huzur AI Rehberine Dön',
                      style: TextStyle(
                        color: Color(0xFFFFE082),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _entryFormContent(),
        ],
      ),
    );
  }

  Widget _entryFormContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 25, 22, 30),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 43,
              color: _accent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sizinle nasıl iletişim kuralım?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Görüşme talebinizi oluşturmak için adınızı ve e-posta adresinizi girin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFB3C3BC),
                height: 1.5,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 25),
            _inputField(
              controller: _nameController,
              label: 'Adınız',
              icon: Icons.person_outline,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Adınızı girin.'
                  : null,
            ),
            const SizedBox(height: 13),
            _inputField(
              controller: _emailController,
              label: 'E-posta adresiniz',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';

                return RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                ).hasMatch(email)
                    ? null
                    : 'Geçerli bir e-posta girin.';
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'Adınız, e-posta adresiniz ve görüşme mesajlarınız destek hizmeti için işlenir.',
              style: TextStyle(
                color: Color(0xFF91A79D),
                fontSize: 11,
                height: 1.5,
              ),
            ),
                      const SizedBox(height: 12),
          GlassContainer(
            borderRadius: 16,
            blurSigma: 18,
            goldAccentBorder: _privacyConsentAccepted,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            onTap: () => setState(() => _privacyConsentAccepted = !_privacyConsentAccepted),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _privacyConsentAccepted,
                    activeColor: const Color(0xFFD4AF37),
                    checkColor: const Color(0xFF04100C),
                    side: BorderSide(
                      color: const Color(0xFFFFE082).withValues(alpha: 0.75),
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onChanged: (val) {
                      setState(() => _privacyConsentAccepted = val ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ad ve e-posta bilgilerimin yalnızca canlı destek iletişimi kapsamında işlenmesini ve gizlilik aydınlatma metnini (v1.0) okuduğumu, onayladığımı beyan ederim.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 11.8,
                      height: 1.42,
                    ),
                  ),
                ),
              ],
            ),
          ),
const SizedBox(height: 22),
            FilledButton(
              onPressed: _starting ? null : _startSession,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF397B63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _starting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Görüşme talebi oluştur'),
            ),
          ],
        ),
      ),
    );
  }

      Widget _inputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    ValueChanged<String>? onFieldSubmitted,
    int maxLines = 1,
  }) {
    return GlassContainer(
      borderRadius: 18,
      blurSigma: 22,
      emeraldGlow: true,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        maxLines: maxLines,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: const Color(0xFFFFE082),
        decoration: InputDecoration(
          icon: icon != null
              ? Icon(icon, color: const Color(0xFF9CE5C9), size: 19)
              : null,
          labelText: label,
          labelStyle: TextStyle(
            color: const Color(0xFFFFE082).withValues(alpha: 0.88),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.38),
            fontSize: 12.5,
          ),
          errorStyle: const TextStyle(
            color: Color(0xFFFFB4AB),
            fontSize: 11.2,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _conversationView() {
    final snapshot = _snapshot;
    final waiting = snapshot?.status == 'waiting';
    final position = snapshot?.queuePosition ?? 0;

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF16372D),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                waiting ? Icons.schedule_rounded : Icons.check_circle_outline,
                color: _accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  waiting
                      ? 'Şu an sıradasınız. Sıranız: $position'
                      : 'Görüşmeniz başladı. Mesajınızı yazabilirsiniz.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: snapshot == null || snapshot.messages.isEmpty
              ? const Center(
                  child: Text(
                    'Mesajlarınız burada görünecek.',
                    style: TextStyle(color: Colors.white60),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  itemCount: snapshot.messages.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.messages[index];
                    final mine = !message.isFromDeveloper;

                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
                        decoration: BoxDecoration(
                          color: mine
                              ? const Color(0xFF245B48)
                              : const Color(0xFF1B2923),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                message.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  TimeOfDay.fromDateTime(
                                    message.createdAt.toLocal(),
                                  ).format(context),
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                ),
                                if (mine) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.done_all_rounded,
                                    size: 14,
                                    color: message.isRead
                                        ? _accent
                                        : Colors.white60,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (snapshot?.developerTyping == true)
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Geliştirici yazıyor...',
                style: TextStyle(
                  color: _accent,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: _surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF397B63),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                  ),
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviewView() {
    if (_reviewSubmitted) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: _accent,
                size: 54,
              ),
              SizedBox(height: 15),
              Text(
                'Değerlendirmeniz alındı.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Huzur canlı desteği kullandığınız için teşekkür ederiz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.rate_review_outlined,
            color: _accent,
            size: 44,
          ),
          const SizedBox(height: 17),
          const Text(
            'Görüşmemiz nasıldı?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Deneyiminizi yıldız vererek ve yorum yazarak değerlendirebilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 23),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: () => setState(() => _stars = index + 1),
                icon: Icon(
                  index < _stars
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xFFFFC95C),
                  size: 35,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _reviewController,
            minLines: 3,
            maxLines: 5,
            maxLength: 2000,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Görüşünüzü yazın (isteğe bağlı)...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: _surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _reviewSending ? null : _submitReview,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF397B63),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: _reviewSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Değerlendirmeyi gönder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: FractionallySizedBox(
        heightFactor: keyboardInset > 0 ? 1.0 : 0.92,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF103528).withValues(alpha: 0.82),
                    const Color(0xFF071913).withValues(alpha: 0.90),
                    const Color(0xFF030A07).withValues(alpha: 0.95),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                    top: BorderSide(
                        color:
                            const Color(0xFFFFE082).withValues(alpha: 0.34))),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    _header(),
                    Expanded(
                      child: _sessionId == null
                          ? _entryView()
                          : _snapshot?.closed == true
                              ? _reviewView()
                              : _conversationView(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HUZUR AI — CUSTOM PAINTER HİLAL AVATARI & TYPING INDICATOR (ADIM 4A)
// ============================================================================

class HuzurAiCrescentAvatar extends StatelessWidget {
  final double size;
  const HuzurAiCrescentAvatar({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.25, -0.3),
          radius: 0.95,
          colors: [
            Color(0xFF174636),
            Color(0xFF0A221A),
            Color(0xFF05110D),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.65),
          width: 1.25,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
            blurRadius: 10,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _HuzurCrescentPainter(),
      ),
    );
  }
}

class _HuzurCrescentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.30;

    // Altın hilal (Path.combine ile iki dairenin farkı)
    final outerCircle = Path()
      ..addOval(Rect.fromCircle(center: center.translate(-size.width * 0.02, 0), radius: outerRadius));
    final innerCutout = Path()
      ..addOval(Rect.fromCircle(
        center: center.translate(outerRadius * 0.38, -outerRadius * 0.16),
        radius: outerRadius * 0.82,
      ));

    final crescentPath = Path.combine(PathOperation.difference, outerCircle, innerCutout);

    final goldPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF3B0),
          Color(0xFFD4AF37),
          Color(0xFFAA8220),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    canvas.drawPath(crescentPath, goldPaint);

    // Hilalin sağ üst iç boşluğuna zarif 4 köşeli ışıltı yıldızı
    final starCenter = center.translate(outerRadius * 0.42, -outerRadius * 0.22);
    final starRadius = size.width * 0.095;
    final starPath = Path();
    for (int i = 0; i < 8; i++) {
      final r = i.isEven ? starRadius : starRadius * 0.36;
      final angle = (i * math.pi / 4) - (math.pi / 2);
      final pt = Offset(
        starCenter.dx + r * math.cos(angle),
        starCenter.dy + r * math.sin(angle),
      );
      if (i == 0) {
        starPath.moveTo(pt.dx, pt.dy);
      } else {
        starPath.lineTo(pt.dx, pt.dy);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HuzurAiTypingBubble extends StatefulWidget {
  const HuzurAiTypingBubble({super.key});

  @override
  State<HuzurAiTypingBubble> createState() => _HuzurAiTypingBubbleState();
}

class _HuzurAiTypingBubbleState extends State<HuzurAiTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const HuzurAiCrescentAvatar(size: 32),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2920).withValues(alpha: 0.92),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final phase = (_controller.value * 2 * math.pi) - (index * 0.9);
                    final dy = -3.0 * ((math.sin(phase) + 1) / 2);
                    final opacity = 0.40 + 0.60 * ((math.sin(phase) + 1) / 2);
                    return Padding(
                      padding: EdgeInsets.only(right: index < 2 ? 5 : 0),
                      child: Transform.translate(
                        offset: Offset(0, dy),
                        child: Opacity(
                          opacity: opacity.clamp(0.25, 1.0),
                          child: Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD4AF37),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HuzurAiGuideData {
  static const String title = 'Huzur AI';
  static const String subtitle = 'Uygulama Rehberi • Otomatik Tanıtım';

  static const String welcomeMessage =
      'Selamünaleyküm, Huzur rehberine hoş geldiniz. '
      'Aşağıdaki seçeneklerden Huzur uygulamasının gerçek özelliklerini inceleyebilir '
      'veya doğrudan Huzur Geliştiricisi Ege Deniz ile canlı sohbete bağlanabilirsiniz.';

  static const String optWhatIsHuzur = 'Huzur nedir?';
  static const String optWhatDoesHuzurOffer = 'Huzur bizlere neler sunuyor?';
  static const String optConnectDeveloper = 'Geliştiriciyle sohbet etmek istiyorum.';

  static const String ansWhatIsHuzur =
      'Huzur; ibadet, tefekkür ve günlük manevi alışkanlıkları tek bir sade deneyimde '
      'buluşturan bir yaşam ve ibadet ekosistemidir. Gün içinde kendine ayırdığın zamanı '
      'daha düzenli, dingin ve anlamlı kılmana eşlik eder.';

  static const String ansWhatDoesHuzurOffer =
      'Huzur uygulaması içerisinde yer alan gerçek modüller şunlardır:\n'
      '• Namaz Vakitleri ve Vakit Atmosferi: Konuma dayalı vakit hesaplaması, ezan bildirimleri ve vakte uyumlu görsel atmosfer.\n'
      '• Kur’an ve Kutsal Metinlerde Arama: Ayetler, ilahi metinler ve tefekkür notları arasında hızlı okuma ve arama.\n'
      '• Esmaül Hüsna ve Zikir Takibi: Kişisel zikir sayacı, Esmaül Hüsna rehberi ve günlük manevi takip.\n'
      '• Huzur Sesleri (Atmosfer): Ney, yağmur, su ve rüzgar sesleriyle tefekkür ve odaklanma arka planı.\n'
      '• Kıble Pusulası ve Hicri Takvim: Sensör destekli kıble yönü bulucu ve Hicri takvim dönüşümü.';
}

// ============================================================================
// HUZUR LIQUID GLASS — COMPACT iOS EMERALD, BLACK & GOLD DESIGN (ADIM 5)
// ============================================================================

class HuzurLiquidGlassTheme {
  static const Color deepBlack = Color(0xFF040B08);
  static const Color darkEmerald = Color(0xFF0B241C);
  static const Color midEmerald = Color(0xFF12382B);
  static const Color softEmerald = Color(0xFF9CE5C9);
  static const Color royalGold = Color(0xFFD4AF37);
  static const Color lightGold = Color(0xFFFFE082);
}

class HuzurLiquidGlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? borderColor;

  const HuzurLiquidGlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.borderRadius = 20,
    this.blurSigma = 18,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: HuzurLiquidGlassTheme.royalGold.withValues(alpha: 0.06),
            blurRadius: 12,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  HuzurLiquidGlassTheme.midEmerald.withValues(alpha: 0.78),
                  HuzurLiquidGlassTheme.darkEmerald.withValues(alpha: 0.88),
                  HuzurLiquidGlassTheme.deepBlack.withValues(alpha: 0.94),
                ],
              ),
              border: Border.all(
                color: borderColor ??
                    HuzurLiquidGlassTheme.royalGold.withValues(alpha: 0.34),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EGE DENİZ — HUZUR GELİŞTİRİCİSİ SVG/CUSTOMPAINTER AVATARI & DOĞRULAMA (ADIM 6)
// ============================================================================

class EgeDenizDeveloperProfile {
  static const String fullName = 'Ege Deniz';
  static const String title = 'Huzur Geliştiricisi';
  static const String connectLabel = 'Ege Deniz ile Canlı Sohbete Bağlan';
  static const String privacyNotice =
      'Ad ve e-posta bilgilerimin yalnızca canlı destek iletişimi kapsamında işlenmesini ve gizlilik koşullarını onaylıyorum.';
}

class EgeDenizDeveloperAvatar extends StatelessWidget {
  final double size;
  final bool showVerifiedBadge;

  const EgeDenizDeveloperAvatar({
    super.key,
    this.size = 40,
    this.showVerifiedBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF164A39),
                  Color(0xFF0A241C),
                  Color(0xFF05110D),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.78),
                width: 1.35,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9CE5C9).withValues(alpha: 0.16),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _EgeDenizSvgAvatarPainter(),
            ),
          ),
          if (showVerifiedBadge)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: size * 0.36,
                height: size * 0.36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF071A14),
                  border: Border.all(
                    color: const Color(0xFFD4AF37),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  Icons.verified_rounded,
                  size: size * 0.26,
                  color: const Color(0xFF9CE5C9),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EgeDenizSvgAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Sekizgen geometrik çerçeve (SVG tarzı ince altın çizgi)
    final hexPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.032
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.35);

    final hexPath = Path();
    final r = w * 0.38;
    for (int i = 0; i < 6; i++) {
      final a = (i * math.pi / 3) - (math.pi / 2);
      final pt = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      if (i == 0) {
        hexPath.moveTo(pt.dx, pt.dy);
      } else {
        hexPath.lineTo(pt.dx, pt.dy);
      }
    }
    hexPath.close();
    canvas.drawPath(hexPath, hexPaint);

    // 2. Geliştirici sembolü: Sol '<', Sağ '>' ve ortada altın '/' vektörleri
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * 0.068
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF3B0),
          Color(0xFFD4AF37),
          Color(0xFF9CE5C9),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r));

    // Sol '<'
    final leftBracket = Path()
      ..moveTo(w * 0.37, h * 0.37)
      ..lineTo(w * 0.25, h * 0.50)
      ..lineTo(w * 0.37, h * 0.63);
    canvas.drawPath(leftBracket, strokePaint);

    // Sağ '>'
    final rightBracket = Path()
      ..moveTo(w * 0.63, h * 0.37)
      ..lineTo(w * 0.75, h * 0.50)
      ..lineTo(w * 0.63, h * 0.63);
    canvas.drawPath(rightBracket, strokePaint);

    // Orta '/'
    final slashPath = Path()
      ..moveTo(w * 0.54, h * 0.33)
      ..lineTo(w * 0.46, h * 0.67);
    canvas.drawPath(slashPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EgeDenizDeveloperHeaderBadge extends StatelessWidget {
  const EgeDenizDeveloperHeaderBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return HuzurLiquidGlassSurface(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      borderRadius: 18,
      blurSigma: 16,
      child: Row(
        children: [
          const EgeDenizDeveloperAvatar(size: 42),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text(
                      EgeDenizDeveloperProfile.fullName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.verified_rounded,
                      size: 15,
                      color: Color(0xFF9CE5C9),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  EgeDenizDeveloperProfile.title,
                  style: TextStyle(
                    color: Color(0xFFFFE082),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF9CE5C9).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF9CE5C9).withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 7, color: Color(0xFF9CE5C9)),
                SizedBox(width: 5),
                Text(
                  'Canlı Destek',
                  style: TextStyle(
                    color: Color(0xFF9CE5C9),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SOHBET DAVRANIŞLARI, OTURUM KORUMA & DEĞERLENDİRME YÖNETİCİSİ (ADIM 7)
// ============================================================================

class HuzurSupportSessionGuard {
  static bool shouldTriggerRating({
    required String status,
    required bool closedByAdmin,
    required bool ratingAlreadySubmitted,
  }) {
    final normalized = status.trim().toLowerCase();
    final isClosed = closedByAdmin ||
        normalized == 'closed' ||
        normalized == 'ended' ||
        normalized == 'resolved' ||
        normalized == 'closed_by_admin';
    return isClosed && !ratingAlreadySubmitted;
  }

  static void dismissKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
