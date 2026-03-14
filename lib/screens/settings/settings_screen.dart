import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          children: [
            const Text(
              'Настройки',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            const _SettingCard(
              title: 'Имя пользователя',
              value: 'Андрей',
              leading: Icons.person_outline,
            ),
            const SizedBox(height: 10),
            const _SettingCard(
              title: 'Тема',
              value: 'Светлая',
              leading: Icons.light_mode_outlined,
            ),
            const SizedBox(height: 10),
            const _SettingCard(
              title: 'Язык',
              value: 'Русский',
              leading: Icons.language_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.title,
    required this.value,
    required this.leading,
  });

  final String title;
  final String value;
  final IconData leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A000000)),
      ),
      child: ListTile(
        leading: Icon(leading, color: const Color(0xFF3C3C3C)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
