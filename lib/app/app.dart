import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/api_client.dart';
import '../repositories/api_friends_repository.dart';
import '../repositories/api_habits_repository.dart';
import '../repositories/api_home_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/calendar_repository.dart';
import '../repositories/friends_repository.dart';
import '../repositories/habits_repository.dart';
import '../repositories/home_repository.dart';
import '../repositories/settings_repository.dart';
import '../screens/auth/auth_gate_screen.dart';
import '../services/session_service.dart';

class HabicalApp extends StatefulWidget {
  const HabicalApp({
    super.key,
    required this.apiClient,
    required this.sessionService,
  });

  final ApiClient apiClient;
  final SessionService sessionService;

  @override
  State<HabicalApp> createState() => _HabicalAppState();
}

class _HabicalAppState extends State<HabicalApp> {
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>.value(value: widget.apiClient),
        RepositoryProvider<AuthRepository>(
          create: (_) => AuthRepository(
            apiClient: widget.apiClient,
            sessionService: widget.sessionService,
          ),
        ),
        RepositoryProvider<SettingsRepository>(
          create: (_) => SettingsRepository(apiClient: widget.apiClient),
        ),
        RepositoryProvider<CalendarRepository>(
          create: (_) => ApiCalendarRepository(apiClient: widget.apiClient),
        ),
        RepositoryProvider<HabitsRepository>(
          create: (_) => ApiHabitsRepository(apiClient: widget.apiClient),
        ),
        RepositoryProvider<FriendsRepository>(
          create: (_) => ApiFriendsRepository(apiClient: widget.apiClient),
        ),
        RepositoryProvider<HomeRepository>(
          create: (_) => ApiHomeRepository(apiClient: widget.apiClient),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Habical',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0277BC),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF2F2F2),
          fontFamily: 'Cera Pro',
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Color(0xFF0277BC),
            selectionColor: Color(0x3321A1F1),
            selectionHandleColor: Color(0xFF0277BC),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color(0xFF0277BC),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: const Color(0xFFF3F3F3),
            contentTextStyle: const TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            behavior: SnackBarBehavior.floating,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFFB5B5B5)),
            ),
          ),
        ),
        home: Builder(
          builder: (context) => AuthGateScreen(
            authRepository: context.read<AuthRepository>(),
            sessionService: widget.sessionService,
          ),
        ),
      ),
    );
  }
}
