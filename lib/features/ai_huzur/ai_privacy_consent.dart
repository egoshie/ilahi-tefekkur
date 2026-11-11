import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiPrivacyConsent {
  static const String freeQuestionQuotaKey =
      'huzur_dini_asistan_free_questions_v1';

  static String _consentKey(String uid) => 'huzur_ai_gemini_consent_v1_$uid';

  static String _acceptedAtKey(String uid) =>
      'huzur_ai_gemini_consent_accepted_at_v1_$uid';

  static Future<bool> hasConsent(String uid) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_consentKey(uid)) ?? false;
  }

  static Future<bool> ensureConsent(
    BuildContext context,
    String uid,
  ) async {
    if (await hasConsent(uid)) return true;
    if (!context.mounted) return false;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AiGeminiConsentDialog(),
    );

    if (accepted != true) return false;

    await setConsent(uid, true);
    return true;
  }

  static Future<void> setConsent(String uid, bool enabled) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_consentKey(uid), enabled);

    if (enabled) {
      await preferences.setString(
        _acceptedAtKey(uid),
        DateTime.now().toUtc().toIso8601String(),
      );
    } else {
      await preferences.remove(_acceptedAtKey(uid));
    }
  }

  static Future<void> clearForAccount(String uid) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_consentKey(uid));
    await preferences.remove(_acceptedAtKey(uid));
    await preferences.remove(freeQuestionQuotaKey);
  }
}

class _AiGeminiConsentDialog extends StatefulWidget {
  const _AiGeminiConsentDialog();

  @override
  State<_AiGeminiConsentDialog> createState() => _AiGeminiConsentDialogState();
}

class _AiGeminiConsentDialogState extends State<_AiGeminiConsentDialog> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFFFA21A);

    return Dialog(
      backgroundColor: const Color(0xFF211B14),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: amber.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.privacy_tip_outlined,
                color: amber,
                size: 30,
              ),
              const SizedBox(height: 14),
              const Text(
                'AI veri paylaşım izni',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Huzur Dini Asistanı yanıt oluşturabilmek için '
                'gönderdiğin soru metnini, özellikle seçtiğin görseli '
                've yanıt için gerekli sohbet bağlamını Firebase AI Logic '
                'aracılığıyla Google tarafından sunulan yapay zekâ hizmetine iletir.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'İstek sırasında IP adresi ve bağlantı gibi teknik '
                'bilgiler de ilgili hizmet sağlayıcılar tarafından '
                'işlenebilir. Google ve Firebase hizmetlerinin veri '
                'saklama ve işleme koşulları kendi güncel şartlarına '
                'tabidir. Huzur bu sağlayıcıların sistemlerindeki '
                'saklama sürelerini bağımsız olarak belirlemez.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Lütfen şifre, kimlik numarası, finansal bilgi veya '
                'başkalarına ait özel/hassas bilgileri göndermemeye '
                'dikkat et.',
                style: TextStyle(
                  color: Color(0xFFFFDCA0),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _checked,
                onChanged: (value) {
                  setState(() => _checked = value ?? false);
                },
                activeColor: amber,
                checkColor: Colors.black,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Bu veri aktarımını anladım ve açıkça kabul ediyorum.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'İznimi daha sonra Profilim bölümünden geri çekebilirim.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Şimdi değil',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _checked
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: amber,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white12,
                        disabledForegroundColor: Colors.white38,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text(
                        'Kabul et',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
