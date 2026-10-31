import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

typedef HuzurJson = Map<String, dynamic>;

class HuzurSupportApiException implements Exception {
  final String message;
  final int? statusCode;

  const HuzurSupportApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class HuzurSupportSessionCreated {
  final String sessionId;
  final int queuePosition;
  final String status;

  const HuzurSupportSessionCreated({
    required this.sessionId,
    required this.queuePosition,
    required this.status,
  });

  factory HuzurSupportSessionCreated.fromJson(HuzurJson json) {
    final id = (json['session_id'] ?? json['id'] ?? '').toString();

    if (id.isEmpty) {
      throw const HuzurSupportApiException(
        'Sunucu oturum numarası döndürmedi.',
      );
    }

    return HuzurSupportSessionCreated(
      sessionId: id,
      queuePosition: _toInt(json['queue_position'], fallback: 0),
      status: (json['status'] ?? 'waiting').toString(),
    );
  }
}

class HuzurSupportMessage {
  final String id;
  final String text;
  final String sender;
  final DateTime createdAt;
  final bool isRead;

  const HuzurSupportMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.createdAt,
    required this.isRead,
  });

  bool get isFromDeveloper => sender == 'developer' || sender == 'admin';

  factory HuzurSupportMessage.fromJson(HuzurJson json) {
    return HuzurSupportMessage(
      id: (json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      sender: (json['sender'] ?? json['role'] ?? 'user').toString(),
      createdAt: DateTime.tryParse(
            (json['created_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
      isRead: json['is_read'] == true,
    );
  }
}

class HuzurSupportSessionSnapshot {
  final String sessionId;
  final String status;
  final int queuePosition;
  final bool developerTyping;
  final bool closed;
  final List<HuzurSupportMessage> messages;

  const HuzurSupportSessionSnapshot({
    required this.sessionId,
    required this.status,
    required this.queuePosition,
    required this.developerTyping,
    required this.closed,
    required this.messages,
  });

  factory HuzurSupportSessionSnapshot.fromJson(HuzurJson json) {
    final rawMessages = json['messages'];

    final messages = rawMessages is List
        ? rawMessages
            .whereType<Map>()
            .map(
              (item) => HuzurSupportMessage.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : <HuzurSupportMessage>[];

    return HuzurSupportSessionSnapshot(
      sessionId: (json['session_id'] ?? json['id'] ?? '').toString(),
      status: (json['status'] ?? 'waiting').toString(),
      queuePosition: _toInt(json['queue_position']),
      developerTyping: json['developer_typing'] == true,
      closed: json['closed'] == true || json['status']?.toString() == 'closed',
      messages: messages,
    );
  }
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

class HuzurLiveSupportApi {
  HuzurLiveSupportApi({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ??
                const String.fromEnvironment(
                  'HUZUR_SUPPORT_API_URL',
                  defaultValue: '',
                ))
            .trim()
            .replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  static const Duration _timeout = Duration(seconds: 15);

  Uri _uri(String path) {
    if (_baseUrl.isEmpty) {
      throw const HuzurSupportApiException(
        'Canlı destek sunucu adresi henüz yapılandırılmadı.',
      );
    }

    final parsed = Uri.tryParse(_baseUrl);

    if (parsed == null ||
        !parsed.hasScheme ||
        parsed.host.isEmpty ||
        !['https', 'http'].contains(parsed.scheme)) {
      throw const HuzurSupportApiException(
        'Canlı destek sunucu adresi geçersiz.',
      );
    }

    return Uri.parse('$_baseUrl$path');
  }

  Future<HuzurJson> _request(
    String method,
    String path, {
    HuzurJson? body,
  }) async {
    final uri = _uri(path);

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
    };

    try {
      late http.Response response;

      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(_timeout);
          break;

        case 'POST':
          response = await _client
              .post(
                uri,
                headers: headers,
                body: jsonEncode(body ?? <String, dynamic>{}),
              )
              .timeout(_timeout);
          break;

        default:
          throw const HuzurSupportApiException(
            'Desteklenmeyen HTTP işlemi.',
          );
      }

      final responseText = utf8.decode(response.bodyBytes);

      dynamic decoded;

      if (responseText.trim().isNotEmpty) {
        try {
          decoded = jsonDecode(responseText);
        } on FormatException {
          throw const HuzurSupportApiException(
            'Sunucudan geçersiz JSON yanıtı geldi.',
          );
        }
      } else {
        decoded = <String, dynamic>{};
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map
            ? (decoded['detail'] ??
                    decoded['message'] ??
                    'İşlem tamamlanamadı.')
                .toString()
            : 'İşlem tamamlanamadı.';

        throw HuzurSupportApiException(
          message,
          response.statusCode,
        );
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return <String, dynamic>{'data': decoded};
    } on HuzurSupportApiException {
      rethrow;
    } on http.ClientException {
      throw const HuzurSupportApiException(
        'Sunucuya bağlantı kurulamadı.',
      );
    } on FormatException {
      throw const HuzurSupportApiException(
        'Sunucu adresi veya yanıt biçimi geçersiz.',
      );
    } catch (error) {
      if (error is HuzurSupportApiException) rethrow;

      throw HuzurSupportApiException(
        'Canlı destek bağlantı hatası: $error',
      );
    }
  }

  String _sessionPath(String sessionId) {
    return '/api/v1/sessions/${Uri.encodeComponent(sessionId)}';
  }

  Future<HuzurSupportSessionCreated> createSession({
    required String name,
    required String email,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty) {
      throw const HuzurSupportApiException(
        'Lütfen adınızı girin.',
      );
    }

    if (!RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(cleanEmail)) {
      throw const HuzurSupportApiException(
        'Geçerli bir e-posta adresi girin.',
      );
    }

    final json = await _request(
      'POST',
      '/api/v1/sessions',
      body: <String, dynamic>{
        'name': cleanName,
        'email': cleanEmail,
      },
    );

    return HuzurSupportSessionCreated.fromJson(json);
  }

  Future<HuzurSupportSessionSnapshot> getSession(
    String sessionId,
  ) async {
    final json = await _request(
      'GET',
      _sessionPath(sessionId),
    );

    return HuzurSupportSessionSnapshot.fromJson(json);
  }

  Future<void> sendMessage({
    required String sessionId,
    required String text,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) return;

    if (cleanText.length > 4000) {
      throw const HuzurSupportApiException(
        'Mesaj en fazla 4000 karakter olabilir.',
      );
    }

    await _request(
      'POST',
      '${_sessionPath(sessionId)}/messages',
      body: <String, dynamic>{
        'text': cleanText,
      },
    );
  }

  Future<void> setTyping({
    required String sessionId,
    required bool isTyping,
  }) async {
    return; // [ADIM 8] Telegram yazma onizlemesi kaldirildi
  }

  Future<void> markMessagesRead({
    required String sessionId,
    required List<String> messageIds,
  }) async {
    if (messageIds.isEmpty) return;

    await _request(
      'POST',
      '${_sessionPath(sessionId)}/read',
      body: <String, dynamic>{
        'message_ids': messageIds,
      },
    );
  }

  Future<void> registerDeviceToken({
    required String sessionId,
    required String token,
  }) async {
    if (token.trim().isEmpty) return;

    await _request(
      'POST',
      '${_sessionPath(sessionId)}/device-token',
      body: <String, dynamic>{
        'token': token.trim(),
      },
    );
  }

  Future<void> submitReview({
    required String sessionId,
    required int stars,
    required String review,
  }) async {
    if (stars < 1 || stars > 5) {
      throw const HuzurSupportApiException(
        'Yıldız değerlendirmesi 1 ile 5 arasında olmalı.',
      );
    }

    final cleanReview = review.trim();

    if (cleanReview.length > 2000) {
      throw const HuzurSupportApiException(
        'Değerlendirme en fazla 2000 karakter olabilir.',
      );
    }

    await _request(
      'POST',
      '${_sessionPath(sessionId)}/review',
      body: <String, dynamic>{
        'stars': stars,
        'review': cleanReview,
      },
    );
    await clearSavedSession();
  }

  Future<void> clearSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('huzur_live_support_session_id');
  }

  Future<void> dispose() async {
    _client.close();
  }
}

// ============================================================================
// TELEGRAM KALICI KISA KOD (ege1, ege2, ali1) & KOMUT ÇÖZÜMLEYİCİ (ADIM 8)
// ============================================================================

class HuzurTelegramShortCodeHelper {
  static const Map<String, String> _trCharMap = {
    'ç': 'c', 'Ç': 'c',
    'ğ': 'g', 'Ğ': 'g',
    'ı': 'i', 'I': 'i', 'İ': 'i',
    'ö': 'o', 'Ö': 'o',
    'ş': 's', 'Ş': 's',
    'ü': 'u', 'Ü': 'u',
  };

  /// Kullanıcının ilk adından temiz bir önek üretir (örn: "Ege Deniz" -> "ege", "Ali" -> "ali")
  static String normalizeNamePrefix(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'uye';
    final firstWord = trimmed.split(RegExp(r'\s+')).first;
    final buffer = StringBuffer();
    for (final rune in firstWord.runes) {
      final ch = String.fromCharCode(rune);
      final mapped = _trCharMap[ch] ?? ch.toLowerCase();
      if (RegExp(r'^[a-z0-9]$').hasMatch(mapped)) {
        buffer.write(mapped);
      }
    }
    final result = buffer.toString();
    return result.isEmpty ? 'uye' : result;
  }

  /// Dahili UUID korunurken Telegram tarafında gösterilecek kalıcı kısa kodu üretir (örn: ege1, ege2, ali1)
  static String buildShortCode({
    required String fullName,
    int sequenceNumber = 1,
    String? existingShortCode,
  }) {
    if (existingShortCode != null &&
        RegExp(r'^[a-z0-9]+[0-9]+$').hasMatch(existingShortCode.trim())) {
      return existingShortCode.trim().toLowerCase();
    }
    final prefix = normalizeNamePrefix(fullName);
    final seq = sequenceNumber < 1 ? 1 : sequenceNumber;
    return '$prefix$seq';
  }
}
