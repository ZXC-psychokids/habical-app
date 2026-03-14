import 'package:flutter/material.dart';

import '../../widgets/appear_animations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  children: const [
                    DelayedAppear(
                      delay: Duration(milliseconds: 70),
                      child: _SettingCard(
                        title: 'Имя пользователя',
                        value: 'Андрей',
                        leading: Icons.person_outline,
                      ),
                    ),
                    SizedBox(height: 10),
                    DelayedAppear(
                      delay: Duration(milliseconds: 110),
                      child: _SettingCard(
                        title: 'Тема',
                        value: 'Светлая',
                        leading: Icons.light_mode_outlined,
                      ),
                    ),
                    SizedBox(height: 10),
                    DelayedAppear(
                      delay: Duration(milliseconds: 150),
                      child: _SettingCard(
                        title: 'Язык',
                        value: 'Русский',
                        leading: Icons.language_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
