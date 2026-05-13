import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../repositories/habits_repository.dart';

class SharedHabitDetailsScreen extends StatefulWidget {
  const SharedHabitDetailsScreen({
    super.key,
    required this.sharedHabitPairId,
    required this.repository,
  });

  final String sharedHabitPairId;
  final HabitsRepository repository;

  @override
  State<SharedHabitDetailsScreen> createState() => _SharedHabitDetailsScreenState();
}

class _SharedHabitDetailsScreenState extends State<SharedHabitDetailsScreen> {
  bool _isLoading = true;
  bool _isReminding = false;
  String? _error;
  SharedHabitDetails? _details;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final details = await widget.repository.fetchSharedHabitDetails(
        sharedHabitPairId: widget.sharedHabitPairId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Не удалось загрузить совместную привычку.';
        _isLoading = false;
      });
    }
  }

  Future<void> _remind() async {
    final details = _details;
    if (details == null || details.todayTaskId == null) {
      return;
    }
    setState(() {
      _isReminding = true;
    });
    try {
      final result = await widget.repository.remindSharedHabit(
        sharedHabitPairId: details.sharedHabitPairId,
        taskId: details.todayTaskId!,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      await _load();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось отправить напоминание.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isReminding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = _details;
    final canRemind = details != null &&
        details.todayTaskId != null &&
        !details.friendCompletedToday &&
        !_isReminding;

    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(title: const Text('Совместная привычка')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFB42318)),
                ),
              ),
            if (details != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0x15000000)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _hexToColor(details.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            details.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${details.streakDays} дн. подряд',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8A8A8A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0x15000000)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Вы: ${details.you.handle}'),
                    Text('Друг: ${details.friend.handle}'),
                    const SizedBox(height: 8),
                    Text('Вы выполнили сегодня: ${details.youCompletedToday ? 'да' : 'нет'}'),
                    Text(
                      'Друг выполнил сегодня: ${details.friendCompletedToday ? 'да' : 'нет'}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: canRemind ? _remind : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0277BD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isReminding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Напомнить другу',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Color _hexToColor(String rawValue) {
  var value = rawValue.trim();
  if (value.startsWith('#')) {
    value = value.substring(1);
  }
  if (value.length == 6) {
    value = 'FF$value';
  }
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) {
    return const Color(0xFFC7C7CC);
  }
  return Color(parsed);
}
