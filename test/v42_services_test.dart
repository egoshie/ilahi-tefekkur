import 'package:flutter_test/flutter_test.dart';
import 'package:ilahi_tefekkur/core/services/offline_sacred_repository.dart';

void main() {
  test('TurkishSearchNormalizer şapkalı ve Türkçe karakterleri doğru normalize eder', () {
    expect(TurkishSearchNormalizer.matches('Duhâ Sûresi', 'duha'), isTrue);
    expect(TurkishSearchNormalizer.matches('Fâtiha Sûresi', 'fatiha'), isTrue);
    expect(TurkishSearchNormalizer.matches('Yâsîn Sûresi', 'yasin'), isTrue);
    expect(TurkishSearchNormalizer.matches('İnşirâh Sûresi', 'insirah'), isTrue);
    expect(TurkishSearchNormalizer.matches('Âl-i İmrân Sûresi', 'ali imran'), isTrue);
  });

  test('OfflineSacredRepository veri bütünlüğü (114 Sure, 99 Esma, 40 Kısa Ayet)', () {
    final surahs = OfflineSacredRepository.getAllSurahMetadata();
    expect(surahs.length, 114);
    expect(OfflineSacredRepository.kAll99EsmaulHusna.length, 99);
    expect(OfflineSacredRepository.kHourlyShortVerses.length, 40);
  });
}
