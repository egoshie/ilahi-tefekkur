import 'package:flutter_test/flutter_test.dart';
import 'package:ilahi_tefekkur/core/data/hourly_verses.g.dart';
import 'package:ilahi_tefekkur/core/services/offline_sacred_repository.dart';

void main() {
  test('Ana katalog 69 ayeti korur', () {
    expect(kHourlyShortVerseCatalog, hasLength(69));
    expect(OfflineSacredRepository.kHourlyShortVerses, hasLength(69));

    final keys = kHourlyShortVerseCatalog.map((verse) => verse.ayahKey).toSet();

    expect(keys, hasLength(69));
  });

  test('Widget kataloğu 27 benzersiz kısa ayet içerir', () {
    expect(kHourlyWidgetShortVerses, hasLength(27));

    final keys = kHourlyWidgetShortVerses.map((verse) => verse.ayahKey).toSet();

    expect(keys, hasLength(27));
    expect(keys, isNot(contains('25:63')));

    for (final verse in kHourlyWidgetShortVerses) {
      expect(
        verse.arabicShort.trim().split(RegExp(r'\s+')).length,
        lessThanOrEqualTo(4),
      );
      expect(
        verse.turkishShort.trim().split(RegExp(r'\s+')).length,
        lessThanOrEqualTo(4),
      );
    }
  });

  test('Widget kataloğu ana JSON seçim kuralıyla eşleşir', () {
    final eligible = kHourlyShortVerseCatalog.where((verse) {
      return verse.ayahKey != '25:63' &&
          verse.arabicShort.trim().split(RegExp(r'\s+')).length <= 4 &&
          verse.turkishShort.trim().split(RegExp(r'\s+')).length <= 4;
    }).toList();

    expect(
      eligible.map((verse) => verse.ayahKey).toList(),
      kHourlyWidgetShortVerses.map((verse) => verse.ayahKey).toList(),
    );
  });
}
