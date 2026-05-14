enum NavigationTab {
  home,
  calendar,
  friends,
  habits,
  settings,
}

class NavigationState {
  const NavigationState({
    required this.selectedTab,
    this.habitsFocusHabitId,
    this.openCalendarInDayMode = false,
  });

  factory NavigationState.initial() {
    return const NavigationState(
      selectedTab: NavigationTab.home,
    );
  }

  final NavigationTab selectedTab;
  final String? habitsFocusHabitId;
  final bool openCalendarInDayMode;

  int get selectedIndex => selectedTab.index;

  NavigationState copyWith({
    NavigationTab? selectedTab,
    String? habitsFocusHabitId,
    bool clearHabitsFocus = false,
    bool? openCalendarInDayMode,
  }) {
    return NavigationState(
      selectedTab: selectedTab ?? this.selectedTab,
      habitsFocusHabitId: clearHabitsFocus
          ? null
          : (habitsFocusHabitId ?? this.habitsFocusHabitId),
      openCalendarInDayMode:
          openCalendarInDayMode ?? this.openCalendarInDayMode,
    );
  }
}
