import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../widgets/appear_animations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  String _email = '';
  String _handle = '';
  String _timezone = 'Europe/Warsaw';
  int _weekStartsOn = 1;
  bool _shareHabits = true;
  bool _shareCalendar = true;
  bool _shareNews = true;
  bool _notifyFriendRequests = true;
  bool _notifyHabitReminders = true;
  bool _notifyFriendsNews = true;

  late final TextEditingController _timezoneController;

  @override
  void initState() {
    super.initState();
    _timezoneController = TextEditingController(text: _timezone);
    _loadData();
  }

  @override
  void dispose() {
    _timezoneController.dispose();
    super.dispose();
  }

  ApiClient get _apiClient => RepositoryProvider.of<ApiClient>(context);

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiClient.dio.get('/me'),
        _apiClient.dio.get('/me/settings'),
      ]);
      final meRaw = results[0].data;
      final settingsRaw = results[1].data;

      if (meRaw is! Map || settingsRaw is! Map) {
        throw StateError('Некорректный формат настроек.');
      }

      final me = Map<String, dynamic>.from(meRaw);
      final settings = Map<String, dynamic>.from(settingsRaw);

      if (!mounted) {
        return;
      }
      setState(() {
        _email = (me['email'] as String?)?.trim() ?? '';
        _handle = (me['handle'] as String?)?.trim() ?? '';
        _timezone = (settings['timezone'] as String?)?.trim() ?? _timezone;
        _weekStartsOn = (settings['weekStartsOn'] as int?) ?? _weekStartsOn;
        _shareHabits = (settings['shareHabits'] as bool?) ?? _shareHabits;
        _shareCalendar =
            (settings['shareCalendar'] as bool?) ?? _shareCalendar;
        _shareNews = (settings['shareNews'] as bool?) ?? _shareNews;
        _notifyFriendRequests =
            (settings['notifyFriendRequests'] as bool?) ??
            _notifyFriendRequests;
        _notifyHabitReminders =
            (settings['notifyHabitReminders'] as bool?) ??
            _notifyHabitReminders;
        _notifyFriendsNews =
            (settings['notifyFriendsNews'] as bool?) ?? _notifyFriendsNews;
        _timezoneController.text = _timezone;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = 'Не удалось загрузить настройки.';
      });
    }
  }

  Future<void> _savePrivacy({
    required bool shareHabits,
    required bool shareCalendar,
    required bool shareNews,
  }) async {
    await _apiClient.dio.patch(
      '/me/settings/privacy',
      data: {
        'shareHabits': shareHabits,
        'shareCalendar': shareCalendar,
        'shareNews': shareNews,
      },
    );
  }

  Future<void> _saveNotifications({
    required bool notifyFriendRequests,
    required bool notifyHabitReminders,
    required bool notifyFriendsNews,
  }) async {
    await _apiClient.dio.patch(
      '/me/settings/notifications',
      data: {
        'notifyFriendRequests': notifyFriendRequests,
        'notifyHabitReminders': notifyHabitReminders,
        'notifyFriendsNews': notifyFriendsNews,
      },
    );
  }

  Future<void> _saveCalendar({
    required String timezone,
    required int weekStartsOn,
  }) async {
    await _apiClient.dio.patch(
      '/me/settings/calendar',
      data: {
        'timezone': timezone,
        'weekStartsOn': weekStartsOn,
      },
    );
  }

  Future<void> _runSave(Future<void> Function() action) async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await action();
    } on DioException catch (error) {
      final message = _extractErrorMessage(error);
      if (!mounted) {
        return;
      }
      setState(() {
        _error = message;
      });
      await _loadData();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Не удалось сохранить настройки.';
      });
      await _loadData();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Ошибка сохранения настроек.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      body: SafeArea(
        child: ScreenAppear(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                color: const Color(0xFF0277BD),
                child: const Text(
                  'Настройки',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                          children: [
                            _SectionCard(
                              title: 'Профиль',
                              children: [
                                _InfoRow(title: 'Хендл', value: _handle),
                                const SizedBox(height: 8),
                                _InfoRow(title: 'Email', value: _email),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _SectionCard(
                              title: 'Приватность',
                              children: [
                                _SwitchRow(
                                  label: 'Показывать привычки',
                                  value: _shareHabits,
                                  enabled: !_isSaving,
                                  onChanged: (value) {
                                    setState(() => _shareHabits = value);
                                    _runSave(
                                      () => _savePrivacy(
                                        shareHabits: value,
                                        shareCalendar: _shareCalendar,
                                        shareNews: _shareNews,
                                      ),
                                    );
                                  },
                                ),
                                _SwitchRow(
                                  label: 'Показывать календарь',
                                  value: _shareCalendar,
                                  enabled: !_isSaving,
                                  onChanged: (value) {
                                    setState(() => _shareCalendar = value);
                                    _runSave(
                                      () => _savePrivacy(
                                        shareHabits: _shareHabits,
                                        shareCalendar: value,
                                        shareNews: _shareNews,
                                      ),
                                    );
                                  },
                                ),
                                _SwitchRow(
                                  label: 'Показывать новости',
                                  value: _shareNews,
                                  enabled: !_isSaving,
                                  onChanged: (value) {
                                    setState(() => _shareNews = value);
                                    _runSave(
                                      () => _savePrivacy(
                                        shareHabits: _shareHabits,
                                        shareCalendar: _shareCalendar,
                                        shareNews: value,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _SectionCard(
                              title: 'Уведомления',
                              children: [
                                _SwitchRow(
                                  label: 'Заявки в друзья',
                                  value: _notifyFriendRequests,
                                  enabled: !_isSaving,
                                  onChanged: (value) {
                                    setState(
                                      () => _notifyFriendRequests = value,
                                    );
                                    _runSave(
                                      () => _saveNotifications(
                                        notifyFriendRequests: value,
                                        notifyHabitReminders:
                                            _notifyHabitReminders,
                                        notifyFriendsNews: _notifyFriendsNews,
                                      ),
                                    );
                                  },
                                ),
                                _SwitchRow(
                                  label: 'Напоминания о привычках',
                                  value: _notifyHabitReminders,
                                  enabled: !_isSaving,
                                  onChanged: (value) {
                                    setState(
                                      () => _notifyHabitReminders = value,
                                    );
                                    _runSave(
                                      () => _saveNotifications(
                                        notifyFriendRequests:
                                            _notifyFriendRequests,
                                        notifyHabitReminders: value,
                                        notifyFriendsNews: _notifyFriendsNews,
                                      ),
                                    );
                                  },
                                ),
                                _SwitchRow(
                                  label: 'Новости друзей',
                                  value: _notifyFriendsNews,
                                  enabled: !_isSaving,
                                  onChanged: (value) {
                                    setState(() => _notifyFriendsNews = value);
                                    _runSave(
                                      () => _saveNotifications(
                                        notifyFriendRequests:
                                            _notifyFriendRequests,
                                        notifyHabitReminders:
                                            _notifyHabitReminders,
                                        notifyFriendsNews: value,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _SectionCard(
                              title: 'Календарь',
                              children: [
                                const Text(
                                  'Timezone',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4B4B4B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _timezoneController,
                                  enabled: !_isSaving,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text(
                                      'Первый день недели',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4B4B4B),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    DropdownButton<int>(
                                      value: _weekStartsOn,
                                      onChanged: _isSaving
                                          ? null
                                          : (value) {
                                              if (value == null) {
                                                return;
                                              }
                                              setState(
                                                () => _weekStartsOn = value,
                                              );
                                            },
                                      items: const [
                                        DropdownMenuItem(
                                          value: 1,
                                          child: Text('Понедельник'),
                                        ),
                                        DropdownMenuItem(
                                          value: 7,
                                          child: Text('Воскресенье'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: _isSaving
                                        ? null
                                        : () {
                                            final tz = _timezoneController.text
                                                .trim();
                                            setState(() => _timezone = tz);
                                            _runSave(
                                              () => _saveCalendar(
                                                timezone: tz,
                                                weekStartsOn: _weekStartsOn,
                                              ),
                                            );
                                          },
                                    child: const Text('Сохранить календарь'),
                                  ),
                                ),
                              ],
                            ),
                            if (_isSaving) ...[
                              const SizedBox(height: 12),
                              const LinearProgressIndicator(minHeight: 2),
                            ],
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Color(0xFFB42318),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4B4B4B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF222222),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF222222),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
