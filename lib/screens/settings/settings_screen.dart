import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/auth_repository.dart';
import 'settings_appearance_screen.dart';
import 'settings_calendar_screen.dart';
import 'settings_notifications_screen.dart';
import 'settings_profile_screen.dart';
import 'settings_ui_tokens.dart';

enum _UiLanguage { ru, en }

extension _UiLanguageView on _UiLanguage {
  String get title {
    switch (this) {
      case _UiLanguage.ru:
        return 'Русский';
      case _UiLanguage.en:
        return 'English';
    }
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _UiLanguage _selectedLanguage = _UiLanguage.ru;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsUiTokens.screenBackground,
      body: SafeArea(
        child: ListView(
          padding: SettingsUiTokens.pagePadding,
          children: [
            const Text(
              '\u041d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438',
              style: TextStyle(
                fontSize: 32,
                height: 1.08,
                fontWeight: FontWeight.w700,
                color: SettingsUiTokens.accentBlue,
              ),
            ),
            const SizedBox(height: 46),
            _SettingsCard(
              selectedLanguage: _selectedLanguage,
              onLanguageSelected: (value) {
                setState(() => _selectedLanguage = value);
              },
              onLogout: () => _logout(context),
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

  Future<void> _logout(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthRepository>().logout();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('\u0412\u044b \u0432\u044b\u0448\u043b\u0438 \u0438\u0437 \u0430\u043a\u043a\u0430\u0443\u043d\u0442\u0430'),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0432\u044b\u0439\u0442\u0438 \u0438\u0437 \u0430\u043a\u043a\u0430\u0443\u043d\u0442\u0430'),
        ),
      );
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.selectedLanguage,
    required this.onLanguageSelected,
    required this.onLogout,
  });

  final _UiLanguage selectedLanguage;
  final ValueChanged<_UiLanguage> onLanguageSelected;
  final VoidCallback onLogout;

  Future<_UiLanguage?> _showLanguageDialog(
    BuildContext context,
    _UiLanguage selected,
  ) {
    return showDialog<_UiLanguage>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: SettingsUiTokens.cardBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: SettingsUiTokens.cardRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '\u042f\u0437\u044b\u043a',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: SettingsUiTokens.accentBlue,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(
                height: 1,
                thickness: 1,
                color: SettingsUiTokens.divider,
              ),
              const SizedBox(height: 8),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const _LanguageFlag(language: _UiLanguage.ru),
                title: const Text(
                  'Русский',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SettingsUiTokens.primaryText,
                  ),
                ),
                trailing: selected == _UiLanguage.ru
                    ? const Icon(
                        Icons.check_rounded,
                        color: SettingsUiTokens.accentBlue,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(_UiLanguage.ru),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const _LanguageFlag(language: _UiLanguage.en),
                title: const Text(
                  'English',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SettingsUiTokens.primaryText,
                  ),
                ),
                trailing: selected == _UiLanguage.en
                    ? const Icon(
                        Icons.check_rounded,
                        color: SettingsUiTokens.accentBlue,
                      )
                    : null,
                onTap: null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SettingsUiTokens.cardBackground,
        borderRadius: SettingsUiTokens.cardRadius,
        boxShadow: const [SettingsUiTokens.cardShadow],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          _SettingsRow(
            icon: Icons.person_outline,
            title: '\u041f\u0440\u043e\u0444\u0438\u043b\u044c',
            trailingBuilder: (isActive) => _Chevron(
              color: isActive ? SettingsUiTokens.accentBlue : const Color(0xFF171717),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsProfileScreen(),
                ),
              );
            },
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.language,
            title: '\u042f\u0437\u044b\u043a',
            trailingBuilder: (isActive) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedLanguage.title,
                  style: const TextStyle(
                    color: SettingsUiTokens.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                _LanguageFlag(language: selectedLanguage, compact: true),
                const SizedBox(width: 10),
                _Chevron(
                  color: isActive
                      ? SettingsUiTokens.accentBlue
                      : const Color(0xFF171717),
                ),
              ],
            ),
            onTap: () {
              _showLanguageDialog(context, selectedLanguage).then((value) {
                if (value != null) {
                  onLanguageSelected(value);
                }
              });
            },
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.palette_outlined,
            title: '\u0412\u043d\u0435\u0448\u043d\u0438\u0439 \u0432\u0438\u0434',
            trailingBuilder: (isActive) => _Chevron(
              color: isActive ? SettingsUiTokens.accentBlue : const Color(0xFF171717),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsAppearanceScreen(),
                ),
              );
            },
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.calendar_today_outlined,
            title: '\u041a\u0430\u043b\u0435\u043d\u0434\u0430\u0440\u044c',
            trailingBuilder: (isActive) => _Chevron(
              color: isActive ? SettingsUiTokens.accentBlue : const Color(0xFF171717),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsCalendarScreen(),
                ),
              );
            },
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.notifications_none_outlined,
            title: '\u0423\u0432\u0435\u0434\u043e\u043c\u043b\u0435\u043d\u0438\u044f',
            trailingBuilder: (isActive) => _Chevron(
              color: isActive ? SettingsUiTokens.accentBlue : const Color(0xFF171717),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsNotificationsScreen(),
                ),
              );
            },
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.logout,
            title: '\u0412\u044b\u0439\u0442\u0438 \u0438\u0437 \u0430\u043a\u043a\u0430\u0443\u043d\u0442\u0430',
            trailingBuilder: (isActive) => _Chevron(
              color: isActive ? SettingsUiTokens.accentBlue : const Color(0xFF171717),
            ),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatefulWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.trailingBuilder,
    required this.onTap,
    this.titleColor = SettingsUiTokens.primaryText,
  });

  final IconData icon;
  final String title;
  final Color titleColor;
  final Widget Function(bool isActive) trailingBuilder;
  final VoidCallback onTap;

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovered || _isPressed;
    final titleColor = isActive ? SettingsUiTokens.accentBlue : widget.titleColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: SettingsUiTokens.itemRadius,
        onTap: widget.onTap,
        onHover: (hovered) => setState(() => _isHovered = hovered),
        onHighlightChanged: (pressed) => setState(() => _isPressed = pressed),
        mouseCursor: SystemMouseCursors.click,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            borderRadius: SettingsUiTokens.itemRadius,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: SettingsUiTokens.accentBlue,
                  borderRadius: SettingsUiTokens.iconRadius,
                ),
                child: Icon(widget.icon, size: 17, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              widget.trailingBuilder(isActive),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.arrow_forward_ios_rounded, size: 13, color: color);
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Divider(
        height: 1,
        thickness: 1,
        color: SettingsUiTokens.divider,
      ),
    );
  }
}

