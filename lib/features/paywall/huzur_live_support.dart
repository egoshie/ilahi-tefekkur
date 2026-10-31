import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _HuzurLiveSupportSheet(),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF102D28),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF78CDB0).withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.support_agent_rounded,
                color: Color(0xFF9CE5C9),
                size: 25,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Geliştiriciyle Görüş',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Sorularınız için canlı destek',
                      style: TextStyle(
                        color: Color(0xFFB8CEC7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF9CE5C9),
                size: 15,
              ),
            ],
          ),
        ),
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
  final _api = HuzurLiveSupportApi();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _reviewController = TextEditingController();

  Timer? _pollTimer;
  Timer? _typingTimer;

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
  bool _typingActive = false;

  int _stars = 5;

  static const _background = Color(0xFF08120F);
  static const _surface = Color(0xFF12221D);
  static const _accent = Color(0xFF9CE5C9);

  @override
  void dispose() {
    _pollTimer?.cancel();
    _typingTimer?.cancel();

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
        _typingTimer?.cancel();
        await _setTyping(false);
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

  void _onMessageChanged(String value) {
    _typingTimer?.cancel();

    if (value.trim().isEmpty) {
      unawaited(_setTyping(false));
      return;
    }

    unawaited(_setTyping(true));

    _typingTimer = Timer(
      const Duration(milliseconds: 900),
      () => _setTyping(false),
    );
  }

  Future<void> _setTyping(bool value) async {
    final id = _sessionId;

    if (id == null || _typingActive == value) return;

    _typingActive = value;

    try {
      await _api.setTyping(
        sessionId: id,
        isTyping: value,
      );
    } catch (error) {
      debugPrint('Huzur typing status: $error');
    }
  }

  Future<void> _sendMessage() async {
    final id = _sessionId;
    final text = _messageController.text.trim();

    if (id == null || text.isEmpty || _sending) return;

    FocusScope.of(context).unfocus();
    setState(() => _sending = true);

    try {
      await _setTyping(false);

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
                  'Huzur Canlı Destek',
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
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFADC1B7)),
        prefixIcon: Icon(icon, color: _accent, size: 20),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: Color(0xFFFFA5A5)),
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
                    onChanged: _onMessageChanged,
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
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Container(
        decoration: const BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25),
          ),
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
    );
  }
}
