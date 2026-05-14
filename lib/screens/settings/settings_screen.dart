import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/auth_repository.dart';
import 'settings_appearance_screen.dart';
import 'settings_calendar_screen.dart';
import 'settings_notifications_screen.dart';
import 'settings_profile_screen.dart';
import 'settings_ui_tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    required this.onLogout,
  });

  final VoidCallback onLogout;

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
