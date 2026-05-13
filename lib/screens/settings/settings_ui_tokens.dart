import 'package:flutter/material.dart';

class SettingsUiTokens {
  const SettingsUiTokens._();

  static const Color screenBackground = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF000000);
  static const Color mutedText = Color(0xFFABABAB);
  static const Color accentBlue = Color(0xFF0277BC);
  static const Color divider = Color(0xFFB5B5B5);
  static const Color switchOn = Color(0xFF92D7FF);
  static const Color switchOff = Color(0xFFABABAB);
  static const Color switchThumb = Color(0xFFFFFFFF);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(15));
  static const BorderRadius itemRadius = BorderRadius.all(Radius.circular(15));
  static const BorderRadius iconRadius = BorderRadius.all(Radius.circular(10));

  static const BoxShadow cardShadow = BoxShadow(
    color: Color.fromRGBO(29, 39, 51, 0.30),
    offset: Offset(0, 4),
    blurRadius: 10.1,
    spreadRadius: 0,
  );

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(25, 32, 25, 20);
  static const TextStyle screenTitle = TextStyle(
    fontSize: 32,
    height: 1.08,
    fontWeight: FontWeight.w700,
    color: primaryText,
  );
}
