import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/settings_repository.dart';
import 'settings_ui_tokens.dart';

class SettingsAppearanceScreen extends StatefulWidget {
  const SettingsAppearanceScreen({super.key});

  @override
  State<SettingsAppearanceScreen> createState() => _SettingsAppearanceScreenState();
}

class _SettingsAppearanceScreenState extends State<SettingsAppearanceScreen> {
  static const String _tBack = '\u041d\u0430\u0437\u0430\u0434';
  static const String _tTitle = '\u0412\u043d\u0435\u0448\u043d\u0438\u0439 \u0432\u0438\u0434';
  static const String _tFeed = '\u041b\u0435\u043d\u0442\u0430 \u043d\u043e\u0432\u043e\u0441\u0442\u0435\u0439';
  static const String _tStreaks = '\u0421\u0442\u0440\u0438\u043a\u0438';
  static const String _tNewHabits = '\u041d\u043e\u0432\u044b\u0435 \u043f\u0440\u0438\u0432\u044b\u0447\u043a\u0438';
  static const String _tSharedHabits =
      '\u0421\u043e\u0432\u043c\u0435\u0441\u0442\u043d\u044b\u0435 \u043f\u0440\u0438\u0432\u044b\u0447\u043a\u0438';
  static const String _tVersion = 'habical v0.7.5';
  static const String _tLoadError =
      '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u043d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438.';
  static const String _tSaveError =
      '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0441\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c \u0438\u0437\u043c\u0435\u043d\u0435\u043d\u0438\u044f.';

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  bool _streaks = true;
  bool _newHabits = false;
  bool _sharedHabits = false;

  SettingsRepository get _settingsRepository => context.read<SettingsRepository>();

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
        _streaks = data.settings.shareHabits;
        _newHabits = data.settings.shareNews;
        _sharedHabits = data.settings.shareCalendar;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _tLoadError;
        _isLoading = false;
      });
    }
  }

  Future<void> _save({
    bool? streaks,
    bool? newHabits,
    bool? sharedHabits,
  }) async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final prevStreaks = _streaks;
    final prevNewHabits = _newHabits;
    final prevSharedHabits = _sharedHabits;

    try {
      final updated = await _settingsRepository.updatePrivacy(
        shareHabits: streaks,
        shareNews: newHabits,
        shareCalendar: sharedHabits,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _streaks = updated.shareHabits;
        _newHabits = updated.shareNews;
        _sharedHabits = updated.shareCalendar;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _streaks = prevStreaks;
        _newHabits = prevNewHabits;
        _sharedHabits = prevSharedHabits;
        _error = _tSaveError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _toggleStreaks(bool value) async {
    setState(() => _streaks = value);
    await _save(streaks: value);
  }

  Future<void> _toggleNewHabits(bool value) async {
    setState(() => _newHabits = value);
    await _save(newHabits: value);
  }

  Future<void> _toggleSharedHabits(bool value) async {
    setState(() => _sharedHabits = value);
    await _save(sharedHabits: value);
  }

  @override
  Widget build(BuildContext context) {
    final controlsDisabled = _isLoading || _isSaving;

    return Scaffold(
      backgroundColor: SettingsUiTokens.screenBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: SettingsUiTokens.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            constraints: const BoxConstraints.tightFor(
                              width: 24,
                              height: 24,
                            ),
                            splashRadius: 18,
                            tooltip: _tBack,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            _tTitle,
                            style: TextStyle(
                              fontSize: 50 / 1.56,
                              height: 1.08,
                              fontWeight: FontWeight.w700,
                              color: SettingsUiTokens.accentBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
                      const Text(
                        _tFeed,
                        style: TextStyle(
                          fontSize: 36 / 1.56,
                          height: 1.08,
                          fontWeight: FontWeight.w500,
                          color: SettingsUiTokens.accentBlue,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: SettingsUiTokens.cardBackground,
                          borderRadius: SettingsUiTokens.cardRadius,
                          boxShadow: [SettingsUiTokens.cardShadow],
                        ),
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                        child: Column(
                          children: [
                            _FeedSwitchRow(
                              title: _tStreaks,
                              value: _streaks,
                              enabled: !controlsDisabled,
                              textColor: _streaks
                                  ? SettingsUiTokens.primaryText
                                  : SettingsUiTokens.mutedText,
                              onChanged: _toggleStreaks,
                            ),
                            const SizedBox(height: 12),
                            _FeedSwitchRow(
                              title: _tNewHabits,
                              value: _newHabits,
                              enabled: !controlsDisabled,
                              textColor: _newHabits
                                  ? SettingsUiTokens.primaryText
                                  : SettingsUiTokens.mutedText,
                              onChanged: _toggleNewHabits,
                            ),
                            const SizedBox(height: 12),
                            _FeedSwitchRow(
                              title: _tSharedHabits,
                              value: _sharedHabits,
                              enabled: !controlsDisabled,
                              textColor: _sharedHabits
                                  ? SettingsUiTokens.primaryText
                                  : SettingsUiTokens.mutedText,
                              onChanged: _toggleSharedHabits,
                            ),
                          ],
                        ),
                      ),
                      if (_error != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: SettingsUiTokens.divider),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: SettingsUiTokens.primaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 28),
                      const Center(
                        child: Text(
                          _tVersion,
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
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeedSwitchRow extends StatelessWidget {
  const _FeedSwitchRow({
    required this.title,
    required this.value,
    required this.enabled,
    required this.textColor,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final bool enabled;
  final Color textColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Align(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: SettingsUiTokens.switchThumb,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 13, height: 13),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