class _LanguageFlag extends StatelessWidget {
  const _LanguageFlag({required this.language, this.compact = false});

  final _UiLanguage language;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 16.0 : 20.0;
    final height = compact ? 12.0 : 14.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(2.5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          border: Border.all(color: const Color(0x55000000)),
        ),
        child: switch (language) {
          _UiLanguage.ru => const _RuFlag(),
          _UiLanguage.en => const _UkLikeFlag(),
        },
      ),
    );
  }
}

class _RuFlag extends StatelessWidget {
  const _RuFlag();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE5E7EB),
            Color(0xFFE5E7EB),
            Color(0xFF1D4ED8),
            Color(0xFF1D4ED8),
            Color(0xFFDC2626),
            Color(0xFFDC2626),
          ],
          stops: [0.0, 0.33, 0.33, 0.66, 0.66, 1.0],
        ),
      ),
    );
  }
}

class _UkLikeFlag extends StatelessWidget {
  const _UkLikeFlag();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF1F4EA8)),
        Center(
          child: Transform.rotate(
            angle: 0.60,
            child: Container(width: 36, height: 3, color: Colors.white),
          ),
        ),
        Center(
          child: Transform.rotate(
            angle: -0.60,
            child: Container(width: 36, height: 3, color: Colors.white),
          ),
        ),
        Center(child: Container(width: 4, color: Colors.white)),
        Center(child: Container(height: 4, color: Colors.white)),
        Center(
          child: Transform.rotate(
            angle: 0.60,
            child: Container(width: 36, height: 1.5, color: Color(0xFFDC2626)),
          ),
        ),
        Center(
          child: Transform.rotate(
            angle: -0.60,
            child: Container(width: 36, height: 1.5, color: Color(0xFFDC2626)),
          ),
        ),
        Center(child: Container(width: 2, color: Color(0xFFDC2626))),
        Center(child: Container(height: 2, color: Color(0xFFDC2626))),
      ],
    );
  }
}
