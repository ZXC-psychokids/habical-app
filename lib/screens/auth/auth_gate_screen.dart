import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../../services/session_service.dart';
import '../root_screen.dart';
import 'auth_flow_screen.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({
    super.key,
    required this.authRepository,
    required this.sessionService,
  });

  final AuthRepository authRepository;
  final SessionService sessionService;

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  bool _isBootstrapping = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await widget.sessionService.restore();

    if (widget.sessionService.isAuthenticated) {
      try {
        await widget.authRepository.fetchMe();
      } on DioException catch (error) {
        if (error.response?.statusCode == 401) {
          try {
            await widget.authRepository.refresh();
            await widget.authRepository.fetchMe();
          } catch (_) {
            await widget.sessionService.clear();
          }
        } else {
          await widget.sessionService.clear();
        }
      } catch (_) {
        await widget.sessionService.clear();
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isBootstrapping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isBootstrapping) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AnimatedBuilder(
      animation: widget.sessionService,
      builder: (context, _) {
        if (widget.sessionService.isAuthenticated) {
          return const RootScreen();
        }
        return AuthFlowScreen(authRepository: widget.authRepository);
      },
    );
  }
}
