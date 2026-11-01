import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilahi_tefekkur/core/services/huzur_live_support_api.dart';
import 'package:ilahi_tefekkur/core/services/offline_sacred_repository.dart';
import 'package:ilahi_tefekkur/core/theme/glass_container.dart';
import 'package:ilahi_tefekkur/features/support/huzur_live_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Kriter 1 & 2: Kullanıcıya görünen hiçbir ekranda Liquid Glass veya V1.0 metni bulunmamalı', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType< File >()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      expect(
        content.contains('Huzur Canlı Destek • Liquid Glass'),
        isFalse,
        reason: '${file.path} içinde Huzur Canlı Destek • Liquid Glass bulundu',
      );
      expect(
        RegExp(r'\b[vV]1\.0\b').hasMatch(content),
        isFalse,
        reason: '${file.path} içinde V1.0 ifadesi bulundu',
      );
    }
  });

  test('Kriter 3 & 6: Gizlilik onayı zorunlu olmalı ve bildirim başlığı Ege size yazdı olmalı', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = HuzurLiveSupportNotifier();

    expect(notifier.state.privacyConsentGiven, isFalse);
    expect(kDeveloperPushNotificationTitle, equals('Ege size yazdı'));

    final rejected = await notifier.startSession(
      fullName: 'Deniz',
      privacyConsent: false,
      initialMessage: 'Test mesajı',
    );
    expect(rejected, isFalse);
    expect(notifier.state.hasActiveSession, isFalse);
    expect(
      notifier.state.errorMessage,
      contains('gizlilik aydınlatma metnini onaylamanız'),
    );
  });

  testWidgets('Kriter 1, 2, 7 & 8: Canlı Destek cam tasarımı, Ege Deniz avatarı, sohbet ve değerlendirme sonrası temizlik', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'huzur_support_session_id': 'test-uuid-999',
      'huzur_support_short_code': 'deniz1',
      'huzur_support_user_name': 'Deniz',
      'huzur_support_status': 'active',
      'huzur_support_privacy_consent': true,
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HuzurLiveSupportSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Cam tasarım bileşenleri ve başlık kontrolü
    expect(find.text('Huzur Canlı Destek'), findsOneWidget);
    expect(find.textContaining('Liquid Glass'), findsNothing);
    expect(find.textContaining('V1.0'), findsNothing);
    expect(find.byType(GlassContainer), findsWidgets);
    expect(find.byType(EgeDenizDeveloperAvatar), findsWidgets);
    expect(find.textContaining('deniz1'), findsWidgets);

    // Görüşmeyi bitirip Değerlendirme ekranına geçiş
    await tester.tap(find.text('Bitir'));
    await tester.pumpAndSettle();

    expect(find.text('Görüşmeyi Değerlendirin'), findsOneWidget);
    expect(find.text('Değerlendirmeyi Gönder'), findsOneWidget);

    // Değerlendirmeyi gönderdikten sonra oturumun tamamen temizlenmesi
    await tester.tap(find.text('Değerlendirmeyi Gönder'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('huzur_support_session_id'), isNull);
  });

  test('Kutsal Metinler ve 99 Esmaül Hüsna bütünlük kontrolü', () {
    expect(OfflineSacredRepository.getAllSurahMetadata().length, equals(114));
    expect(OfflineSacredRepository.kAll99EsmaulHusna.length, equals(99));
    expect(OfflineSacredRepository.kHourlyShortVerses.length, equals(40));
  });
}
