import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/habits_repository.dart';
import '../repositories/home_repository.dart';
import '../screens/home/home_screen.dart';

class HabicalApp extends StatelessWidget {
  const HabicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<HabitsRepository>(
          create: (_) => InMemoryHabitsRepository(),
        ),
        RepositoryProvider<HomeRepository>(
          create: (_) => InMemoryHomeRepository(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Habical',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
          scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}