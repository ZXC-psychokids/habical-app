import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/create_habit/create_habit_cubit.dart';
import '../../cubits/create_habit/create_habit_state.dart';

class CreateHabitScreen extends StatelessWidget {
  const CreateHabitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateHabitCubit(),
      child: const _CreateHabitView(),
    );
  }
}

class _CreateHabitView extends StatelessWidget {
  const _CreateHabitView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateHabitCubit, CreateHabitState>(
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
          context.read<CreateHabitCubit>().clearError();
        }

        final submission = state.submission;
        if (submission != null) {
          Navigator.of(context).pop(submission);
          context.read<CreateHabitCubit>().clearSubmission();
        }
      },
      builder: (context, state) {
        final cubit = context.read<CreateHabitCubit>();
        return Scaffold(
          appBar: AppBar(title: const Text('Новая привычка')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Название',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const ValueKey('habit-name-field'),
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onChanged: cubit.updateName,
                    onSubmitted: (_) => cubit.submit(),
                    decoration: InputDecoration(
                      hintText: 'Введите название привычки',
                      filled: true,
                      fillColor: const Color(0xFFF3F3F3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0x1A000000)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0x1A000000)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Дата начала',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      key: const ValueKey('habit-start-date-button'),
                      onPressed: () => _pickDate(context, state.startDate),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F3F3),
                        side: const BorderSide(color: Color(0x1A000000)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatDate(state.startDate),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: state.isSaving ? null : cubit.submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBEBEBE),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: state.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Сохранить',
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

  Future<void> _pickDate(BuildContext context, DateTime selectedDate) async {
    final cubit = context.read<CreateHabitCubit>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );

    if (picked != null) {
      cubit.updateStartDate(picked);
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
