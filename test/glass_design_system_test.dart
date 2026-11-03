import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilahi_tefekkur/core/theme/glass_container.dart';

void main() {
  testWidgets('İçerik yüzeyi varsayılan olarak ekstra blur kullanmaz', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassContainer(
              child: Text('Huzur yüzeyi'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Huzur yüzeyi'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('Cam efekti açık kontrol BackdropFilter kullanır', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassContainer(
              enableBlur: true,
              blurSigma: 18,
              child: Text('Cam kontrol'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Cam kontrol'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('Etkileşimli yüzey dokunmayı işler', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassContainer(
              onTap: () => tapped = true,
              child: const Text('Dokun'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Dokun'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
