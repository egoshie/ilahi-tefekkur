import 'package:flutter_test/flutter_test.dart';
import 'package:ilahi_tefekkur/core/services/quran_background_audio_service.dart';

void main() {
  group('Quran audio Premium access', () {
    test('Ücretsiz kullanıcı ilk üç tamamlanmış sureye kadar dinleyebilir', () {
      for (var count = 0; count < 3; count++) {
        expect(
          QuranBackgroundAudioNotifier.canStartPlaylist(
            isPremium: false,
            completedSurahCount: count,
          ),
          isTrue,
        );
      }
    });

    test('Üç tamamlanmış sureden sonra ücretsiz erişim kapanır', () {
      expect(
        QuranBackgroundAudioNotifier.canStartPlaylist(
          isPremium: false,
          completedSurahCount: 3,
        ),
        isFalse,
      );
    });

    test('Premium kullanıcı için dinleme sınırı yoktur', () {
      expect(
        QuranBackgroundAudioNotifier.canStartPlaylist(
          isPremium: true,
          completedSurahCount: 10000,
        ),
        isTrue,
      );
    });
  });
}
