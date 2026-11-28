import 'package:flutter_test/flutter_test.dart';
import 'package:ilahi_tefekkur/core/models/v42_models.dart';
import 'package:ilahi_tefekkur/core/services/tasbih_session_service.dart';

void main() {
  group('TasbihSessionState', () {
    test('başlangıç durumu yükleniyor olarak tanımlanır', () {
      const state = TasbihSessionState();
      expect(state.isLoading, isTrue);
      expect(state.activeRecord, isNull);
      expect(state.loadError, isNull);
    });

    test('yüklenmiş kayıt aktif sayaç olarak sunulur', () {
      const record = TasbihRecord(
        id: 1,
        title: 'Sübhanallah',
        arabic: 'سُبْحَانَ ٱللَّهِ',
        count: 7,
        target: 33,
      );
      const state = TasbihSessionState(
        records: [record],
        isLoading: false,
      );

      expect(state.activeRecord?.title, 'Sübhanallah');
      expect(state.activeRecord?.count, 7);
      expect(state.isLoading, isFalse);
    });

    test('yükleme hatası açıkça temsil edilir ve temizlenebilir', () {
      const failed = TasbihSessionState(
        isLoading: false,
        loadError: 'Yerel kayıt okunamadı.',
      );
      final retried = failed.copyWith(isLoading: true, clearLoadError: true);

      expect(failed.loadError, isNotNull);
      expect(retried.loadError, isNull);
      expect(retried.isLoading, isTrue);
    });
  });
}
