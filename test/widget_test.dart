import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilahi_tefekkur/core/theme/glass_container.dart';
import 'package:ilahi_tefekkur/core/services/notification_service.dart';
import 'package:ilahi_tefekkur/features/paywall/huzur_live_support.dart';
import 'package:ilahi_tefekkur/features/paywall/huzur_live_support_api.dart';

void main() {
  test('Telegram kalıcı kısa kod üretimi (deniz1, ege1) ve bildirim başlığı testi', () {
    expect(
      HuzurTelegramShortCodeHelper.buildShortCode(fullName: 'Deniz Yılmaz', sequenceNumber: 1),
      equals('deniz1'),
    );
    expect(
      HuzurTelegramShortCodeHelper.buildShortCode(fullName: 'Ege Deniz', sequenceNumber: 2),
      equals('ege2'),
    );
    expect(
      resolveSupportNotificationTitle(senderRole: 'admin'),
      equals('Ege size yazdı'),
    );
  });

  testWidgets('Liquid Glass, Huzur AI Hilal Avatarı ve Ege Deniz Geliştirici Avatarı render testi',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassContainer(
            goldAccentBorder: true,
            emeraldGlow: true,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                HuzurAiCrescentAvatar(size: 38),
                EgeDenizDeveloperAvatar(size: 40),
                Text(HuzurAiGuideData.optWhatIsHuzur),
                Text(HuzurAiGuideData.optWhatDoesHuzurOffer),
                Text(HuzurAiGuideData.optConnectDeveloper),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GlassContainer), findsOneWidget);
    expect(find.byType(HuzurAiCrescentAvatar), findsOneWidget);
    expect(find.byType(EgeDenizDeveloperAvatar), findsOneWidget);
    expect(find.text('Huzur nedir?'), findsOneWidget);
    expect(find.text('Huzur bizlere neler sunuyor?'), findsOneWidget);
    expect(find.text('Geliştiriciyle sohbet etmek istiyorum.'), findsOneWidget);
  });
}
