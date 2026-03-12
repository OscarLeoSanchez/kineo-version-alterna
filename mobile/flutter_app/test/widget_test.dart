import 'package:flutter_test/flutter_test.dart';
import 'package:kineo_coach/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders app bootstrap shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KineoCoachApp());

    expect(find.byType(KineoCoachApp), findsOneWidget);
  });
}
