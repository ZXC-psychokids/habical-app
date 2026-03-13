enum NavigationTab {
  home,
  calendar,
  friends,
  habits,
  settings,
}

class NavigationState {
  const NavigationState({required this.selectedTab});

  factory NavigationState.initial() {
    return const NavigationState(selectedTab: NavigationTab.home);
  }

  final NavigationTab selectedTab;

  int get selectedIndex => selectedTab.index;

  NavigationState copyWith({NavigationTab? selectedTab}) {
    return NavigationState(selectedTab: selectedTab ?? this.selectedTab);
  }
}
