import 'package:flutter_test/flutter_test.dart';
import 'package:ilahi_tefekkur/core/services/notification_service.dart';

void main() {
  test('widget ayetleri dört kelimeyi aşmaz ve 27 kayıt benzersizdir', () {
    final service = NotificationAndWidgetService.instance;
    final verses = List.generate(
      27,
      (index) => service.getActiveHourlyVerse(offset: index),
    );

    expect(verses.map((verse) => verse.ayahKey).toSet(), hasLength(27));

    for (final verse in verses) {
      expect(verse.arabicShort.trim().split(RegExp(r'\\s+')).length,
          lessThanOrEqualTo(4));
      expect(verse.turkishShort.trim().split(RegExp(r'\\s+')).length,
          lessThanOrEqualTo(4));
    }
  });

  test('elle yenileme bir sonraki seçilmiş ayeti getirir', () {
    final service = NotificationAndWidgetService.instance;
    final current = service.getActiveHourlyVerse(offset: 0);
    final next = service.getActiveHourlyVerse(offset: 1);
    expect(next.ayahKey, isNot(current.ayahKey));
  });
}
