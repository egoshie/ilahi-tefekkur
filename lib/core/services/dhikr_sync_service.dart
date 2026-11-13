import "dart:async";
import "dart:convert";
import "dart:math";

import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "huzur_api_service.dart";
import "user_progress_service.dart";

class DhikrSyncService {
  static const String _queueKey = "huzur_dhikr_sync_queue_v1";

  final HuzurApiService _api = HuzurApiService();
  final Random _random = Random.secure();
  final Set<String> _inFlight = <String>{};

  Future<void> _queueTail = Future<void>.value();
  Timer? _debounce;
  late final Timer _retryTimer;
  late final StreamSubscription<User?> _authSubscription;

  bool _syncing = false;
  bool _disposed = false;

  DhikrSyncService() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      unawaited(syncPending());
    });

    _retryTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => unawaited(syncPending()),
    );
  }

  Future<T> _locked<T>(Future<T> Function() action) {
    final completer = Completer<T>();

    _queueTail = _queueTail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }

  String? _countryCode(String value) {
    switch (value.trim().toLowerCase()) {
      case "türkiye":
      case "turkiye":
      case "turkey":
      case "tr":
        return "TR";
      case "suudi arabistan":
      case "saudi arabia":
      case "sa":
        return "SA";
      case "filistin":
      case "palestine":
      case "palestine, state of":
      case "ps":
        return "PS";
      default:
        final code = value.trim().toUpperCase();
        return RegExp(r"^[A-Z]{2}$").hasMatch(code) ? code : null;
    }
  }

  String _newRequestId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, "0")).join();

    return "${hex.substring(0, 8)}-${hex.substring(8, 12)}-"
        "${hex.substring(12, 16)}-${hex.substring(16, 20)}-"
        "${hex.substring(20, 32)}";
  }

  Future<List<Map<String, dynamic>>> _readQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);

    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException("Zikir kuyruğu geçersiz.");
    }

    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _writeQueue(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_queueKey, jsonEncode(items));
  }

  Future<void> recordDhikr({required String countryName}) async {
    if (_disposed) return;

    final countryCode = _countryCode(countryName);
    if (countryCode == null) {
      debugPrint("Huzur: ülke kodu eşleştirilemedi; yerel zikir korundu.");
      return;
    }

    try {
      final dayKey = huzurIstanbulDayKey();

      await _locked(() async {
        final queue = await _readQueue();

        final index = queue.lastIndexWhere((item) {
          final id = item["request_id"] as String;
          final count = item["count"] as int;

          return item["day_key"] == dayKey &&
              item["country_code"] == countryCode &&
              !_inFlight.contains(id) &&
              count < 10000;
        });

        if (index >= 0) {
          queue[index]["count"] = (queue[index]["count"] as int) + 1;
        } else {
          queue.add({
            "request_id": _newRequestId(),
            "count": 1,
            "country_code": countryCode,
            "day_key": dayKey,
          });
        }

        await _writeQueue(queue);
      });

      _scheduleSync();
    } catch (error) {
      debugPrint("Huzur zikir kuyruğu kaydedilemedi: $error");
    }
  }

  void _scheduleSync() {
    if (_disposed) return;

    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 1200),
      () => unawaited(syncPending()),
    );
  }

  Future<void> syncPending() async {
    if (_disposed || _syncing) return;
    _syncing = true;

    try {
      while (!_disposed) {
        final item = await _locked<Map<String, dynamic>?>(() async {
          final queue = await _readQueue();

          for (final entry in queue) {
            final id = entry["request_id"] as String;
            if (!_inFlight.contains(id)) {
              _inFlight.add(id);
              return Map<String, dynamic>.from(entry);
            }
          }

          return null;
        });

        if (item == null) break;

        final id = item["request_id"] as String;

        try {
          final response = await _api.syncDhikrBatch(
            requestId: id,
            count: item["count"] as int,
            countryCode: item["country_code"] as String,
            dayKey: item["day_key"] as String,
          );

          if (response["accepted"] != true) break;

          await _locked(() async {
            final queue = await _readQueue();
            queue.removeWhere((entry) => entry["request_id"] == id);
            await _writeQueue(queue);
          });
        } catch (error) {
          debugPrint("Huzur senkronizasyonu beklemede: $error");
          break;
        } finally {
          _inFlight.remove(id);
        }
      }
    } catch (error) {
      debugPrint("Huzur senkronizasyon kuyruğu okunamadı: $error");
    } finally {
      _syncing = false;
    }
  }

  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _retryTimer.cancel();
    unawaited(_authSubscription.cancel());
    _api.close();
  }
}
