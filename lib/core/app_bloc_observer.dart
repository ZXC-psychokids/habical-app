import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_logger.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppLogger.e(
      'Bloc error in ${bloc.runtimeType}',
      error,
      stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}
