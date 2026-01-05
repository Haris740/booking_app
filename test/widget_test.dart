import 'package:flutter_test/flutter_test.dart';

import 'package:booking_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the welcome screen is shown
    expect(find.text('Doctor Booking'), findsOneWidget);
  });
}
