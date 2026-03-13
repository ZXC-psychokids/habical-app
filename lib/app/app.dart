import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/habits_repository.dart';
import '../repositories/home_repository.dart';
import '../repositories/friends_repository.dart';
import '../repositories/in_memory_app_store.dart';
import '../screens/root_screen.dart';

class HabicalApp extends StatelessWidget {
  const HabicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = InMemoryAppStore();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<HabitsRepository>(
          create: (_) => InMemoryHabitsRepository(store: store),
        ),
        RepositoryProvider<HomeRepository>(
          create: (_) => InMemoryHomeRepository(store: store),
        ),
        RepositoryProvider<FriendsRepository>(
          create: (_) => InMemoryFriendsRepository(store: store),
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
