import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../repositories/auth_repository.dart';

class AuthFlowScreen extends StatefulWidget {
  const AuthFlowScreen({
    super.key,
    required this.authRepository,
  });

  final AuthRepository authRepository;

  @override
  State<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends State<AuthFlowScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _loginController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerEmailController = TextEditingController();
  final _registerHandleController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerPasswordConfirmController = TextEditingController();

  final _resetEmailController = TextEditingController();
  final _resetTokenController = TextEditingController();
  final _resetPasswordController = TextEditingController();
  final _resetPasswordConfirmController = TextEditingController();

  bool _isLoading = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerHandleController.dispose();
    _registerPasswordController.dispose();
    _registerPasswordConfirmController.dispose();
    _resetEmailController.dispose();
    _resetTokenController.dispose();
    _resetPasswordController.dispose();
    _resetPasswordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      await action();
      if (!mounted) {
        return;
      }
      setState(() {
        _message = successMessage;
        _messageIsError = false;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      final responseData = error.response?.data;
      var details = 'Request failed.';
      if (responseData is Map && responseData['message'] is String) {
        details = responseData['message'] as String;
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        details = error.message!.trim();
      }
      setState(() {
        _message = details;
        _messageIsError = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = 'Request failed.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Login'),
            Tab(text: 'Register'),
            Tab(text: 'Reset'),
          ],
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLoginTab(),
            _buildRegisterTab(),
            _buildResetTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomMessage(),
    );
  }

  Widget _buildLoginTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _loginController,
          decoration: const InputDecoration(
            labelText: 'Login (email or handle)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _loginPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => _runAction(
            () => widget.authRepository.login(
              login: _loginController.text,
              password: _loginPasswordController.text,
            ),
            successMessage: 'Logged in.',
          ),
          child: const Text('Login'),
        ),
      ],
    );
  }

  Widget _buildRegisterTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _registerEmailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _registerHandleController,
          decoration: const InputDecoration(
            labelText: 'Handle',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _registerPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _registerPasswordConfirmController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password confirmation',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => _runAction(
            () => widget.authRepository.register(
              email: _registerEmailController.text,
              handle: _registerHandleController.text,
              password: _registerPasswordController.text,
              passwordConfirmation: _registerPasswordConfirmController.text,
            ),
            successMessage: 'Registered and logged in.',
          ),
          child: const Text('Register'),
        ),
      ],
    );
  }

  Widget _buildResetTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Request reset',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _resetEmailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () => _runAction(
            () => widget.authRepository.requestPasswordReset(
              email: _resetEmailController.text,
            ),
            successMessage: 'Reset request sent.',
          ),
          child: const Text('Request reset'),
        ),
        const Divider(height: 24),
        const Text(
          'Confirm reset',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _resetTokenController,
          decoration: const InputDecoration(
            labelText: 'Token',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _resetPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _resetPasswordConfirmController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New password confirmation',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => _runAction(
            () => widget.authRepository.confirmPasswordReset(
              token: _resetTokenController.text,
              newPassword: _resetPasswordController.text,
              newPasswordConfirmation: _resetPasswordConfirmController.text,
            ),
            successMessage: 'Password has been reset.',
          ),
          child: const Text('Confirm reset'),
        ),
      ],
    );
  }

  Widget _buildBottomMessage() {
    if (_isLoading) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (_message == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      color: _messageIsError
          ? const Color(0xFFFFEBEE)
          : const Color(0xFFE8F5E9),
      child: Text(
        _message!,
        style: TextStyle(
          color: _messageIsError ? const Color(0xFFB71C1C) : Colors.black,
        ),
      ),
    );
  }
}
