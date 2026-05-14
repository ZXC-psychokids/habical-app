import 'package:flutter_bloc/flutter_bloc.dart';

import 'navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(NavigationState.initial());

  void selectTab(NavigationTab tab) {
    if (state.selectedTab == tab &&
        !state.openCalendarInDayMode &&
        state.habitsFocusHabitId == null) {
      return;
    }
    emit(
      state.copyWith(
        selectedTab: tab,
        openCalendarInDayMode: false,
        clearHabitsFocus: true,
      ),
    );
  }

  void openCalendarDayTab() {
    emit(
      state.copyWith(
        selectedTab: NavigationTab.calendar,
        openCalendarInDayMode: true,
        clearHabitsFocus: true,
      ),
    );
  }

  void openHabitsTab({String? focusHabitId}) {
    emit(
      state.copyWith(
        selectedTab: NavigationTab.habits,
        habitsFocusHabitId: focusHabitId,
        openCalendarInDayMode: false,
      ),
    );
  }

  void selectIndex(int index) {
    if (index < 0 || index >= NavigationTab.values.length) {
      return;
    }
    selectTab(NavigationTab.values[index]);
  }
}
