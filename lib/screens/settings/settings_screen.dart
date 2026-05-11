import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/auth_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _backgroundColor = Color(0xFFFFFFFF);
  static const _cardColor = Color(0xFFFFFFFF);
  static const _accentBlue = Color(0xFF0277BC);
  static const _titleColor = Color(0xFF0C0C0C);
  static const _dividerColor = Color(0xFFB5B5B5);
  static const _secondaryTextColor = Color(0xFFB5B5B5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(25, 32, 25, 20),
          children: [
            const Text(
              'Настройки',
              style: TextStyle(
                fontSize: 32,
                height: 1.08,
                fontWeight: FontWeight.w700,
                color: _titleColor,
              ),
            ),
            const SizedBox(height: 46),
            _SettingsCard(onLogout: () => _logout(context)),
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
        const SnackBar(content: Text('Вы вышли из аккаунта')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось выйти из аккаунта')),
      );
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SettingsScreen._cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(29, 39, 51, 0.30),
            offset: Offset(0, 4),
            blurRadius: 10.1,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          _SettingsRow(
            icon: Icons.person_outline,
            title: 'Профиль',
            trailingBuilder: (isActive) => _Chevron(
              color: isActive
                  ? SettingsScreen._accentBlue
                  : const Color(0xFF171717),
            ),
            onTap: () {},
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.language,
            title: 'Язык',
            trailingBuilder: (isActive) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Русский',
                  style: TextStyle(
                    color: SettingsScreen._secondaryTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                _Chevron(
                  color: isActive
                      ? SettingsScreen._accentBlue
                      : const Color(0xFF171717),
                ),
              ],
            ),
            onTap: () {},
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.palette_outlined,
            title: 'Внешний вид',
            trailingBuilder: (isActive) => _Chevron(
              color: isActive
                  ? SettingsScreen._accentBlue
                  : const Color(0xFF171717),
            ),
            onTap: () {},
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.calendar_today_outlined,
            title: 'Календарь',
            trailingBuilder: (isActive) => _Chevron(
              color: isActive
                  ? SettingsScreen._accentBlue
                  : const Color(0xFF171717),
            ),
            onTap: () {},
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.notifications_none_outlined,
            title: 'Уведомления',
            trailingBuilder: (isActive) => _Chevron(
              color: isActive
                  ? SettingsScreen._accentBlue
                  : const Color(0xFF171717),
            ),
            onTap: () {},
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.build_outlined,
            title: 'Поддержка',
            trailingBuilder: (isActive) => _Chevron(
              color: isActive
                  ? SettingsScreen._accentBlue
                  : const Color(0xFF171717),
            ),
            onTap: () {},
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.logout,
            title: 'Выйти из аккаунта',
            trailingBuilder: (isActive) => _Chevron(
              color: isActive
                  ? SettingsScreen._accentBlue
                  : const Color(0xFF171717),
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
    this.titleColor = const Color(0xFF111111),
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
    final titleColor = isActive ? SettingsScreen._accentBlue : widget.titleColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
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
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: SettingsScreen._accentBlue,
                  borderRadius: BorderRadius.circular(10),
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
        color: SettingsScreen._dividerColor,
      ),
    );
  }
}
