import 'package:flutter_test/flutter_test.dart';
import 'package:color_match/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ColorMatchApp());
    expect(find.byType(ColorMatchApp), findsOneWidget);
  });
}
