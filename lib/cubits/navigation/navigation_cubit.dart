import 'package:flutter_bloc/flutter_bloc.dart';

import 'navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(NavigationState.initial());

  void selectTab(NavigationTab tab) {
    if (state.selectedTab == tab) {
      return;
    }
    emit(state.copyWith(selectedTab: tab));
  }

  void selectIndex(int index) {
    if (index < 0 || index >= NavigationTab.values.length) {
      return;
    }
    selectTab(NavigationTab.values[index]);
  }
}
