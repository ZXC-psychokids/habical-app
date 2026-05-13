import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/app.dart';
import 'core/app_bloc_observer.dart';
import 'core/app_logger.dart';
import 'core/api_client.dart';
import 'services/session_service.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        AppLogger.e(
          'FlutterError.onError',
          details.exception,
          details.stack,
        );
        FlutterError.presentError(details);
      };

      PlatformDispatcher.instance.onError = (error, stackTrace) {
        AppLogger.e(
          'PlatformDispatcher.instance.onError',
          error,
          stackTrace,
        );
        return true;
      };

      Bloc.observer = const AppBlocObserver();

      final sessionService = SessionService(
        storage: SharedPreferencesSessionStorage(),
      );
      final apiClient = ApiClient(sessionService: sessionService);

      runApp(HabicalApp(apiClient: apiClient, sessionService: sessionService));
    },
    (error, stackTrace) {
      AppLogger.e(
        'runZonedGuarded uncaught error',
        error,
        stackTrace,
      );
    },
  );
}
