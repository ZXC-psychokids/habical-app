import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../repositories/calendar_repository.dart';
import '../../repositories/settings_repository.dart';
import 'settings_ui_tokens.dart';

class SettingsCalendarScreen extends StatefulWidget {
  const SettingsCalendarScreen({super.key});

  @override
  State<SettingsCalendarScreen> createState() => _SettingsCalendarScreenState();
}

class _SettingsCalendarScreenState extends State<SettingsCalendarScreen> {
  static const _prefsShowWeekNumbersKey = 'settings.calendar.showWeekNumbers';
  static const _prefsShowWeekDaysKey = 'settings.calendar.showWeekDays';

  static const List<_WeekStartOption> _weekStartOptions = [
    _WeekStartOption(value: 1, label: '\u041f\u043e\u043d\u0435\u0434\u0435\u043b\u044c\u043d\u0438\u043a'),
    _WeekStartOption(value: 7, label: '\u0412\u043e\u0441\u043a\u0440\u0435\u0441\u0435\u043d\u044c\u0435'),
  ];

  static const List<_TimezoneOption> _timezoneOptions = [
    _TimezoneOption(label: 'GMT-12', iana: 'Etc/GMT+12'),
    _TimezoneOption(label: 'GMT-11', iana: 'Pacific/Pago_Pago'),
    _TimezoneOption(label: 'GMT-10', iana: 'Pacific/Honolulu'),
    _TimezoneOption(label: 'GMT-9', iana: 'America/Anchorage'),
    _TimezoneOption(label: 'GMT-8', iana: 'America/Los_Angeles'),
    _TimezoneOption(label: 'GMT-7', iana: 'America/Denver'),
    _TimezoneOption(label: 'GMT-6', iana: 'America/Chicago'),
    _TimezoneOption(label: 'GMT-5', iana: 'America/New_York'),
    _TimezoneOption(label: 'GMT-4', iana: 'America/Halifax'),
    _TimezoneOption(label: 'GMT-3', iana: 'America/Sao_Paulo'),
    _TimezoneOption(label: 'GMT-2', iana: 'Atlantic/South_Georgia'),
    _TimezoneOption(label: 'GMT-1', iana: 'Atlantic/Azores'),
    _TimezoneOption(label: 'GMT+0', iana: 'Europe/London'),
    _TimezoneOption(label: 'GMT+1', iana: 'Europe/Berlin'),
    _TimezoneOption(label: 'GMT+1', iana: 'Europe/Warsaw'),
    _TimezoneOption(label: 'GMT+2', iana: 'Europe/Kyiv'),
    _TimezoneOption(label: 'GMT+3', iana: 'Europe/Moscow'),
    _TimezoneOption(label: 'GMT+4', iana: 'Asia/Dubai'),
    _TimezoneOption(label: 'GMT+5', iana: 'Asia/Karachi'),
    _TimezoneOption(label: 'GMT+6', iana: 'Asia/Dhaka'),
    _TimezoneOption(label: 'GMT+7', iana: 'Asia/Bangkok'),
    _TimezoneOption(label: 'GMT+8', iana: 'Asia/Shanghai'),
    _TimezoneOption(label: 'GMT+9', iana: 'Asia/Tokyo'),
    _TimezoneOption(label: 'GMT+10', iana: 'Australia/Sydney'),
    _TimezoneOption(label: 'GMT+11', iana: 'Pacific/Noumea'),
    _TimezoneOption(label: 'GMT+12', iana: 'Pacific/Auckland'),
    _TimezoneOption(label: 'GMT+13', iana: 'Pacific/Apia'),
    _TimezoneOption(label: 'GMT+14', iana: 'Pacific/Kiritimati'),
  ];

