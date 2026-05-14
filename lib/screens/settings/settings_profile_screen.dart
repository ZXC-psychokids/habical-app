import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../repositories/settings_repository.dart';
import 'settings_ui_tokens.dart';

class SettingsProfileScreen extends StatefulWidget {
  const SettingsProfileScreen({super.key});

  @override
  State<SettingsProfileScreen> createState() => _SettingsProfileScreenState();
}

class _SettingsProfileScreenState extends State<SettingsProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  static const _tLoadProfileError =
      '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u043f\u0440\u043e\u0444\u0438\u043b\u044c.';
  static const _tCancel = '\u041e\u0442\u043c\u0435\u043d\u0430';
  static const _tSave = '\u0421\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c';
  static const _tCheckValue =
      '\u041f\u0440\u043e\u0432\u0435\u0440\u044c\u0442\u0435 \u0432\u0432\u0435\u0434\u0435\u043d\u043d\u043e\u0435 \u0437\u043d\u0430\u0447\u0435\u043d\u0438\u0435.';
  static const _tSaveChangesError =
      '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0441\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c \u0438\u0437\u043c\u0435\u043d\u0435\u043d\u0438\u044f.';
  static const _tInvalidHandle =
      '\u0425\u044d\u043d\u0434\u043b: 3\u201330 \u0441\u0438\u043c\u0432\u043e\u043b\u043e\u0432, \u0442\u043e\u043b\u044c\u043a\u043e \u043b\u0430\u0442\u0438\u043d\u0441\u043a\u0438\u0435 \u0431\u0443\u043a\u0432\u044b, \u0446\u0438\u0444\u0440\u044b \u0438 _.';
  static const _tInvalidEmail =
      '\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u043a\u043e\u0440\u0440\u0435\u043a\u0442\u043d\u044b\u0439 email.';
  static const _tPrivacyError =
      '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043e\u0431\u043d\u043e\u0432\u0438\u0442\u044c \u043f\u0440\u0438\u0432\u0430\u0442\u043d\u043e\u0441\u0442\u044c.';
  static const _tAvatarUpdated =
      '\u0410\u0432\u0430\u0442\u0430\u0440 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d.';
  static const _tImageOnly =
      '\u041f\u043e\u0434\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u044e\u0442\u0441\u044f \u0442\u043e\u043b\u044c\u043a\u043e \u0438\u0437\u043e\u0431\u0440\u0430\u0436\u0435\u043d\u0438\u044f.';
  static const _tAvatarUploadError =
      '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u0430\u0432\u0430\u0442\u0430\u0440.';
  static const _tBack = '\u041d\u0430\u0437\u0430\u0434';
  static const _tProfile = '\u041f\u0440\u043e\u0444\u0438\u043b\u044c';
  static const _tAboutYou = '\u0418\u043d\u0444\u043e\u0440\u043c\u0430\u0446\u0438\u044f \u043e \u0432\u0430\u0441';
  static const _tChangeHandle =
      '\u0421\u043c\u0435\u043d\u0438\u0442\u044c \u0438\u043c\u044f \u043f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u0442\u0435\u043b\u044f';
  static const _tEditHandle =
      '\u0418\u0437\u043c\u0435\u043d\u0438\u0442\u044c \u0438\u043c\u044f \u043f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u0442\u0435\u043b\u044f';
  static const _tHandle = '\u0425\u044d\u043d\u0434\u043b';
  static const _tChangeEmail = '\u0421\u043c\u0435\u043d\u0438\u0442\u044c \u043f\u043e\u0447\u0442\u0443';
  static const _tEditEmail = '\u0418\u0437\u043c\u0435\u043d\u0438\u0442\u044c \u043f\u043e\u0447\u0442\u0443';
  static const _tPrivacy = '\u041a\u043e\u043d\u0444\u0438\u0434\u0435\u043d\u0446\u0438\u0430\u043b\u044c\u043d\u043e\u0441\u0442\u044c';
  static const _tHabits = '\u041f\u0440\u0438\u0432\u044b\u0447\u043a\u0438';
  static const _tCalendar = '\u041a\u0430\u043b\u0435\u043d\u0434\u0430\u0440\u044c';
  static const _tNews = '\u041d\u043e\u0432\u043e\u0441\u0442\u0438';

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  ProfileData? _profile;
  UserSettingsData? _settings;

  SettingsRepository get _settingsRepository => context.read<SettingsRepository>();

  void _showUiSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: SettingsUiTokens.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFFF3F3F3),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: SettingsUiTokens.divider),
          ),
        ),
      );
  }

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
        _profile = data.profile;
        _settings = data.settings;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _tLoadProfileError;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfileField({
    required String title,
    required String label,
    required String initialValue,
    required Future<ProfileData> Function(String value) update,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String value)? validator,
  }) async {
    if (_profile == null || _isSaving) {
      return;
    }

    final controller = TextEditingController(text: initialValue);
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        String? validationError;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: SettingsUiTokens.cardBackground,
              shape: const RoundedRectangleBorder(borderRadius: SettingsUiTokens.cardRadius),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: SettingsUiTokens.primaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      textInputAction: TextInputAction.done,
                      cursorColor: SettingsUiTokens.accentBlue,
                      onSubmitted: (_) {
                        final candidate = controller.text.trim();
                        final error = validator?.call(candidate);
                        if (error != null) {
                          setDialogState(() => validationError = error);
                          return;
                        }
                        Navigator.of(context).pop(candidate);
                      },
                      decoration: InputDecoration(
                        labelText: label,
                        isDense: true,
                        errorText: validationError,
                        labelStyle: const TextStyle(color: SettingsUiTokens.mutedText),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: SettingsUiTokens.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: SettingsUiTokens.accentBlue,
                            width: 1.5,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: SettingsUiTokens.divider),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: SettingsUiTokens.accentBlue,
                          ),
                          child: const Text(_tCancel),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final candidate = controller.text.trim();
                            final error = validator?.call(candidate);
                            if (error != null) {
                              setDialogState(() => validationError = error);
                              return;
                            }
                            Navigator.of(context).pop(candidate);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: SettingsUiTokens.accentBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(_tSave),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    controller.dispose();
    if (value == null || value.isEmpty || value == initialValue) {
      return;
    }
    final validationError = validator?.call(value);
    if (validationError != null) {
      _showUiSnack(validationError);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final updatedProfile = await update(value);
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = updatedProfile;
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      final status = e.response?.statusCode;
      final message = status == 400 ? _tCheckValue : _tSaveChangesError;
      _showUiSnack(message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showUiSnack(_tSaveChangesError);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _updatePrivacy({
    bool? shareHabits,
    bool? shareCalendar,
    bool? shareNews,
  }) async {
    final current = _settings;
    if (current == null || _isSaving) {
      return;
    }

    final optimistic = UserSettingsData(
      shareHabits: shareHabits ?? current.shareHabits,
      shareCalendar: shareCalendar ?? current.shareCalendar,
      shareNews: shareNews ?? current.shareNews,
      notifyFriendRequests: current.notifyFriendRequests,
      notifyHabitReminders: current.notifyHabitReminders,
      notifyFriendsNews: current.notifyFriendsNews,
      timezone: current.timezone,
      weekStartsOn: current.weekStartsOn,
    );

    setState(() {
      _settings = optimistic;
      _isSaving = true;
      _error = null;
    });

    try {
      final updated = await _settingsRepository.updatePrivacy(
        shareHabits: shareHabits,
        shareCalendar: shareCalendar,
        shareNews: shareNews,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _settings = updated;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _settings = current;
      });
      _showUiSnack(_tPrivacyError);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isSaving || _profile == null) {
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final bytes = await picked.readAsBytes();
      final updated = await _settingsRepository.updateAvatar(
        bytes: bytes,
        filename: picked.name.isEmpty ? 'avatar.jpg' : picked.name,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = updated;
      });
      _showUiSnack(_tAvatarUpdated);
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      final status = e.response?.statusCode;
      final message = status == 400 ? _tImageOnly : _tAvatarUploadError;
      _showUiSnack(message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showUiSnack(_tAvatarUploadError);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final settings = _settings;
    final controlsDisabled = _isLoading || _isSaving || profile == null || settings == null;

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
                  tooltip: _tBack,
                ),
                const SizedBox(width: 8),
                const Text(
                  _tProfile,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: SettingsUiTokens.accentBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _AvatarSection(
              avatarUrl: profile?.avatarUrl ?? '',
              onTapCamera: _pickAndUploadAvatar,
            ),
            const SizedBox(height: 20),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BlockTitle(_tAboutYou),
                  const SizedBox(height: 12),
                  _ProfileFieldRow(
                    icon: Icons.alternate_email_rounded,
                    value: profile == null ? '' : '@${profile.handle}',
                    subtitle: _tChangeHandle,
                    enabled: !controlsDisabled,
                    onTap: () => _updateProfileField(
                      title: _tEditHandle,
                      label: _tHandle,
                      initialValue: profile?.handle ?? '',
                      validator: _validateHandle,
                      update: (value) => _settingsRepository.updateProfile(handle: value),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ProfileFieldRow(
                    icon: Icons.mail_outline_rounded,
                    value: profile?.email ?? '',
                    subtitle: _tChangeEmail,
                    enabled: !controlsDisabled,
                    onTap: () => _updateProfileField(
                      title: _tEditEmail,
                      label: 'Email',
                      initialValue: profile?.email ?? '',
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      update: (value) => _settingsRepository.updateProfile(email: value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BlockTitle(_tPrivacy),
                  const SizedBox(height: 12),
                  _PrivacySwitchRow(
                    title: _tHabits,
                    value: settings?.shareHabits ?? false,
                    enabled: !controlsDisabled,
                    onChanged: (value) => _updatePrivacy(shareHabits: value),
                  ),
                  const SizedBox(height: 8),
                  _PrivacySwitchRow(
                    title: _tCalendar,
                    value: settings?.shareCalendar ?? false,
                    enabled: !controlsDisabled,
                    onChanged: (value) => _updatePrivacy(shareCalendar: value),
                  ),
                  const SizedBox(height: 8),
                  _PrivacySwitchRow(
                    title: _tNews,
                    value: settings?.shareNews ?? false,
                    enabled: !controlsDisabled,
                    onChanged: (value) => _updatePrivacy(shareNews: value),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: SettingsUiTokens.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

  String? _validateHandle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return _tCheckValue;
    }
    final regex = RegExp(r'^[a-zA-Z0-9_]{3,30}$');
    if (!regex.hasMatch(trimmed)) {
      return _tInvalidHandle;
    }
    return null;
  }

  String? _validateEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return _tCheckValue;
    }
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!regex.hasMatch(trimmed)) {
      return _tInvalidEmail;
    }
    return null;
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.avatarUrl,
    required this.onTapCamera,
  });

  final String avatarUrl;
  final VoidCallback onTapCamera;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl.trim().isNotEmpty;
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: SettingsUiTokens.accentBlue, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(58),
              child: hasAvatar
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _AvatarFallback(),
                    )
                  : const _AvatarFallback(),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: InkWell(
              onTap: onTapCamera,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: SettingsUiTokens.accentBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  size: 17,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE7F3FB),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 54,
        color: SettingsUiTokens.accentBlue,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SettingsUiTokens.cardBackground,
        borderRadius: SettingsUiTokens.cardRadius,
        boxShadow: [SettingsUiTokens.cardShadow],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: child,
    );
  }
}

class _BlockTitle extends StatelessWidget {
  const _BlockTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: SettingsUiTokens.accentBlue,
      ),
    );
  }
}

class _ProfileFieldRow extends StatelessWidget {
  const _ProfileFieldRow({
    required this.icon,
    required this.value,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: SettingsUiTokens.accentBlue,
              borderRadius: SettingsUiTokens.iconRadius,
            ),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SettingsUiTokens.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: SettingsUiTokens.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySwitchRow extends StatelessWidget {
  const _PrivacySwitchRow({
    required this.title,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: value ? SettingsUiTokens.primaryText : SettingsUiTokens.mutedText,
              ),
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
              color: value ? SettingsUiTokens.switchOn : SettingsUiTokens.switchOff,
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
