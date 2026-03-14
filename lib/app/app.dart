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

class HabicalApp extends StatefulWidget {
  const HabicalApp({super.key});

  @override
  State<HabicalApp> createState() => _HabicalAppState();
}

class _HabicalAppState extends State<HabicalApp> {
  late final InMemoryAppStore store;
  late final ApiClient apiClient;

  @override
  void initState() {
    super.initState();
    store = InMemoryAppStore();
    apiClient = ApiClient();
  }

  @override
  Widget build(BuildContext context) {
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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
          scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        ),
        home: const RootScreen(),
      ),
    );
  }
}