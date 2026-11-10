import 'package:flutter/services.dart';

class LocalAIAvailability {
  final bool available;
  final String reason;

  const LocalAIAvailability({
    required this.available,
    required this.reason,
  });

  factory LocalAIAvailability.fromMap(Map<String, dynamic> map) {
    return LocalAIAvailability(
      available: map['available'] == true,
      reason: map['reason'] as String? ?? 'unknown',
    );
  }
}

class LocalAIService {
  LocalAIService._();

  static const MethodChannel _channel =
      MethodChannel('com.ilahi.tefekkur/local_ai');

  static Future<LocalAIAvailability> checkAvailability() async {
    try {
      final response =
          await _channel.invokeMapMethod<String, dynamic>('availability');

      return LocalAIAvailability.fromMap(
        response ??
            const {
              'available': false,
              'reason': 'empty-response',
            },
      );
    } on PlatformException catch (error) {
      return LocalAIAvailability(
        available: false,
        reason: error.code,
      );
    } on MissingPluginException {
      return const LocalAIAvailability(
        available: false,
        reason: 'native-channel-missing',
      );
    }
  }

  static Future<String> generate({
    required String prompt,
    required String instructions,
  }) async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'generate',
      {
        'prompt': prompt,
        'instructions': instructions,
      },
    );

    final text = response?['text'] as String?;

    if (text == null || text.trim().isEmpty) {
      throw PlatformException(
        code: 'empty-response',
        message: 'Yerel AI boş yanıt döndürdü.',
      );
    }

    return text;
  }

  static Future<void> reset() async {
    await _channel.invokeMethod<void>('reset');
  }
}
