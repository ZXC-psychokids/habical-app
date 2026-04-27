import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/auth_repository.dart';
import '../../repositories/settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _emailController = TextEditingController();
  final _handleController = TextEditingController();
  final _timezoneController = TextEditingController();

  bool _shareHabits = true;
  bool _shareCalendar = true;
  bool _shareNews = true;

  bool _notifyFriendRequests = true;
  bool _notifyHabitReminders = true;
  bool _notifyFriendsNews = true;

  int _weekStartsOn = 1;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  SettingsRepository get _settingsRepository =>
      RepositoryProvider.of<SettingsRepository>(context);

  AuthRepository get _authRepository =>
      RepositoryProvider.of<AuthRepository>(context);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _handleController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _settingsRepository.fetchProfileAndSettings();
      if (!mounted) {
        return;
      }
      setState(() {
        _emailController.text = data.profile.email;
        _handleController.text = data.profile.handle;
        _timezoneController.text = data.settings.timezone;
        _shareHabits = data.settings.shareHabits;
        _shareCalendar = data.settings.shareCalendar;
        _shareNews = data.settings.shareNews;
        _notifyFriendRequests = data.settings.notifyFriendRequests;
        _notifyHabitReminders = data.settings.notifyHabitReminders;
        _notifyFriendsNews = data.settings.notifyFriendsNews;
        _weekStartsOn = data.settings.weekStartsOn;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = 'Failed to load profile/settings.';
      });
    }
  }

  Future<void> _saveProfile() async {
    await _runSave(
      () => _settingsRepository.updateProfile(
        email: _emailController.text,
        handle: _handleController.text,
      ),
      successMessage: 'Profile updated.',
    );
  }

  Future<void> _savePrivacy() async {
    await _runSave(
      () => _settingsRepository.updatePrivacy(
        shareHabits: _shareHabits,
        shareCalendar: _shareCalendar,
        shareNews: _shareNews,
      ),
      successMessage: 'Privacy settings updated.',
    );
  }

  Future<void> _saveNotifications() async {
    await _runSave(
      () => _settingsRepository.updateNotifications(
        notifyFriendRequests: _notifyFriendRequests,
        notifyHabitReminders: _notifyHabitReminders,
        notifyFriendsNews: _notifyFriendsNews,
      ),
      successMessage: 'Notification settings updated.',
    );
  }

  Future<void> _saveCalendar() async {
    await _runSave(
      () => _settingsRepository.updateCalendarSettings(
        timezone: _timezoneController.text,
        weekStartsOn: _weekStartsOn,
      ),
      successMessage: 'Calendar settings updated.',
    );
  }

  Future<void> _runSave(
    Future<dynamic> Function() action, {
    required String successMessage,
  }) async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to save changes.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _runSave(
      () => _authRepository.logout(),
      successMessage: 'Logged out.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (!_isLoading) ...[
              _ProfileCard(
                emailController: _emailController,
                handleController: _handleController,
                onSave: _isSaving ? null : _saveProfile,
              ),
              const SizedBox(height: 12),
              _PrivacyCard(
                shareHabits: _shareHabits,
                shareCalendar: _shareCalendar,
                shareNews: _shareNews,
                onShareHabitsChanged: (value) => setState(() => _shareHabits = value),
                onShareCalendarChanged: (value) =>
                    setState(() => _shareCalendar = value),
                onShareNewsChanged: (value) => setState(() => _shareNews = value),
                onSave: _isSaving ? null : _savePrivacy,
              ),
              const SizedBox(height: 12),
              _NotificationsCard(
                notifyFriendRequests: _notifyFriendRequests,
                notifyHabitReminders: _notifyHabitReminders,
                notifyFriendsNews: _notifyFriendsNews,
                onNotifyFriendRequestsChanged: (value) =>
                    setState(() => _notifyFriendRequests = value),
                onNotifyHabitRemindersChanged: (value) =>
                    setState(() => _notifyHabitReminders = value),
                onNotifyFriendsNewsChanged: (value) =>
                    setState(() => _notifyFriendsNews = value),
                onSave: _isSaving ? null : _saveNotifications,
              ),
              const SizedBox(height: 12),
              _CalendarCard(
                timezoneController: _timezoneController,
                weekStartsOn: _weekStartsOn,
                onWeekStartsOnChanged: (value) =>
                    setState(() => _weekStartsOn = value),
                onSave: _isSaving ? null : _saveCalendar,
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _isSaving ? null : _logout,
                child: const Text('Logout'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.emailController,
    required this.handleController,
    required this.onSave,
  });

  final TextEditingController emailController;
  final TextEditingController handleController;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const _CardTitle('Profile'),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: handleController,
              decoration: const InputDecoration(
                labelText: 'Handle',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onSave,
                child: const Text('Save profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({
    required this.shareHabits,
    required this.shareCalendar,
    required this.shareNews,
    required this.onShareHabitsChanged,
    required this.onShareCalendarChanged,
    required this.onShareNewsChanged,
    required this.onSave,
  });

  final bool shareHabits;
  final bool shareCalendar;
  final bool shareNews;
  final ValueChanged<bool> onShareHabitsChanged;
  final ValueChanged<bool> onShareCalendarChanged;
  final ValueChanged<bool> onShareNewsChanged;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const _CardTitle('Privacy'),
            SwitchListTile(
              value: shareHabits,
              onChanged: onShareHabitsChanged,
              title: const Text('Share habits'),
            ),
            SwitchListTile(
              value: shareCalendar,
              onChanged: onShareCalendarChanged,
              title: const Text('Share calendar'),
            ),
            SwitchListTile(
              value: shareNews,
              onChanged: onShareNewsChanged,
              title: const Text('Share news'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onSave,
                child: const Text('Save privacy'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard({
    required this.notifyFriendRequests,
    required this.notifyHabitReminders,
    required this.notifyFriendsNews,
    required this.onNotifyFriendRequestsChanged,
    required this.onNotifyHabitRemindersChanged,
    required this.onNotifyFriendsNewsChanged,
    required this.onSave,
  });

  final bool notifyFriendRequests;
  final bool notifyHabitReminders;
  final bool notifyFriendsNews;
  final ValueChanged<bool> onNotifyFriendRequestsChanged;
  final ValueChanged<bool> onNotifyHabitRemindersChanged;
  final ValueChanged<bool> onNotifyFriendsNewsChanged;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const _CardTitle('Notifications'),
            SwitchListTile(
              value: notifyFriendRequests,
              onChanged: onNotifyFriendRequestsChanged,
              title: const Text('Friend requests'),
            ),
            SwitchListTile(
              value: notifyHabitReminders,
              onChanged: onNotifyHabitRemindersChanged,
              title: const Text('Habit reminders'),
            ),
            SwitchListTile(
              value: notifyFriendsNews,
              onChanged: onNotifyFriendsNewsChanged,
              title: const Text('Friends feed'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onSave,
                child: const Text('Save notifications'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.timezoneController,
    required this.weekStartsOn,
    required this.onWeekStartsOnChanged,
    required this.onSave,
  });

  final TextEditingController timezoneController;
  final int weekStartsOn;
  final ValueChanged<int> onWeekStartsOnChanged;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const _CardTitle('Calendar'),
            TextField(
              controller: timezoneController,
              decoration: const InputDecoration(
                labelText: 'Timezone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: weekStartsOn,
              decoration: const InputDecoration(
                labelText: 'Week starts on',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Monday (1)')),
                DropdownMenuItem(value: 7, child: Text('Sunday (7)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onWeekStartsOnChanged(value);
                }
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onSave,
                child: const Text('Save calendar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }
}
