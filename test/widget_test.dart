import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dnb_plant_ai/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('DNB Plant AI home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const DnbApp());
    await tester.pumpAndSettle();
    expect(find.text('DNB Plant AI'), findsOneWidget);
    expect(find.text('دانا زبان گیاه شما'), findsOneWidget);
    expect(find.text('گیاهان من'), findsWidgets);
  });
  test('plant records receive distinct stable identifiers', () {
    final state = DnbState();
    final first = state.newPlantId();
    final second = state.newPlantId();
    expect(first, startsWith('DNB-'));
    expect(second, startsWith('DNB-'));
    expect(first, isNot(second));
  });

}
