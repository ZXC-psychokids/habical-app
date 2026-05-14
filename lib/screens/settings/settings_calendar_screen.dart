import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../repositories/calendar_repository.dart';
import 'settings_ui_tokens.dart';

class SettingsCalendarScreen extends StatefulWidget {
  const SettingsCalendarScreen({super.key});

  @override
  State<SettingsCalendarScreen> createState() => _SettingsCalendarScreenState();
}

class _SettingsCalendarScreenState extends State<SettingsCalendarScreen> {
  static const _prefsShowWeekNumbersKey = 'settings.calendar.showWeekNumbers';
  static const _prefsShowWeekDaysKey = 'settings.calendar.showWeekDays';

  static const List<_CategoryColorOption> _categoryPalette = [
    _CategoryColorOption(hex: '#FF6B6B', name: '\u041a\u0440\u0430\u0441\u043d\u044b\u0439'),
    _CategoryColorOption(hex: '#FFA62B', name: '\u041e\u0440\u0430\u043d\u0436\u0435\u0432\u044b\u0439'),
    _CategoryColorOption(hex: '#FACC15', name: '\u0416\u0435\u043b\u0442\u044b\u0439'),
    _CategoryColorOption(hex: '#4CAF50', name: '\u0417\u0435\u043b\u0435\u043d\u044b\u0439'),
    _CategoryColorOption(hex: '#41D9E2', name: '\u0411\u0438\u0440\u044e\u0437\u043e\u0432\u044b\u0439'),
    _CategoryColorOption(hex: '#5AA9E6', name: '\u0413\u043e\u043b\u0443\u0431\u043e\u0439'),
    _CategoryColorOption(hex: '#1D4ED8', name: '\u0421\u0438\u043d\u0438\u0439'),
    _CategoryColorOption(hex: '#BD2BFF', name: '\u0424\u0438\u043e\u043b\u0435\u0442\u043e\u0432\u044b\u0439'),
    _CategoryColorOption(hex: '#8B5E3C', name: '\u041a\u043e\u0440\u0438\u0447\u043d\u0435\u0432\u044b\u0439'),
    _CategoryColorOption(hex: '#64748B', name: '\u0421\u0435\u0440\u043e-\u0441\u0438\u043d\u0438\u0439'),
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  bool _showWeekNumbers = true;
  bool _showWeekDays = false;
  List<EventCategoryItem> _categories = const [];

  CalendarRepository get _calendarRepository => context.read<CalendarRepository>();

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
      final results = await Future.wait([
        _calendarRepository.fetchCategories(),
        SharedPreferences.getInstance(),
      ]);
      final categories = results[0] as List<EventCategoryItem>;
      final prefs = results[1] as SharedPreferences;
      if (!mounted) {
        return;
      }
      setState(() {
        _showWeekNumbers = prefs.getBool(_prefsShowWeekNumbersKey) ?? true;
        _showWeekDays = prefs.getBool(_prefsShowWeekDaysKey) ?? false;
        _categories = categories;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u043d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438 \u043a\u0430\u043b\u0435\u043d\u0434\u0430\u0440\u044f.';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleShowWeekNumbers(bool value) async {
    setState(() => _showWeekNumbers = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsShowWeekNumbersKey, value);
  }

  Future<void> _toggleShowWeekDays(bool value) async {
    setState(() => _showWeekDays = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsShowWeekDaysKey, value);
  }

  Future<void> _addCategory() async {
    final result = await _showCategoryEditorDialog();
    if (result == null) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _calendarRepository.createCategory(
        title: result.title,
        color: result.colorHex,
      );
      final updated = await _calendarRepository.fetchCategories();
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = updated;
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      final status = e.response?.statusCode;
      if (status == 400) {
        _showSnack('\u041f\u0440\u043e\u0432\u0435\u0440\u044c\u0442\u0435 \u043d\u0430\u0437\u0432\u0430\u043d\u0438\u0435 \u0438\u043b\u0438 \u0446\u0432\u0435\u0442 \u043a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u0438.');
      } else {
        _showSnack('\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0434\u043e\u0431\u0430\u0432\u0438\u0442\u044c \u043a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044e.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack('\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0434\u043e\u0431\u0430\u0432\u0438\u0442\u044c \u043a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044e.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _editCategory(EventCategoryItem category) async {
    final result = await _showCategoryEditorDialog(initial: category);
    if (result == null) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (result.deleteRequested) {
        final shouldDelete = await _showDeleteConfirm();
        if (shouldDelete != true) {
          return;
        }
        await _calendarRepository.deleteCategory(categoryId: category.id);
      } else {
        await _calendarRepository.updateCategory(
          categoryId: category.id,
          title: result.title,
          color: result.colorHex,
        );
      }
      final updated = await _calendarRepository.fetchCategories();
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = updated;
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      final status = e.response?.statusCode;
      if (status == 409) {
        _showSnack('\u041a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044f \u0438\u0441\u043f\u043e\u043b\u044c\u0437\u0443\u0435\u0442\u0441\u044f \u0432 \u0441\u043e\u0431\u044b\u0442\u0438\u044f\u0445 \u0438 \u043d\u0435 \u043c\u043e\u0436\u0435\u0442 \u0431\u044b\u0442\u044c \u0443\u0434\u0430\u043b\u0435\u043d\u0430.');
      } else if (status == 400) {
        _showSnack('\u041f\u0440\u043e\u0432\u0435\u0440\u044c\u0442\u0435 \u043d\u0430\u0437\u0432\u0430\u043d\u0438\u0435 \u0438\u043b\u0438 \u0446\u0432\u0435\u0442 \u043a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u0438.');
      } else {
        _showSnack('\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043e\u0431\u043d\u043e\u0432\u0438\u0442\u044c \u043a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044e.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack('\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043e\u0431\u043d\u043e\u0432\u0438\u0442\u044c \u043a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044e.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlsDisabled = _isLoading || _isSaving;
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
                const Text(
                  '\u041a\u0430\u043b\u0435\u043d\u0434\u0430\u0440\u044c',
                  style: TextStyle(
                    fontSize: 32,
                    height: 1.08,
                    fontWeight: FontWeight.w700,
                    color: SettingsUiTokens.accentBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _Card(
              child: Column(
                children: [
                  _SwitchRow(
                    title: '\u041f\u043e\u043a\u0430\u0437\u044b\u0432\u0430\u0442\u044c \u043d\u043e\u043c\u0435\u0440 \u043d\u0435\u0434\u0435\u043b\u0438',
                    muted: false,
                    value: _showWeekNumbers,
                    enabled: !controlsDisabled,
                    onChanged: _toggleShowWeekNumbers,
                  ),
                  const SizedBox(height: 12),
                  _SwitchRow(
                    title: '\u041f\u043e\u043a\u0430\u0437\u044b\u0432\u0430\u0442\u044c \u0434\u043d\u0438 \u043d\u0435\u0434\u0435\u043b\u0438',
                    muted: !_showWeekDays,
                    value: _showWeekDays,
                    enabled: !controlsDisabled,
                    onChanged: _toggleShowWeekDays,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _SectionTitle('\u041a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u0438 \u0441\u043e\u0431\u044b\u0442\u0438\u0439'),
            const SizedBox(height: 12),
            _Card(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: CircularProgressIndicator(
                          color: SettingsUiTokens.accentBlue,
                        ),
                      ),
                    )
                  : _categories.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '\u041a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u0438 \u043f\u043e\u043a\u0430 \u043d\u0435 \u0434\u043e\u0431\u0430\u0432\u043b\u0435\u043d\u044b',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: SettingsUiTokens.mutedText,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < _categories.length; i++) ...[
                          _CategoryRow(
                            title: _categories[i].title,
                            colorName: _colorNameByHex(_categories[i].color),
                            dotColor: _parseHexColor(_categories[i].color),
                            enabled: !controlsDisabled,
                            onTap: () => _editCategory(_categories[i]),
                          ),
                          if (i < _categories.length - 1) const SizedBox(height: 10),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 45,
              child: ElevatedButton(
                onPressed: controlsDisabled ? null : _addCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SettingsUiTokens.accentBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: SettingsUiTokens.accentBlue.withAlpha(120),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  '\u0414\u043e\u0431\u0430\u0432\u0438\u0442\u044c \u043a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044e',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
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

  Future<_CategoryEditorResult?> _showCategoryEditorDialog({
    EventCategoryItem? initial,
  }) async {
    final titleController = TextEditingController(text: initial?.title ?? '');
    var selectedColor = _normalizeToPaletteColorHex(initial?.color);

    final result = await showDialog<_CategoryEditorResult>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: SettingsUiTokens.cardBackground,
              shape: const RoundedRectangleBorder(
                borderRadius: SettingsUiTokens.cardRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      initial == null
                          ? '\u041d\u043e\u0432\u0430\u044f \u043a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044f'
                          : '\u0420\u0435\u0434\u0430\u043a\u0442\u0438\u0440\u043e\u0432\u0430\u043d\u0438\u0435',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: SettingsUiTokens.primaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      cursorColor: SettingsUiTokens.accentBlue,
                      decoration: InputDecoration(
                        labelText: 'Название',
                        isDense: true,
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final color in _categoryPalette)
                          _ColorDotButton(
                            color: _parseHexColor(color.hex),
                            selected: selectedColor == color.hex,
                            tooltip: color.name,
                            onTap: () => setDialogState(() {
                              selectedColor = color.hex;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (initial != null)
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(
                                const _CategoryEditorResult(
                                  title: '',
                                  colorHex: '',
                                  deleteRequested: true,
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: SettingsUiTokens.accentBlue,
                            ),
                            child: const Text('Удалить'),
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: SettingsUiTokens.accentBlue,
                          ),
                          child: const Text('Отмена'),
                        ),
                        const SizedBox(width: 6),
                        FilledButton(
                          onPressed: () {
                            final title = titleController.text.trim();
                            if (title.isEmpty) {
                              return;
                            }
                            Navigator.of(context).pop(
                              _CategoryEditorResult(
                                title: title,
                                colorHex: selectedColor,
                                deleteRequested: false,
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: SettingsUiTokens.accentBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(initial == null ? 'Добавить' : 'Сохранить'),
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
    return result;
  }

  Future<bool?> _showDeleteConfirm() {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: SettingsUiTokens.cardBackground,
        shape: const RoundedRectangleBorder(borderRadius: SettingsUiTokens.cardRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u043a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044e?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                '\u041a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044f \u0431\u0443\u0434\u0435\u0442 \u0443\u0434\u0430\u043b\u0435\u043d\u0430, \u0435\u0441\u043b\u0438 \u043d\u0435 \u0438\u0441\u043f\u043e\u043b\u044c\u0437\u0443\u0435\u0442\u0441\u044f \u0432 \u0441\u043e\u0431\u044b\u0442\u0438\u044f\u0445.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: SettingsUiTokens.mutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: SettingsUiTokens.accentBlue,
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: SettingsUiTokens.accentBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Удалить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  String _normalizeToPaletteColorHex(String? rawHex) {
    if (rawHex == null) {
      return _categoryPalette.first.hex;
    }
    final normalized = rawHex.trim().toUpperCase();
    for (final option in _categoryPalette) {
      if (option.hex == normalized) {
        return option.hex;
      }
    }
    return _categoryPalette.first.hex;
  }

  String _colorNameByHex(String rawHex) {
    final normalized = rawHex.trim().toUpperCase();
    for (final option in _categoryPalette) {
      if (option.hex == normalized) {
        return option.name;
      }
    }
    return normalized;
  }

  static Color _parseHexColor(String hex) {
    final cleaned = hex.trim().replaceFirst('#', '');
    if (cleaned.length == 6) {
      final value = int.tryParse(cleaned, radix: 16);
      if (value != null) {
        return Color(0xFF000000 | value);
      }
    }
    return const Color(0xFF5AA9E6);
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: SettingsUiTokens.accentBlue,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.muted,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final bool muted;
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
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: muted ? SettingsUiTokens.mutedText : SettingsUiTokens.primaryText,
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
      opacity: enabled ? 1 : 0.6,
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.title,
    required this.colorName,
    required this.dotColor,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String colorName;
  final Color dotColor;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: enabled ? SettingsUiTokens.primaryText : SettingsUiTokens.mutedText,
                ),
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              colorName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: SettingsUiTokens.mutedText,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: enabled ? SettingsUiTokens.primaryText : SettingsUiTokens.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDotButton extends StatelessWidget {
  const _ColorDotButton({
    required this.color,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 28,
          height: 28,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? SettingsUiTokens.accentBlue : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryColorOption {
  const _CategoryColorOption({
    required this.hex,
    required this.name,
  });

  final String hex;
  final String name;
}

class _CategoryEditorResult {
  const _CategoryEditorResult({
    required this.title,
    required this.colorHex,
    required this.deleteRequested,
  });

  final String title;
  final String colorHex;
  final bool deleteRequested;
}

