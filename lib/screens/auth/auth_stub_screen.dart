import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api_client.dart';

class AuthStubScreen extends StatefulWidget {
  const AuthStubScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<AuthStubScreen> createState() => _AuthStubScreenState();
}

class _AuthStubScreenState extends State<AuthStubScreen> {
  final _loginController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerEmailController = TextEditingController();
  final _registerHandleController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerPasswordConfirmController = TextEditingController();

  final _resetEmailController = TextEditingController();

  final _resetTokenController = TextEditingController();
  final _resetNewPasswordController = TextEditingController();
  final _resetNewPasswordConfirmController = TextEditingController();

  final _confirmEmailController = TextEditingController();
  final _confirmCodeController = TextEditingController();

  bool _isLoading = false;
  String _result = 'Ready';

  @override
  void dispose() {
    _loginController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerHandleController.dispose();
    _registerPasswordController.dispose();
    _registerPasswordConfirmController.dispose();
    _resetEmailController.dispose();
    _resetTokenController.dispose();
    _resetNewPasswordController.dispose();
    _resetNewPasswordConfirmController.dispose();
    _confirmEmailController.dispose();
    _confirmCodeController.dispose();
    super.dispose();
  }

  Future<void> _runRequest(Future<Response<dynamic>> Function() request) async {
    if (_isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
      _result = 'Loading...';
    });

    try {
      final response = await request();
      setState(() {
        _result = 'HTTP ${response.statusCode}\n${_pretty(response.data)}';
      });
    } on DioException catch (error) {
      final code = error.response?.statusCode;
      final data = error.response?.data;
      setState(() {
        _result = 'HTTP ${code ?? '-'}\n${_pretty(data ?? error.message)}';
      });
    } catch (error) {
      setState(() {
        _result = 'Error\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _pretty(dynamic value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value?.toString() ?? 'null';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dio = widget.apiClient.dio;

    return Scaffold(
      appBar: AppBar(title: const Text('Auth Stubs')),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _Section(
              title: 'Login',
              children: [
                _field(_loginController, 'login (email or handle)'),
                _field(_loginPasswordController, 'password', obscure: true),
                ElevatedButton(
                  onPressed: () => _runRequest(
                    () => dio.post(
                      '/auth/login',
                      data: {
                        'login': _loginController.text.trim(),
                        'password': _loginPasswordController.text,
                      },
                    ),
                  ),
                  child: const Text('POST /auth/login'),
                ),
              ],
            ),
            _Section(
              title: 'Register',
              children: [
                _field(_registerEmailController, 'email'),
                _field(_registerHandleController, 'handle'),
                _field(_registerPasswordController, 'password', obscure: true),
                _field(
                  _registerPasswordConfirmController,
                  'passwordConfirmation',
                  obscure: true,
                ),
                ElevatedButton(
                  onPressed: () => _runRequest(
                    () => dio.post(
                      '/auth/register',
                      data: {
                        'email': _registerEmailController.text.trim(),
                        'handle': _registerHandleController.text.trim(),
                        'password': _registerPasswordController.text,
                        'passwordConfirmation':
                            _registerPasswordConfirmController.text,
                      },
                    ),
                  ),
                  child: const Text('POST /auth/register'),
                ),
              ],
            ),
            _Section(
              title: 'Password Reset Request',
              children: [
                _field(_resetEmailController, 'email'),
                ElevatedButton(
                  onPressed: () => _runRequest(
                    () => dio.post(
                      '/auth/password-reset/request',
                      data: {
                        'email': _resetEmailController.text.trim(),
                      },
                    ),
                  ),
                  child: const Text('POST /auth/password-reset/request'),
                ),
              ],
            ),
            _Section(
              title: 'Password Reset Confirm',
              children: [
                _field(_resetTokenController, 'token'),
                _field(_resetNewPasswordController, 'newPassword', obscure: true),
                _field(
                  _resetNewPasswordConfirmController,
                  'newPasswordConfirmation',
                  obscure: true,
                ),
                ElevatedButton(
                  onPressed: () => _runRequest(
                    () => dio.post(
                      '/auth/password-reset/confirm',
                      data: {
                        'token': _resetTokenController.text.trim(),
                        'newPassword': _resetNewPasswordController.text,
                        'newPasswordConfirmation':
                            _resetNewPasswordConfirmController.text,
                      },
                    ),
                  ),
                  child: const Text('POST /auth/password-reset/confirm'),
                ),
              ],
            ),
            _Section(
              title: 'Email Confirmation (stub)',
              children: [
                _field(_confirmEmailController, 'email'),
                _field(_confirmCodeController, 'code'),
                ElevatedButton(
                  onPressed: () => _runRequest(
                    () => dio.post(
                      '/auth/email-confirm/request',
                      data: {
                        'email': _confirmEmailController.text.trim(),
                      },
                    ),
                  ),
                  child: const Text('POST /auth/email-confirm/request'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _runRequest(
                    () => dio.post(
                      '/auth/email-confirm/confirm',
                      data: {
                        'email': _confirmEmailController.text.trim(),
                        'code': _confirmCodeController.text.trim(),
                      },
                    ),
                  ),
                  child: const Text('POST /auth/email-confirm/confirm'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Result'),
            const SizedBox(height: 6),
            SelectableText(_result),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
