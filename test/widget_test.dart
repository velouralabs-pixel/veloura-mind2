import 'package:flutter_test/flutter_test.dart';
import 'package:veloura_mind/main.dart';

void main() {
  testWidgets('Veloura Mind loads welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const VelouraMindApp());

    expect(find.text('Veloura Mind'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}