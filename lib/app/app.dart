import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/habits_repository.dart';
import '../screens/habits/habits_screen.dart';

class HabicalApp extends StatelessWidget {
  const HabicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<HabitsRepository>(
      create: (_) => InMemoryHabitsRepository(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Habical',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
          scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        ),
        home: const HabitsScreen(),
      ),
    );
  }
}
