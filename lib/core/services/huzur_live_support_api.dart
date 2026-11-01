import 'notification_support_compat.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

const String kPrivacyPolicyConsentVersion = '2026.1';
const String kDeveloperPushNotificationTitle = 'Ege size yazdı';

class SupportMessageItem {
  final String id;
  final String sender;
  final String senderName;
  final String text;
  final DateTime createdAt;

  const SupportMessageItem({
    required this.id,
    required this.sender,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  bool get isFromDeveloper {
    final s = sender.toLowerCase();
    return s == 'developer' || s == 'admin' || s == 'ege' || s == 'support';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'sender_name': senderName,
        'text': text,
        'created_at': createdAt.toIso8601String(),
      };

  factory SupportMessageItem.fromJson(Map<String, dynamic> map) {
    final rawSender = (map['sender'] ?? map['role'] ?? 'user').toString();
    final isDev = rawSender.toLowerCase() == 'developer' ||
        rawSender.toLowerCase() == 'admin' ||
        rawSender.toLowerCase() == 'ege' ||
        rawSender.toLowerCase() == 'support';

    return SupportMessageItem(
      id: (map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
          .toString(),
      sender: isDev ? 'developer' : 'user',
      senderName: (map['sender_name'] ?? (isDev ? 'Ege Deniz' : 'Kullanıcı'))
          .toString(),
      text: (map['text'] ?? map['message'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class SupportSessionState {
  final String? sessionId;
  final String? shortCode;
  final String userName;
  final bool privacyConsentGiven;
  final String privacyConsentVersion;
  final String status;
  final String pushPermissionStatus;
  final String? registeredPushToken;
  final List<SupportMessageItem> messages;
  final bool isLoading;
  final String? errorMessage;

  const SupportSessionState({
    this.sessionId,
    this.shortCode,
    this.userName = '',
    this.privacyConsentGiven = false,
    this.privacyConsentVersion = kPrivacyPolicyConsentVersion,
    this.status = 'idle',
    this.pushPermissionStatus = 'notDetermined',
    this.registeredPushToken,
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  bool get hasActiveSession =>
      sessionId != null && sessionId!.isNotEmpty && status == 'active';

  bool get isClosedForRating => status == 'closed';

  bool get isPushPermissionDenied => pushPermissionStatus == 'denied';

  SupportSessionState copyWith({
    String? sessionId,
    String? shortCode,
    String? userName,
    bool? privacyConsentGiven,
    String? privacyConsentVersion,
    String? status,
    String? pushPermissionStatus,
    String? registeredPushToken,
    List<SupportMessageItem>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearSession = false,
  }) {
    if (clearSession) {
      return SupportSessionState(
        privacyConsentGiven: false,
        status: 'idle',
        pushPermissionStatus: pushPermissionStatus ?? this.pushPermissionStatus,
        registeredPushToken: registeredPushToken ?? this.registeredPushToken,
      );
    }
    return SupportSessionState(
      sessionId: sessionId ?? this.sessionId,
      shortCode: shortCode ?? this.shortCode,
      userName: userName ?? this.userName,
      privacyConsentGiven: privacyConsentGiven ?? this.privacyConsentGiven,
      privacyConsentVersion:
          privacyConsentVersion ?? this.privacyConsentVersion,
      status: status ?? this.status,
      pushPermissionStatus: pushPermissionStatus ?? this.pushPermissionStatus,
      registeredPushToken: registeredPushToken ?? this.registeredPushToken,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final huzurLiveSupportProvider =
    StateNotifierProvider<HuzurLiveSupportNotifier, SupportSessionState>((ref) {
  return HuzurLiveSupportNotifier();
});

class HuzurLiveSupportNotifier extends StateNotifier<SupportSessionState> {
  static String baseUrl = 'https://api.getbible.net';
  Timer? _pollTimer;
  final Set<String> _notifiedDeveloperMessageIds = {};

  HuzurLiveSupportNotifier() : super(const SupportSessionState()) {
    _initializeSupportAndPush();
  }

  Future<void> _initializeSupportAndPush() async {
    NotificationAndWidgetService.instance.addTokenRefreshListener((newToken) {
      registerPushTokenWithBackend(newToken);
    });

    await _restorePersistedSession();
    final perm =
        await NotificationAndWidgetService.instance.checkPermissionStatus();
    final token = NotificationAndWidgetService.instance.currentPushToken;
    state = state.copyWith(
      pushPermissionStatus: perm,
      registeredPushToken: token,
    );
    if (token != null && token.isNotEmpty) {
      await registerPushTokenWithBackend(token);
    }
  }

  Future<void> refreshPushPermissionStatus() async {
    final perm =
        await NotificationAndWidgetService.instance.checkPermissionStatus();
    state = state.copyWith(pushPermissionStatus: perm);
  }

  Future<bool> registerPushTokenWithBackend(String token) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) return false;
    state = state.copyWith(registeredPushToken: cleanToken);

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/support/push/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'fcm_token': cleanToken,
              'platform': 'ios',
              if (state.sessionId != null) 'session_id': state.sessionId,
            }),
          )
          .timeout(const Duration(seconds: 6));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _restorePersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSessionId = prefs.getString('huzur_support_session_id');
    final savedShortCode = prefs.getString('huzur_support_short_code');
    final savedUserName = prefs.getString('huzur_support_user_name') ?? '';
    final savedStatus = prefs.getString('huzur_support_status') ?? 'idle';
    final savedConsent =
        prefs.getBool('huzur_support_privacy_consent') ?? false;
    final rawMsgs = prefs.getStringList('huzur_support_messages') ?? const [];

    if (savedSessionId != null && savedSessionId.isNotEmpty && savedConsent) {
      final restoredMessages = <SupportMessageItem>[];
      for (final item in rawMsgs) {
        try {
          final parsedMsg = SupportMessageItem.fromJson(
            Map<String, dynamic>.from(jsonDecode(item) as Map),
          );
          restoredMessages.add(parsedMsg);
          if (parsedMsg.isFromDeveloper) {
            _notifiedDeveloperMessageIds.add(parsedMsg.id);
          }
        } catch (_) {}
      }

      state = state.copyWith(
        sessionId: savedSessionId,
        shortCode: savedShortCode,
        userName: savedUserName,
        privacyConsentGiven: savedConsent,
        status: savedStatus,
        messages: restoredMessages,
      );

      if (savedStatus == 'active') {
        _startPolling();
      }
    }
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.sessionId == null || state.status == 'idle') {
      await prefs.remove('huzur_support_session_id');
      await prefs.remove('huzur_support_short_code');
      await prefs.remove('huzur_support_user_name');
      await prefs.remove('huzur_support_status');
      await prefs.remove('huzur_support_privacy_consent');
      await prefs.remove('huzur_support_messages');
      return;
    }

    await prefs.setString('huzur_support_session_id', state.sessionId!);
    if (state.shortCode != null) {
      await prefs.setString('huzur_support_short_code', state.shortCode!);
    }
    await prefs.setString('huzur_support_user_name', state.userName);
    await prefs.setString('huzur_support_status', state.status);
    await prefs.setBool(
        'huzur_support_privacy_consent', state.privacyConsentGiven);
    await prefs.setStringList(
      'huzur_support_messages',
      state.messages.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }

  void setPrivacyConsent(bool accepted) {
    state = state.copyWith(
      privacyConsentGiven: accepted,
      errorMessage: null,
    );
  }

  Future<bool> startSession({
    required String fullName,
    required bool privacyConsent,
    required String initialMessage,
    String? fcmToken,
  }) async {
    final cleanName = fullName.trim();
    final cleanMsg = initialMessage.trim();

    if (!privacyConsent) {
      state = state.copyWith(
        errorMessage:
            'Görüşme başlatmak için gizlilik aydınlatma metnini onaylamanız gerekmektedir.',
      );
      return false;
    }

    if (cleanName.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Lütfen adınızı girin.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = fcmToken ??
          state.registeredPushToken ??
          prefs.getString('huzur_fcm_token');

      final payload = <String, dynamic>{
        'user_name': cleanName,
        'privacy_consent': true,
        'privacy_consent_version': kPrivacyPolicyConsentVersion,
        'initial_message': cleanMsg,
        if (savedToken != null && savedToken.isNotEmpty)
          'fcm_token': savedToken,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/support/sessions'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final sessionId = (data['session_id'] ?? data['id'] ?? '').toString();
        final shortCode = (data['short_code'] ?? '').toString();

        final rawServerMsgs = data['messages'] as List<dynamic>?;
        final List<SupportMessageItem> initialMessages = [];

        if (rawServerMsgs != null && rawServerMsgs.isNotEmpty) {
          for (final item in rawServerMsgs) {
            final m = SupportMessageItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            );
            initialMessages.add(m);
            if (m.isFromDeveloper) {
              _notifiedDeveloperMessageIds.add(m.id);
            }
          }
        } else {
          const welcomeId = 'welcome_ege';
          _notifiedDeveloperMessageIds.add(welcomeId);
          initialMessages.add(
            SupportMessageItem(
              id: welcomeId,
              sender: 'developer',
              senderName: 'Ege Deniz',
              text:
                  'Merhaba $cleanName, Huzur Canlı Destek hattına hoş geldiniz. Mesajınız bana ulaştı, en kısa sürede yanıtlayacağım.',
              createdAt: DateTime.now(),
            ),
          );
          if (cleanMsg.isNotEmpty) {
            initialMessages.add(
              SupportMessageItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                sender: 'user',
                senderName: cleanName,
                text: cleanMsg,
                createdAt: DateTime.now(),
              ),
            );
          }
        }

        state = state.copyWith(
          sessionId: sessionId,
          shortCode: shortCode.isNotEmpty ? shortCode : null,
          userName: cleanName,
          privacyConsentGiven: true,
          privacyConsentVersion: kPrivacyPolicyConsentVersion,
          status: 'active',
          messages: initialMessages,
          isLoading: false,
          errorMessage: null,
        );

        await _persistState();
        _startPolling();
        return true;
      } else {
        final errBody = utf8.decode(response.bodyBytes);
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Destek oturumu açılamadı (${response.statusCode}): $errBody',
        );
        return false;
      }
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Sunucu bağlantısı kurulamadı. Lütfen internet bağlantınızı kontrol edin.',
      );
      return false;
    }
  }

  Future<bool> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || !state.hasActiveSession) return false;

    final optimistic = SupportMessageItem(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      senderName: state.userName,
      text: clean,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, optimistic],
      errorMessage: null,
    );
    await _persistState();

    try {
      final response = await http
          .post(
            Uri.parse(
                '$baseUrl/api/support/sessions/${state.sessionId}/messages'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'sender': 'user',
              'sender_name': state.userName,
              'text': clean,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchMessages();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchMessages() async {
    if (state.sessionId == null || state.sessionId!.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/support/sessions/${state.sessionId}'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final remoteStatus = (data['status'] ?? 'active').toString();
        final rawList = data['messages'] as List<dynamic>? ?? const [];

        final parsed = rawList
            .map((e) => SupportMessageItem.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();

        // Yeni gelen Ege Deniz mesajlarını tespit et ve "Ege size yazdı" bildirimi göster
        for (final msg in parsed) {
          if (msg.isFromDeveloper &&
              !_notifiedDeveloperMessageIds.contains(msg.id)) {
            _notifiedDeveloperMessageIds.add(msg.id);
            await NotificationAndWidgetService.instance
                .showEgeReplyNotification(
              messageText: msg.text,
              shortCode: state.shortCode,
            );
          }
        }

        state = state.copyWith(
          status: remoteStatus == 'closed' ? 'closed' : state.status,
          shortCode: (data['short_code'] ?? state.shortCode)?.toString(),
          messages: parsed.isNotEmpty ? parsed : state.messages,
        );
        await _persistState();

        if (remoteStatus == 'closed') {
          _pollTimer?.cancel();
        }
      }
    } catch (_) {}
  }

  Future<void> closeSessionForRating() async {
    _pollTimer?.cancel();
    final currentId = state.sessionId;
    state = state.copyWith(status: 'closed');
    await _persistState();

    if (currentId != null && currentId.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('$baseUrl/api/support/sessions/$currentId/close'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 6));
      } catch (_) {}
    }
  }

  Future<bool> submitRating({
    required int stars,
    required String comment,
  }) async {
    final currentId = state.sessionId;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      if (currentId != null && currentId.isNotEmpty) {
        await http
            .post(
              Uri.parse('$baseUrl/api/support/sessions/$currentId/rating'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'stars': stars.clamp(1, 5),
                'comment': comment.trim(),
              }),
            )
            .timeout(const Duration(seconds: 8));
      }
    } catch (_) {}

    _pollTimer?.cancel();
    _notifiedDeveloperMessageIds.clear();
    state = state.copyWith(clearSession: true);
    await _persistState();
    return true;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      fetchMessages();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
