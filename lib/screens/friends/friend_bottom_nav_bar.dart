import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/navigation/navigation_cubit.dart';
import '../../cubits/navigation/navigation_state.dart';

class FriendBottomNavBar extends StatelessWidget {
  const FriendBottomNavBar({
    super.key,
    required this.selectedTab,
  });

  final NavigationTab selectedTab;

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD9D9D9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1D27334D),
              blurRadius: 10.1,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: tabs
              .map((item) {
                final isSelected = item.tab == selectedTab;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _navigateToRootTab(context, item.tab),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0277BC)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              isSelected
                                  ? item.activeIcon
                                  : item.inactiveIcon,
                              size: 22,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF1F1F1F),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                        ],
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

  void _navigateToRootTab(BuildContext context, NavigationTab tab) {
    try {
      context.read<NavigationCubit>().selectTab(tab);
    } catch (_) {
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
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
