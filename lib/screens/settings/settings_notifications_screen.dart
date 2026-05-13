import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/settings_repository.dart';
import 'settings_ui_tokens.dart';

class SettingsNotificationsScreen extends StatefulWidget {
  const SettingsNotificationsScreen({super.key});

  @override
  State<SettingsNotificationsScreen> createState() =>
      _SettingsNotificationsScreenState();
}

class _SettingsNotificationsScreenState
    extends State<SettingsNotificationsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  bool _friendRequests = true;
  bool _habitReminders = true;
  bool _friendsNews = true;

  SettingsRepository get _settingsRepository => context.read<SettingsRepository>();
  bool get _allEnabled => _friendRequests && _habitReminders && _friendsNews;

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
      final data = await _settingsRepository.fetchProfileAndSettings();
      if (!mounted) {
        return;
      }
      setState(() {
        _friendRequests = data.settings.notifyFriendRequests;
        _habitReminders = data.settings.notifyHabitReminders;
        _friendsNews = data.settings.notifyFriendsNews;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Не удалось загрузить настройки.';
        _isLoading = false;
      });
    }
  }

  Future<void> _save({
    bool? friendRequests,
    bool? habitReminders,
    bool? friendsNews,
  }) async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final updated = await _settingsRepository.updateNotifications(
        notifyFriendRequests: friendRequests ?? _friendRequests,
        notifyHabitReminders: habitReminders ?? _habitReminders,
        notifyFriendsNews: friendsNews ?? _friendsNews,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _friendRequests = updated.notifyFriendRequests;
        _habitReminders = updated.notifyHabitReminders;
        _friendsNews = updated.notifyFriendsNews;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Не удалось сохранить изменения.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _toggleAll(bool value) async {
    setState(() {
      _friendRequests = value;
      _habitReminders = value;
      _friendsNews = value;
    });
    await _save(
      friendRequests: value,
      habitReminders: value,
      friendsNews: value,
    );
  }

  Future<void> _toggleFriendRequests(bool value) async {
    setState(() => _friendRequests = value);
    await _save(friendRequests: value);
  }

  Future<void> _toggleHabitReminders(bool value) async {
    setState(() => _habitReminders = value);
    await _save(habitReminders: value);
  }

  Future<void> _toggleFriendsNews(bool value) async {
    setState(() => _friendsNews = value);
    await _save(friendsNews: value);
  }

  @override
  Widget build(BuildContext context) {
    final controlsDisabled = _isSaving || _isLoading;

    return Scaffold(
      backgroundColor: SettingsUiTokens.screenBackground,
      body: SafeArea(
        child: ListView(
          padding: SettingsUiTokens.pagePadding,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 22,
                    color: SettingsUiTokens.accentBlue,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                  splashRadius: 18,
                  tooltip: '\u041d\u0430\u0437\u0430\u0434',
                ),
                const SizedBox(width: 8),
                const Text('\u0423\u0432\u0435\u0434\u043e\u043c\u043b\u0435\u043d\u0438\u044f', style: TextStyle(fontSize: 32, height: 1.08, fontWeight: FontWeight.w700, color: SettingsUiTokens.accentBlue)),
              ],
            ),
            const SizedBox(height: 35),
            Container(
              decoration: const BoxDecoration(
                color: SettingsUiTokens.cardBackground,
                borderRadius: SettingsUiTokens.cardRadius,
                boxShadow: [SettingsUiTokens.cardShadow],
              ),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                children: [
                  _NotificationRow(
                    title: 'Все уведомления',
                    height: 30,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    textColor: SettingsUiTokens.primaryText,
                    value: _allEnabled,
                    enabled: !controlsDisabled,
                    onChanged: _toggleAll,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 8),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: SettingsUiTokens.divider,
                    ),
                  ),
                  _NotificationRow(
                    title: 'Заявки в друзья',
                    height: 20,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    textColor: _friendRequests
                        ? SettingsUiTokens.primaryText
                        : SettingsUiTokens.mutedText,
                    value: _friendRequests,
                    enabled: !controlsDisabled,
                    onChanged: _toggleFriendRequests,
                  ),
                  const SizedBox(height: 8),
                  _NotificationRow(
                    title: 'Напоминание о привычке',
                    height: 20,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    textColor: _habitReminders
                        ? SettingsUiTokens.primaryText
                        : SettingsUiTokens.mutedText,
                    value: _habitReminders,
                    enabled: !controlsDisabled,
                    onChanged: _toggleHabitReminders,
                  ),
                  const SizedBox(height: 8),
                  _NotificationRow(
                    title: 'Новости друзей',
                    height: 20,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    textColor: _friendsNews
                        ? SettingsUiTokens.primaryText
                        : SettingsUiTokens.mutedText,
                    value: _friendsNews,
                    enabled: !controlsDisabled,
                    onChanged: _toggleFriendsNews,
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'habical v0.7.5',
                style: TextStyle(
                  color: Color(0xFFB5B5B5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.title,
    required this.height,
    required this.fontSize,
    required this.fontWeight,
    required this.textColor,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;
  final Color textColor;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: textColor,
                height: 1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _CompactSwitch(
            value: value,
            enabled: enabled,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _CompactSwitch extends StatelessWidget {
  const _CompactSwitch({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final trackColor = value ? SettingsUiTokens.switchOn : SettingsUiTokens.switchOff;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: 34,
          height: 17,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(9),
            ),
            padding: const EdgeInsets.all(2),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 13,
                height: 13,
                decoration: const BoxDecoration(
                  color: SettingsUiTokens.switchThumb,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
