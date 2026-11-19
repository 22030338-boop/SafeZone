
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safezone/main.dart';

void main() {
  testWidgets('SafeZone inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SafeZoneApp(),
      ),
    );

    expect(find.text('SafeZone'), findsOneWidget);
    expect(find.text('Bienvenido a SafeZone'), findsOneWidget);
  });
}
