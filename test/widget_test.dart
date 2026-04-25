import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:habical/core/api_client.dart';
import 'package:habical/repositories/friends_repository.dart';
import 'package:habical/repositories/habits_repository.dart';
import 'package:habical/repositories/home_repository.dart';
import 'package:habical/repositories/in_memory_app_store.dart';
import 'package:habical/screens/home/home_screen.dart';
import 'package:habical/screens/root_screen.dart';
import 'package:habical/screens/settings/settings_screen.dart';

Widget _buildTestApp() {
  final store = InMemoryAppStore();
  final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:1');
  apiClient.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path == '/me') {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 'user_me',
                'email': 'demo@habical.local',
                'handle': 'demo_user',
                'avatarUrl': '',
                'createdAt': DateTime.now().toUtc().toIso8601String(),
              },
            ),
          );
          return;
        }
        if (options.path == '/me/settings') {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'timezone': 'Europe/Warsaw',
                'weekStartsOn': 1,
                'shareHabits': true,
                'shareCalendar': true,
                'shareNews': true,
                'notifyFriendRequests': true,
                'notifyHabitReminders': true,
                'notifyFriendsNews': true,
              },
            ),
          );
          return;
        }
        handler.next(options);
      },
    ),
  );

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ApiClient>.value(value: apiClient),
      RepositoryProvider<HomeRepository>(
        create: (_) => InMemoryHomeRepository(store: store),
      ),
      RepositoryProvider<HabitsRepository>(
        create: (_) => InMemoryHabitsRepository(store: store),
      ),
      RepositoryProvider<FriendsRepository>(
        create: (_) => InMemoryFriendsRepository(store: store),
      ),
    ],
    child: const MaterialApp(
      home: RootScreen(currentUserId: 'user_me'),
    ),
  );
}

void main() {
  testWidgets('app starts on home screen with bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
  });

  testWidgets('settings screen opens and renders form controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
