import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/navigation/navigation_cubit.dart';
import '../cubits/navigation/navigation_state.dart';
import 'calendar/calendar_screen.dart';
import 'friends/friends_screen.dart';
import 'habits/habits_screen.dart';
import 'home/home_screen.dart';
import 'settings/settings_screen.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NavigationCubit(),
      child: const _RootView(),
    );
  }
}

class _RootView extends StatefulWidget {
  const _RootView();

  @override
  State<_RootView> createState() => _RootViewState();
}

class _RootViewState extends State<_RootView> {
  CalendarScale _calendarScale = CalendarScale.week;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        return Scaffold(
          body: _screenByTab(state.selectedTab),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.selectedTab == NavigationTab.calendar)
                _CalendarScaleBar(
                  selectedScale: _calendarScale,
                  onTap: (scale) => setState(() => _calendarScale = scale),
                ),
              _BottomNavigationBar(
                selectedTab: state.selectedTab,
                onTap: (tab) => context.read<NavigationCubit>().selectTab(tab),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _screenByTab(NavigationTab tab) {
    return switch (tab) {
      NavigationTab.home => const HomeScreen(),
      NavigationTab.calendar => CalendarScreen(
        scale: _calendarScale,
        onOpenDayFromMonthTap: (_) {
          if (_calendarScale != CalendarScale.day) {
            setState(() => _calendarScale = CalendarScale.day);
          }
        },
      ),
      NavigationTab.friends => const FriendsScreen(),
      NavigationTab.habits => const HabitsScreen(),
      NavigationTab.settings => const SettingsScreen(),
    };
  }
}

class _CalendarScaleBar extends StatelessWidget {
  const _CalendarScaleBar({required this.selectedScale, required this.onTap});

  final CalendarScale selectedScale;
  final ValueChanged<CalendarScale> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x1A000000)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 10,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: CalendarScale.values
              .map((scale) {
                final selected = scale == selectedScale;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => onTap(scale),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFB7D8F1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              scale.icon,
                              size: 16,
                              color: selected
                                  ? const Color(0xFF0E2C4F)
                                  : const Color(0xFF505050),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              scale.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? const Color(0xFF0E2C4F)
                                    : const Color(0xFF505050),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  const _BottomNavigationBar({required this.selectedTab, required this.onTap});

  final NavigationTab selectedTab;
  final ValueChanged<NavigationTab> onTap;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      _NavItemData(
        tab: NavigationTab.home,
        label: '\u0413\u043b\u0430\u0432\u043d\u0430\u044f',
        inactiveIcon: Icons.home_outlined,
        activeIcon: Icons.home,
      ),
      _NavItemData(
        tab: NavigationTab.calendar,
        label: '\u041a\u0430\u043b\u0435\u043d\u0434\u0430\u0440\u044c',
        inactiveIcon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month,
      ),
      _NavItemData(
        tab: NavigationTab.friends,
        label: '\u0414\u0440\u0443\u0437\u044c\u044f',
        inactiveIcon: Icons.person_outline,
        activeIcon: Icons.person,
      ),
      _NavItemData(
        tab: NavigationTab.habits,
        label: '\u041f\u0440\u0438\u0432\u044b\u0447\u043a\u0438',
        inactiveIcon: Icons.check_box_outlined,
        activeIcon: Icons.check_box,
      ),
      _NavItemData(
        tab: NavigationTab.settings,
        label: '\u041d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438',
        inactiveIcon: Icons.settings_outlined,
        activeIcon: Icons.settings,
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x1A000000)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: tabs
              .map((item) {
                final isSelected = item.tab == selectedTab;
                return Expanded(
                  child: _NavItem(
                    label: item.label,
                    icon: isSelected ? item.activeIcon : item.inactiveIcon,
                    selected: isSelected,
                    onTap: () => onTap(item.tab),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.tab,
    required this.label,
    required this.inactiveIcon,
    required this.activeIcon,
  });

  final NavigationTab tab;
  final String label;
  final IconData inactiveIcon;
  final IconData activeIcon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? Colors.black : const Color(0xFF505050),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.black : const Color(0xFF505050),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