  static const List<String> _categoryPalette = [
    '#BD2BFF',
    '#FFA62B',
    '#41D9E2',
    '#5AA9E6',
    '#4CAF50',
    '#FF6B6B',
    '#AF52DE',
    '#FF9F0A',
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  int _weekStartsOn = 1;
  String _timezoneIana = 'Europe/Moscow';
  bool _showWeekNumbers = true;
  bool _showWeekDays = false;
  List<EventCategoryItem> _categories = const [];

  SettingsRepository get _settingsRepository => context.read<SettingsRepository>();
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
        _settingsRepository.fetchProfileAndSettings(),
        _calendarRepository.fetchCategories(),
        SharedPreferences.getInstance(),
      ]);
      final settingsData = results[0] as ProfileAndSettings;
      final categories = results[1] as List<EventCategoryItem>;
      final prefs = results[2] as SharedPreferences;
      if (!mounted) {
        return;
      }
      setState(() {
        _weekStartsOn = _normalizeWeekStart(settingsData.settings.weekStartsOn);
        _timezoneIana = settingsData.settings.timezone;
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

  Future<void> _saveCalendarSettings({
    int? weekStartsOn,
    String? timezoneIana,
  }) async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final updated = await _settingsRepository.updateCalendarSettings(
        weekStartsOn: weekStartsOn,
        timezone: timezoneIana,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _weekStartsOn = _normalizeWeekStart(updated.weekStartsOn);
        _timezoneIana = updated.timezone;
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.response?.statusCode == 400
            ? '\u041d\u0435\u043a\u043e\u0440\u0440\u0435\u043a\u0442\u043d\u043e\u0435 \u0437\u043d\u0430\u0447\u0435\u043d\u0438\u0435 \u0434\u043b\u044f \u043d\u0430\u0441\u0442\u0440\u043e\u0435\u043a \u043a\u0430\u043b\u0435\u043d\u0434\u0430\u0440\u044f.'
            : '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0441\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c \u043d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438 \u043a\u0430\u043b\u0435\u043d\u0434\u0430\u0440\u044f.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0441\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c \u043d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438 \u043a\u0430\u043b\u0435\u043d\u0434\u0430\u0440\u044f.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickWeekStart() async {
    if (_isSaving || _isLoading) {
      return;
    }
    final selected = await _showSelectionDialog<int>(
      title: '\u0414\u0435\u043d\u044c \u043d\u0430\u0447\u0430\u043b\u0430 \u043d\u0435\u0434\u0435\u043b\u0438',
      items: _weekStartOptions
          .map((option) => _SelectionItem<int>(value: option.value, label: option.label))
          .toList(growable: false),
      selectedValue: _weekStartsOn,
    );
    if (selected == null || selected == _weekStartsOn) {
      return;
    }
    setState(() => _weekStartsOn = selected);
    await _saveCalendarSettings(weekStartsOn: selected);
  }

  Future<void> _pickTimezone() async {
    if (_isSaving || _isLoading) {
      return;
    }
    final selected = await _showSelectionDialog<String>(
      title: '\u0427\u0430\u0441\u043e\u0432\u043e\u0439 \u043f\u043e\u044f\u0441',
      items: _timezoneOptions
          .map((option) => _SelectionItem<String>(value: option.iana, label: option.label))
          .toList(growable: false),
      selectedValue: _timezoneIana,
      maxHeight: 420,
    );
    if (selected == null || selected == _timezoneIana) {
      return;
    }
    setState(() => _timezoneIana = selected);
    await _saveCalendarSettings(timezoneIana: selected);
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
            const _SectionTitle('\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435 \u043d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438'),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                children: [
                  _ClickableRow(
                    title: '\u0414\u0435\u043d\u044c \u043d\u0430\u0447\u0430\u043b\u0430 \u043d\u0435\u0434\u0435\u043b\u0438:',
                    trailingText: _weekStartLabel(_weekStartsOn),
                    enabled: !controlsDisabled,
                    onTap: _pickWeekStart,
                  ),
                  const _InnerDivider(),
                  _ClickableRow(
                    title: '\u0427\u0430\u0441\u043e\u0432\u043e\u0439 \u043f\u043e\u044f\u0441:',
                    trailingText: _timezoneLabel(_timezoneIana),
                    enabled: !controlsDisabled,
                    onTap: _pickTimezone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
                            colorName: _categories[i].color.toUpperCase(),
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

  Future<T?> _showSelectionDialog<T>({
    required String title,
    required List<_SelectionItem<T>> items,
    required T selectedValue,
    double maxHeight = 320,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: SettingsUiTokens.cardBackground,
          shape: const RoundedRectangleBorder(borderRadius: SettingsUiTokens.cardRadius),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                  const SizedBox(height: 10),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: SettingsUiTokens.divider,
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = item.value == selectedValue;
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? SettingsUiTokens.accentBlue
                                  : SettingsUiTokens.primaryText,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: SettingsUiTokens.accentBlue,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(item.value),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<_CategoryEditorResult?> _showCategoryEditorDialog({
    EventCategoryItem? initial,
  }) async {
    final titleController = TextEditingController(text: initial?.title ?? '');
    var selectedColor = (initial?.color ?? _categoryPalette.first).toUpperCase();

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
                            color: _parseHexColor(color),
                            selected: selectedColor == color,
                            onTap: () => setDialogState(() {
                              selectedColor = color;
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

  int _normalizeWeekStart(int raw) => raw == 7 ? 7 : 1;

  String _weekStartLabel(int value) {
    for (final option in _weekStartOptions) {
      if (option.value == value) {
        return option.label;
      }
    }
    return '\u041f\u043e\u043d\u0435\u0434\u0435\u043b\u044c\u043d\u0438\u043a';
  }

  String _timezoneLabel(String iana) {
    for (final option in _timezoneOptions) {
      if (option.iana == iana) {
        return option.label;
      }
    }
    return _gmtLabelFromIana(iana) ?? 'GMT+0';
  }

  String? _gmtLabelFromIana(String iana) {
    final upper = iana.toUpperCase();
    if (upper.startsWith('GMT') || upper.startsWith('UTC')) {
      final normalized = upper.replaceAll('UTC', 'GMT').replaceAll(' ', '');
      if (normalized == 'GMT') {
        return 'GMT+0';
      }
      final signIndex = normalized.indexOf(RegExp(r'[+-]'));
      if (signIndex > 0 && signIndex < normalized.length - 1) {
        final sign = normalized[signIndex];
        final rawNumber = normalized.substring(signIndex + 1);
        final number = int.tryParse(rawNumber);
        if (number != null) {
          return 'GMT$sign$number';
        }
      }
    }
    return null;
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

class _ClickableRow extends StatelessWidget {
  const _ClickableRow({
    required this.title,
    required this.trailingText,
    required this.onTap,
    required this.enabled,
  });

  final String title;
  final String trailingText;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 34,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: SettingsUiTokens.primaryText,
                ),
              ),
            ),
            Text(
              trailingText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: SettingsUiTokens.mutedText,
              ),
            ),
            const SizedBox(width: 8),
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

class _InnerDivider extends StatelessWidget {
  const _InnerDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Divider(
        height: 1,
        thickness: 1,
        color: SettingsUiTokens.divider,
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
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
    );
  }
}

class _WeekStartOption {
  const _WeekStartOption({
    required this.value,
    required this.label,
  });

  final int value;
  final String label;
}

class _TimezoneOption {
  const _TimezoneOption({
    required this.label,
    required this.iana,
  });

  final String label;
  final String iana;
}

class _SelectionItem<T> {
  const _SelectionItem({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
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

