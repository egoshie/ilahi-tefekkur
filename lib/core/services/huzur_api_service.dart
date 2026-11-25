import "dart:async";
import "dart:convert";

import "package:firebase_app_check/firebase_app_check.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:http/http.dart" as http;

class HuzurApiException implements Exception {
  const HuzurApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => "HuzurApiException: $message";
}

class HuzurApiService {
  HuzurApiService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl =
            (baseUrl ?? const String.fromEnvironment("HUZUR_API_BASE_URL"))
                .trim();

  final http.Client _client;
  final String _baseUrl;

  Uri _validatedBaseUri() {
    if (_baseUrl.isEmpty) {
      throw StateError("HUZUR_API_BASE_URL henüz yapılandırılmadı.");
    }

    final uri = Uri.tryParse(_baseUrl);
    if (uri == null || uri.scheme != "https" || uri.host.isEmpty) {
      throw StateError("Huzur API adresi geçerli bir HTTPS adresi olmalı.");
    }
    return uri;
  }

  Future<Map<String, dynamic>> _publicGet(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _validatedBaseUri().resolve(path);
    final requestUri = queryParameters == null
        ? uri
        : uri.replace(queryParameters: queryParameters);

    final response = await _client.get(
      requestUri,
      headers: {"Accept": "application/json"},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw HuzurApiException(
        "Dünya verileri alınamadı.",
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const HuzurApiException("Sunucudan geçersiz yanıt alındı.");
    }
    return decoded;
  }

  Future<Map<String, dynamic>> getCountries() {
    return _publicGet("/v1/countries");
  }

  Future<Map<String, dynamic>> getWorldRanking({String? dayKey}) {
    return _publicGet(
      "/v1/world/ranking",
      queryParameters: dayKey == null ? null : {"day_key": dayKey},
    );
  }

  Future<void> updateMyCountry(String countryCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final idToken = await user.getIdToken();
    final appCheckToken = await FirebaseAppCheck.instance.getToken();

    if (idToken == null ||
        idToken.isEmpty ||
        appCheckToken == null ||
        appCheckToken.isEmpty) {
      throw const HuzurApiException("Güvenlik tokenları alınamadı.");
    }

    final response = await _client
        .put(
          _validatedBaseUri().resolve("/v1/me/country"),
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": "Bearer $idToken",
            "X-Firebase-AppCheck": appCheckToken,
          },
          body: jsonEncode({"country_code": countryCode}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw HuzurApiException(
        "Ülke tercihi sunucuya kaydedilemedi.",
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    if (_baseUrl.isEmpty) {
      throw StateError("HUZUR_API_BASE_URL henüz yapılandırılmadı.");
    }

    final baseUri = Uri.tryParse(_baseUrl);
    if (baseUri == null || baseUri.scheme != "https" || baseUri.host.isEmpty) {
      throw StateError("Huzur API adresi geçerli bir HTTPS adresi olmalı.");
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const HuzurApiException(
        "Bu işlem için giriş yapmalısın.",
        statusCode: 401,
      );
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const HuzurApiException("Firebase oturum tokenı alınamadı.");
    }

    final appCheckToken = await FirebaseAppCheck.instance.getToken();
    if (appCheckToken == null || appCheckToken.isEmpty) {
      throw const HuzurApiException("App Check tokenı alınamadı.");
    }

    final uri = baseUri.resolve("/v1/me");

    try {
      final response = await _client.get(
        uri,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $idToken",
          "X-Firebase-AppCheck": appCheckToken,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw HuzurApiException(
          "Huzur sunucusu isteği kabul etmedi.",
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const HuzurApiException("Sunucudan geçersiz yanıt alındı.");
      }

      return decoded;
    } on TimeoutException {
      throw const HuzurApiException("Huzur sunucusu zaman aşımına uğradı.");
    } on FormatException {
      throw const HuzurApiException("Sunucu yanıtı okunamadı.");
    }
  }

  Future<Map<String, dynamic>> syncDhikrBatch({
    required String requestId,
    required int count,
    required String countryCode,
    required String dayKey,
  }) async {
    if (_baseUrl.isEmpty) {
      throw StateError("HUZUR_API_BASE_URL henüz yapılandırılmadı.");
    }

    final baseUri = Uri.tryParse(_baseUrl);
    if (baseUri == null || baseUri.scheme != "https" || baseUri.host.isEmpty) {
      throw StateError("Huzur API adresi geçerli bir HTTPS adresi olmalı.");
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const HuzurApiException(
        "Senkronizasyon için giriş yapılmalı.",
        statusCode: 401,
      );
    }

    final idToken = await user.getIdToken();
    final appCheckToken = await FirebaseAppCheck.instance.getToken();

    if (idToken == null ||
        idToken.isEmpty ||
        appCheckToken == null ||
        appCheckToken.isEmpty) {
      throw const HuzurApiException("Güvenlik tokenları alınamadı.");
    }

    final response = await _client
        .post(
          baseUri.resolve("/v1/dhikr/batches"),
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": "Bearer $idToken",
            "X-Firebase-AppCheck": appCheckToken,
          },
          body: jsonEncode({
            "request_id": requestId,
            "count": count,
            "country_code": countryCode,
            "day_key": dayKey,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw HuzurApiException(
        "Zikir senkronizasyonu reddedildi.",
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const HuzurApiException("Sunucu yanıtı okunamadı.");
    }

    return decoded;
  }

  Future<Map<String, String>> _duaAuthHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const HuzurApiException(
        "Bu işlem için Apple hesabıyla giriş yapmalısın.",
        statusCode: 401,
      );
    }

    final idToken = await user.getIdToken();
    final appCheckToken = await FirebaseAppCheck.instance.getToken();

    if (idToken == null ||
        idToken.isEmpty ||
        appCheckToken == null ||
        appCheckToken.isEmpty) {
      throw const HuzurApiException("Güvenlik tokenları alınamadı.");
    }

    return {
      "Accept": "application/json",
      "Authorization": "Bearer $idToken",
      "X-Firebase-AppCheck": appCheckToken,
    };
  }

  Future<Map<String, dynamic>> _duaAuthenticatedPost(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await _duaAuthHeaders();

    if (body != null) {
      headers["Content-Type"] = "application/json";
    }

    final response = await _client
        .post(
          _validatedBaseUri().resolve(path),
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw HuzurApiException(
        "Dua işlemi tamamlanamadı.",
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const HuzurApiException("Sunucudan geçersiz yanıt alındı.");
    }
    return decoded;
  }

  Future<Map<String, dynamic>> getDuaPosts({int limit = 30}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _publicGet(
        "/v1/dua/posts",
        queryParameters: {"limit": limit.toString()},
      );
    }

    // Authenticated feed requests allow the server to apply this user's block list.
    final headers = await _duaAuthHeaders();
    final uri = _validatedBaseUri()
        .resolve("/v1/dua/posts")
        .replace(queryParameters: {"limit": limit.toString()});
    final response = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw HuzurApiException(
        "Dua akışı alınamadı.",
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const HuzurApiException("Dua akışından geçersiz yanıt alındı.");
    }
    return decoded;
  }

  Future<Map<String, dynamic>> createDuaPost({
    required String body,
    required String countryCode,
  }) {
    return _duaAuthenticatedPost(
      "/v1/dua/posts",
      body: {
        "body": body,
        "country_code": countryCode,
      },
    );
  }

  Future<Map<String, dynamic>> amenDuaPost(String postId) {
    return _duaAuthenticatedPost("/v1/dua/posts/$postId/amin");
  }

  Future<Map<String, dynamic>> reportDuaPost({
    required String postId,
    required String reason,
  }) {
    return _duaAuthenticatedPost(
      "/v1/dua/posts/$postId/report",
      body: {"reason": reason},
    );
  }

  Future<Map<String, dynamic>> getBlockedDuaUsers() async {
    final headers = await _duaAuthHeaders();
    final response = await _client
        .get(_validatedBaseUri().resolve("/v1/dua/blocks"), headers: headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw HuzurApiException(
        "Engellenen kullanıcılar alınamadı.",
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const HuzurApiException("Engelleme yanıtı okunamadı.");
    }
    return decoded;
  }

  Future<Map<String, dynamic>> blockDuaUser(String publicId) {
    return _duaAuthenticatedPost(
      "/v1/dua/users/${Uri.encodeComponent(publicId)}/block",
    );
  }

  Future<Map<String, dynamic>> unblockDuaUser(String publicId) async {
    final headers = await _duaAuthHeaders();
    final uri = _validatedBaseUri().resolve(
      "/v1/dua/users/${Uri.encodeComponent(publicId)}/block",
    );
    final response = await _client
        .delete(uri, headers: headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw HuzurApiException(
        "Kullanıcı engeli kaldırılamadı.",
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const HuzurApiException("Engel kaldırma yanıtı okunamadı.");
    }
    return decoded;
  }

  Future<Map<String, dynamic>> deleteMyAccount() async {
    final headers = await _duaAuthHeaders();
    final response = await _client
        .delete(_validatedBaseUri().resolve("/v1/me"), headers: headers)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw HuzurApiException(
        "Hesaba bağlı sunucu verileri silinemedi.",
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded["deleted"] != true) {
      throw const HuzurApiException(
          "Hesap silme sunucu tarafından doğrulanamadı.");
    }
    return decoded;
  }

  Future<Map<String, dynamic>> deleteDuaPost(String postId) async {
    final headers = await _duaAuthHeaders();
    final uri = _validatedBaseUri().resolve(
      "/v1/dua/posts/${Uri.encodeComponent(postId)}",
    );
    final response = await _client
        .delete(uri, headers: headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw HuzurApiException(
        "Dua silinemedi.",
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded["deleted"] != true) {
      throw const HuzurApiException("Dua silme işlemi doğrulanamadı.");
    }
    return decoded;
  }

  Future<Map<String, String>> _premiumAuthHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const HuzurApiException(
        "Premium işlemi için hesabına giriş yapmalısın.",
        statusCode: 401,
      );
    }

    final idToken = await user.getIdToken();
    final appCheckToken = await FirebaseAppCheck.instance.getToken();

    if (idToken == null ||
        idToken.isEmpty ||
        appCheckToken == null ||
        appCheckToken.isEmpty) {
      throw const HuzurApiException("Güvenlik tokenları alınamadı.");
    }

    return {
      "Accept": "application/json",
      "Authorization": "Bearer $idToken",
      "X-Firebase-AppCheck": appCheckToken,
    };
  }

  Future<String> getPremiumAccountToken() async {
    final response = await _client
        .post(
          _validatedBaseUri().resolve("/v1/premium/account-token"),
          headers: await _premiumAuthHeaders(),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw HuzurApiException(
        "Premium hesap tokenı alınamadı.",
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const HuzurApiException(
          "Premium sunucusundan geçersiz yanıt alındı.");
    }

    final token = decoded["app_account_token"];
    if (token is! String || token.isEmpty) {
      throw const HuzurApiException(
          "Apple hesap tokenı yanıt içinde bulunamadı.");
    }
    return token;
  }

  Future<Map<String, dynamic>> verifyPremiumTransaction({
    required String signedTransaction,
  }) async {
    final headers = await _premiumAuthHeaders();
    headers["Content-Type"] = "application/json";

    final response = await _client
        .post(
          _validatedBaseUri().resolve("/v1/premium/verify"),
          headers: headers,
          body: jsonEncode({
            "signed_transaction": signedTransaction,
            "allow_legacy_claim": false,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw HuzurApiException(
        "Apple satın alımı Huzur sunucusunda doğrulanamadı.",
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const HuzurApiException("Premium doğrulama yanıtı okunamadı.");
    }
    return decoded;
  }

  Future<Map<String, dynamic>> getMyPremiumStatus() async {
    final response = await _client
        .get(
          _validatedBaseUri().resolve("/v1/premium/me"),
          headers: await _premiumAuthHeaders(),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw HuzurApiException(
        "Premium hesap durumu alınamadı.",
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const HuzurApiException("Premium hesap yanıtı okunamadı.");
    }
    return decoded;
  }

  void close() {
    _client.close();
  }
}
