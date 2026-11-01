import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilahi_tefekkur/core/services/huzur_live_support_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Gizlilik onayı başlangıçta işaretsiz (false) olmalı ve onaysız oturum reddedilmeli', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = HuzurLiveSupportNotifier();

    expect(notifier.state.privacyConsentGiven, isFalse);
    expect(notifier.state.privacyConsentVersion, equals('2026.1'));

    final startedWithoutConsent = await notifier.startSession(
      fullName: 'Deniz',
      privacyConsent: false,
      initialMessage: 'Merhaba',
    );

    expect(startedWithoutConsent, isFalse);
    expect(notifier.state.hasActiveSession, isFalse);
    expect(notifier.state.errorMessage, isNotNull);
  });
}
