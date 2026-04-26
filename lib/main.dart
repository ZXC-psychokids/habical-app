import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/api_client.dart';
import 'screens/auth/auth_stub_screen.dart';

const _authStubsEnabled = bool.fromEnvironment('AUTH_STUBS', defaultValue: false);

void main() {
  if (_authStubsEnabled) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthStubScreen(apiClient: ApiClient()),
      ),
    );
    return;
  }
  runApp(const HabicalApp());
}
