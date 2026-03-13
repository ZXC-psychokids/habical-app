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

class _RootView extends StatelessWidget {
  const _RootView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        return Scaffold(
          body: _screenByTab(state.selectedTab),
          bottomNavigationBar: _BottomNavigationBar(
            selectedTab: state.selectedTab,
            onTap: (tab) => context.read<NavigationCubit>().selectTab(tab),
          ),
        );
      },
    );
  }

  Widget _screenByTab(NavigationTab tab) {
    return switch (tab) {
      NavigationTab.home => const HomeScreen(),
      NavigationTab.calendar => const CalendarScreen(),
      NavigationTab.friends => const FriendsScreen(),
      NavigationTab.habits => const HabitsScreen(),
      NavigationTab.settings => const SettingsScreen(),
    };
  }
}

class _BottomNavigationBar extends StatelessWidget {
  const _BottomNavigationBar({
    required this.selectedTab,
    required this.onTap,
  });

  final NavigationTab selectedTab;
  final ValueChanged<NavigationTab> onTap;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      _NavItemData(
        tab: NavigationTab.home,
        label: 'Главная',
        inactiveIcon: Icons.home_outlined,
        activeIcon: Icons.home,
      ),
      _NavItemData(
        tab: NavigationTab.calendar,
        label: 'Календарь',
        inactiveIcon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month,
      ),
      _NavItemData(
        tab: NavigationTab.friends,
        label: 'Друзья',
        inactiveIcon: Icons.person_outline,
        activeIcon: Icons.person,
      ),
      _NavItemData(
        tab: NavigationTab.habits,
        label: 'Привычки',
        inactiveIcon: Icons.check_box_outlined,
        activeIcon: Icons.check_box,
      ),
      _NavItemData(
        tab: NavigationTab.settings,
        label: 'Настройки',
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
          children: tabs.map((item) {
            final isSelected = item.tab == selectedTab;
            return Expanded(
              child: _NavItem(
                label: item.label,
                icon: isSelected ? item.activeIcon : item.inactiveIcon,
                selected: isSelected,
                onTap: () => onTap(item.tab),
              ),
            );
          }).toList(growable: false),
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
