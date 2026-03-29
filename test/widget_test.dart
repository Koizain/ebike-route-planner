import 'package:flutter_test/flutter_test.dart';
import 'package:ebike_route_planner/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EBikeApp());
    expect(find.text('eBike Route Planner'), findsOneWidget);
  });
}
