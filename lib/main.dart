import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/api_client.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sessionService = SessionService(
    storage: SharedPreferencesSessionStorage(),
  );
  final apiClient = ApiClient(sessionService: sessionService);

  runApp(HabicalApp(apiClient: apiClient, sessionService: sessionService));
}
