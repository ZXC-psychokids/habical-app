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
import '../repositories/hybrid_habits_repository.dart';
import '../repositories/hybrid_home_repository.dart';
import '../repositories/in_memory_app_store.dart';
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
  late final InMemoryAppStore _store;

  @override
  void initState() {
    super.initState();
    _store = InMemoryAppStore();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>.value(value: widget.apiClient),
        RepositoryProvider<SessionService>.value(value: widget.sessionService),
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
          create: (_) => HybridHabitsRepository(
            remoteRepository: ApiHabitsRepository(apiClient: widget.apiClient),
            store: _store,
          ),
        ),
        RepositoryProvider<FriendsRepository>(
          create: (_) => ApiFriendsRepository(apiClient: widget.apiClient),
        ),
        RepositoryProvider<HomeRepository>(
          create: (_) => HybridHomeRepository(
            remoteRepository: ApiHomeRepository(apiClient: widget.apiClient),
            store: _store,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Habical',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
          scaffoldBackgroundColor: const Color(0xFFF2F2F2),
          fontFamily: 'Cera Pro',
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
