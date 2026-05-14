import 'package:flutter/material.dart';
import 'settings_ui_tokens.dart';

class SettingsAppearanceScreen extends StatefulWidget {
  const SettingsAppearanceScreen({super.key});

  @override
  State<SettingsAppearanceScreen> createState() => _SettingsAppearanceScreenState();
}

class _SettingsAppearanceScreenState extends State<SettingsAppearanceScreen> {
  static const String _tBack = '\u041d\u0430\u0437\u0430\u0434';
  static const String _tTitle = '\u0412\u043d\u0435\u0448\u043d\u0438\u0439 \u0432\u0438\u0434';
  static const String _tVersion = 'habical v0.7.5';
  @override
  Widget build(BuildContext context) {
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
                      const Spacer(),
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
