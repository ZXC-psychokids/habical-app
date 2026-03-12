import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/create_habit/create_habit_state.dart';
import '../../cubits/habits/habits_cubit.dart';
import '../../cubits/habits/habits_state.dart';
import '../../models/habit_list_item.dart';
import '../../repositories/habits_repository.dart';
import 'create_habit_screen.dart';
import 'habit_details_screen.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({
    super.key,
    this.currentUserId = 'user_me',
    HabitsRepository? repository,
  }) : _repository = repository;

  final String currentUserId;
  final HabitsRepository? _repository;

  @override
  Widget build(BuildContext context) {
    final repository =
        _repository ?? RepositoryProvider.of<HabitsRepository>(context);

    return BlocProvider(
      create: (_) =>
          HabitsCubit(repository: repository, userId: currentUserId)
            ..loadHabits(),
      child: const _HabitsView(),
    );
  }
}

class _HabitsView extends StatelessWidget {
  const _HabitsView();

  Future<void> _openHabit(BuildContext context, HabitListItem item) async {
    final cubit = context.read<HabitsCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HabitDetailsScreen(
          habitId: item.habit.id,
          repository: cubit.repository,
        ),
      ),
    );
    await cubit.loadHabits();
  }

  Future<void> _openCreateHabit(BuildContext context) async {
    final cubit = context.read<HabitsCubit>();
    final submission = await Navigator.of(context).push<CreateHabitSubmission>(
      MaterialPageRoute<CreateHabitSubmission>(
        builder: (_) => const CreateHabitScreen(),
      ),
    );

    if (submission == null) {
      return;
    }
    await cubit.addHabit(
      title: submission.title,
      startDate: submission.startDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HabitsCubit, HabitsState>(
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
          context.read<HabitsCubit>().clearError();
        }
      },
      builder: (context, state) {
        final isInitialLoad =
            state.status == HabitsStatus.loading && state.items.isEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFEDEDED),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => context.read<HabitsCubit>().loadHabits(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                children: [
                  const Text(
                    'Habits',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  if (isInitialLoad)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.items.isEmpty)
                    const _EmptyHabitsCard()
                  else
                    ...state.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _HabitCard(
                          item: item,
                          onTap: () => _openHabit(context, item),
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _openCreateHabit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBEBEBE),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Add new habit',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.item, required this.onTap});

  final HabitListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F3F3),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x1A000000)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.habit.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.local_fire_department, size: 26),
                  Text(
                    item.streakLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHabitsCard extends StatelessWidget {
  const _EmptyHabitsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1A000000)),
      ),
      child: const Text('No habits yet. Tap the button below to add one.'),
    );
  }
}
