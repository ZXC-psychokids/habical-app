import 'package:flutter/material.dart';

import '../../cubits/navigation/navigation_state.dart';
import '../../models/friend_page_data.dart';
import '../../repositories/friends_repository.dart';
import 'friend_bottom_nav_bar.dart';

class FriendCalendarScreen extends StatefulWidget {
  const FriendCalendarScreen({
    super.key,
    required this.friendUserId,
    required this.friendHandle,
    required this.friendsRepository,
    required this.initialDay,
  });

  final String friendUserId;
  final String friendHandle;
  final FriendsRepository friendsRepository;
  final DateTime initialDay;

  @override
  State<FriendCalendarScreen> createState() => _FriendCalendarScreenState();
}

class _FriendCalendarScreenState extends State<FriendCalendarScreen> {
  late DateTime _selectedDay;
  bool _isLoading = false;
  String? _error;
  List<FriendEventPreview> _events = const <FriendEventPreview>[];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(
      widget.initialDay.year,
      widget.initialDay.month,
      widget.initialDay.day,
    );
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final events = await widget.friendsRepository.fetchFriendEvents(
        userId: widget.friendUserId,
        day: _selectedDay,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _events = const <FriendEventPreview>[];
        _isLoading = false;
        _error = 'Календарь скрыт настройками приватности.';
      });
    }
  }

  void _changeDay(int offset) {
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: offset));
    });
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      bottomNavigationBar: const FriendBottomNavBar(
        selectedTab: NavigationTab.calendar,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0277BC)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.friendHandle,
          style: const TextStyle(
            color: Color(0xFF0277BC),
            fontWeight: FontWeight.w700,
            fontSize: 30,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEvents,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(25, 8, 25, 20),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _isLoading ? null : () => _changeDay(-1),
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF0277BC),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatDate(_selectedDay),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => _changeDay(1),
                    icon: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF0277BC),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                      color: Color(0xFF0277BC),
                    ),
                  ),
                )
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(29, 39, 51, 0.30),
                        offset: Offset(0, 4),
                        blurRadius: 10.1,
                      ),
                    ],
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF777777),
                    ),
                  ),
                )
              else if (_events.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(29, 39, 51, 0.30),
                        offset: Offset(0, 4),
                        blurRadius: 10.1,
                      ),
                    ],
                  ),
                  child: const Text(
                    'На выбранный день событий нет.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF777777),
                    ),
                  ),
                )
              else
                ..._events.map((event) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(29, 39, 51, 0.30),
                            offset: Offset(0, 4),
                            blurRadius: 10.1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _hexToColor(event.categoryColor),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_timeLabel(event.startsAt)} - ${_timeLabel(event.endsAt)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFABABAB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = <String>[
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    const weekDays = <String>[
      'понедельник',
      'вторник',
      'среда',
      'четверг',
      'пятница',
      'суббота',
      'воскресенье',
    ];
    return '${date.day} ${months[date.month - 1]}, ${weekDays[date.weekday - 1]}';
  }

  String _timeLabel(DateTime value) {
    final local = value.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color _hexToColor(String rawValue) {
    var value = rawValue.trim();
    if (value.startsWith('#')) {
      value = value.substring(1);
    }
    if (value.length == 6) {
      value = 'FF$value';
    }
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) {
      return const Color(0xFF5AA9E6);
    }
    return Color(parsed);
  }
}
