import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/api_client.dart';
import '../repositories/api_friends_repository.dart';
import '../repositories/api_habits_repository.dart';
import '../repositories/api_home_repository.dart';
import '../repositories/friends_repository.dart';
import '../repositories/habits_repository.dart';
import '../repositories/home_repository.dart';
import '../repositories/hybrid_friends_repository.dart';
import '../repositories/hybrid_habits_repository.dart';
import '../repositories/hybrid_home_repository.dart';
import '../repositories/in_memory_app_store.dart';
import '../screens/root_screen.dart';
import '../services/api_session_bootstrapper.dart';

class HabicalApp extends StatefulWidget {
  const HabicalApp({super.key});

  @override
  State<HabicalApp> createState() => _HabicalAppState();
}

class _HabicalAppState extends State<HabicalApp> {
  late final InMemoryAppStore store;
  late final ApiClient apiClient;
  late Future<String> _sessionFuture;

  @override
  void initState() {
    super.initState();
    store = InMemoryAppStore();
    apiClient = ApiClient();
    _sessionFuture = ApiSessionBootstrapper(apiClient: apiClient).ensureSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        final theme = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
          scaffoldBackgroundColor: const Color(0xFFF2F2F2),
          fontFamily: 'Cera Pro',
        );

        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Habical',
            theme: theme,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Habical',
            theme: theme,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Не удалось инициализировать сессию.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _sessionFuture = ApiSessionBootstrapper(
                              apiClient: apiClient,
                            ).ensureSession();
                          });
                        },
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final currentUserId = snapshot.data!;

        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ApiClient>.value(value: apiClient),
            RepositoryProvider<HabitsRepository>(
              create: (_) => HybridHabitsRepository(
                remoteRepository: ApiHabitsRepository(apiClient: apiClient),
                store: store,
              ),
            ),
            RepositoryProvider<FriendsRepository>(
              create: (_) => HybridFriendsRepository(
                remoteRepository: ApiFriendsRepository(apiClient: apiClient),
                store: store,
              ),
            ),
            RepositoryProvider<HomeRepository>(
              create: (_) => HybridHomeRepository(
                remoteRepository: ApiHomeRepository(apiClient: apiClient),
                store: store,
              ),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Habical',
            theme: theme,
            home: RootScreen(currentUserId: currentUserId),
          ),
        );
      },
    );
  }
}
