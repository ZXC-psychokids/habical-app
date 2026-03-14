import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habical/app/app.dart';
import 'package:habical/screens/home/home_screen.dart';
import 'package:habical/screens/settings/settings_screen.dart';

void main() {
  testWidgets('app starts on home screen with bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HabicalApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(Checkbox), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
  });

  testWidgets('settings screen shows editable sections placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HabicalApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Настройки').last);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Имя пользователя'), findsOneWidget);
    expect(find.text('Тема'), findsOneWidget);
    expect(find.text('Язык'), findsOneWidget);
    expect(find.text('Выйти из аккаунта'), findsNothing);
  });
}
