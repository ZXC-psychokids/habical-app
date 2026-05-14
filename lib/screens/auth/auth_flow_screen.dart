import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../../repositories/auth_repository.dart';

enum _AuthPage {
  login,
  register,
  reset,
}

class AuthFlowScreen extends StatefulWidget {
  const AuthFlowScreen({
    super.key,
    required this.authRepository,
  });

  final AuthRepository authRepository;

  @override
  State<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends State<AuthFlowScreen> {
  final _loginController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerEmailController = TextEditingController();
  final _registerHandleController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerPasswordConfirmController = TextEditingController();

  final _resetEmailController = TextEditingController();

  _AuthPage _page = _AuthPage.login;
  bool _isLoading = false;
  bool _loginPasswordVisible = false;
  bool _registerPasswordVisible = false;
  bool _registerPasswordConfirmVisible = false;

  String? _loginError;
  String? _registerError;
  String? _resetError;
  String? _resetSuccess;

  @override
  void dispose() {
    _loginController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerHandleController.dispose();
    _registerPasswordController.dispose();
    _registerPasswordConfirmController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _isLoading,
          child: Column(
            children: [
              if (_isLoading) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                  child: _buildPage(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage() {
    return switch (_page) {
      _AuthPage.login => _buildLoginPage(),
      _AuthPage.register => _buildRegisterPage(),
      _AuthPage.reset => _buildResetPage(),
    };
  }

  Widget _buildLoginPage() {
    return Column(
      key: const ValueKey('auth_login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const _AuthBrandHeader(),
        const SizedBox(height: 24),
        const _SectionTitle('Вход'),
        const SizedBox(height: 10),
        _AuthInput(
          controller: _loginController,
          hint: 'Почта или хендл',
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_loginError != null) {
              setState(() => _loginError = null);
            }
          },
        ),
        const SizedBox(height: 10),
        _AuthInput(
          controller: _loginPasswordController,
          hint: 'Пароль',
          obscureText: !_loginPasswordVisible,
          textInputAction: TextInputAction.done,
          suffix: _EyeButton(
            visible: _loginPasswordVisible,
            onTap: () => setState(() => _loginPasswordVisible = !_loginPasswordVisible),
          ),
          onSubmitted: (_) => _submitLogin(),
          onChanged: (_) {
            if (_loginError != null) {
              setState(() => _loginError = null);
            }
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() {
              _page = _AuthPage.reset;
              _loginError = null;
            }),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Забыли пароль?',
              style: TextStyle(
                color: Color(0xFF0277BC),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (_loginError != null) ...[
          const SizedBox(height: 8),
          _ErrorText(_loginError!),
        ],
        const SizedBox(height: 28),
        _PrimaryButton(
          text: 'Войти',
          onPressed: _submitLogin,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: () => setState(() {
              _page = _AuthPage.register;
              _loginError = null;
            }),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Нет аккаунта? Зарегистрироваться',
              style: TextStyle(
                color: Color(0xFF0277BC),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterPage() {
    return Column(
      key: const ValueKey('auth_register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const _AuthBrandHeader(),
        const SizedBox(height: 24),
        const _SectionTitle('Регистрация'),
        const SizedBox(height: 10),
        _AuthInput(
          controller: _registerEmailController,
          hint: 'Почта',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_registerError != null) {
              setState(() => _registerError = null);
            }
          },
        ),
        const SizedBox(height: 10),
        _AuthInput(
          controller: _registerHandleController,
          hint: 'Имя пользователя',
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_registerError != null) {
              setState(() => _registerError = null);
            }
          },
        ),
        const SizedBox(height: 10),
        _AuthInput(
          controller: _registerPasswordController,
          hint: 'Пароль',
          obscureText: !_registerPasswordVisible,
          textInputAction: TextInputAction.next,
          suffix: _EyeButton(
            visible: _registerPasswordVisible,
            onTap: () => setState(
              () => _registerPasswordVisible = !_registerPasswordVisible,
            ),
          ),
          onChanged: (_) {
            if (_registerError != null) {
              setState(() => _registerError = null);
            }
          },
        ),
        const SizedBox(height: 10),
        _AuthInput(
          controller: _registerPasswordConfirmController,
          hint: 'Повторите пароль',
          obscureText: !_registerPasswordConfirmVisible,
          textInputAction: TextInputAction.done,
          suffix: _EyeButton(
            visible: _registerPasswordConfirmVisible,
            onTap: () => setState(
              () => _registerPasswordConfirmVisible = !_registerPasswordConfirmVisible,
            ),
          ),
          onSubmitted: (_) => _submitRegister(),
          onChanged: (_) {
            if (_registerError != null) {
              setState(() => _registerError = null);
            }
          },
        ),
        if (_registerError != null) ...[
          const SizedBox(height: 10),
          _ErrorText(_registerError!),
        ],
        const SizedBox(height: 28),
        _PrimaryButton(
          text: 'Зарегистрироваться',
          onPressed: _submitRegister,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: () => setState(() {
              _page = _AuthPage.login;
              _registerError = null;
            }),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Уже есть аккаунт? Войти',
              style: TextStyle(
                color: Color(0xFF0277BC),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetPage() {
    return Column(
      key: const ValueKey('auth_reset'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const _AuthBrandHeader(),
        const SizedBox(height: 24),
        const _SectionTitle('Восстановление пароля'),
        const SizedBox(height: 10),
        _AuthInput(
          controller: _resetEmailController,
          hint: 'Почта',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitReset(),
          onChanged: (_) {
            if (_resetError != null || _resetSuccess != null) {
              setState(() {
                _resetError = null;
                _resetSuccess = null;
              });
            }
          },
        ),
        if (_resetError != null) ...[
          const SizedBox(height: 10),
          _ErrorText(_resetError!),
        ],
        if (_resetSuccess != null) ...[
          const SizedBox(height: 10),
          Text(
            _resetSuccess!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF228B22),
            ),
          ),
        ],
        const SizedBox(height: 28),
        _PrimaryButton(
          text: 'Отправить',
          onPressed: _submitReset,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: () => setState(() {
              _page = _AuthPage.login;
              _resetError = null;
              _resetSuccess = null;
            }),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Вернуться на главный экран',
              style: TextStyle(
                color: Color(0xFF0277BC),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitLogin() async {
    final login = _loginController.text.trim();
    final password = _loginPasswordController.text;
    if (login.isEmpty || password.isEmpty) {
      setState(() {
        _loginError = 'Введите почту/хендл и пароль.';
      });
      return;
    }

    await _runAction(
      () => widget.authRepository.login(login: login, password: password),
      onError: (message) => setState(() => _loginError = message),
    );
  }

  Future<void> _submitRegister() async {
    final email = _registerEmailController.text.trim();
    final handle = _registerHandleController.text.trim();
    final password = _registerPasswordController.text;
    final confirmation = _registerPasswordConfirmController.text;

    if (email.isEmpty || handle.isEmpty || password.isEmpty || confirmation.isEmpty) {
      setState(() {
        _registerError = 'Заполните все поля регистрации.';
      });
      return;
    }
    if (password != confirmation) {
      setState(() {
        _registerError = 'Пароли не совпадают.';
      });
      return;
    }

    await _runAction(
      () => widget.authRepository.register(
        email: email,
        handle: handle,
        password: password,
        passwordConfirmation: confirmation,
      ),
      onError: (message) => setState(() => _registerError = message),
    );
  }

  Future<void> _submitReset() async {
    final email = _resetEmailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _resetError = 'Введите почту для восстановления.';
      });
      return;
    }

    await _runAction(
      () => widget.authRepository.requestPasswordReset(email: email),
      onSuccess: () {
        setState(() {
          _resetSuccess = 'Инструкции отправлены на почту.';
          _resetError = null;
        });
      },
      onError: (message) => setState(() => _resetError = message),
    );
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    VoidCallback? onSuccess,
    required ValueChanged<String> onError,
  }) async {
    if (_isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      await action();
      if (!mounted) {
        return;
      }
      onSuccess?.call();
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      onError(_extractError(error));
    } catch (_) {
      if (!mounted) {
        return;
      }
      onError('Не удалось выполнить запрос. Попробуйте снова.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _extractError(DioException error) {
    final friendly = _friendlyAuthError(error);
    if (friendly != null) {
      return friendly;
    }

    final responseData = error.response?.data;
    if (responseData is Map && responseData['message'] is String) {
      return _normalizeMessage(responseData['message'] as String);
    }
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return _normalizeMessage(message);
    }
    return 'Не удалось выполнить запрос. Попробуйте снова.';
  }

  String? _friendlyAuthError(DioException error) {
    final status = error.response?.statusCode;
    final path = error.requestOptions.path;

    if (path == '/auth/login') {
      if (status == 401) {
        return 'Неверная почта, хендл или пароль.';
      }
      if (status == 400) {
        return 'Заполните почту/хендл и пароль.';
      }
    }

    if (path == '/auth/register') {
      if (status == 400) {
        return 'Проверьте поля регистрации: почта, хендл и пароли.';
      }
      if (status == 409) {
        return 'Пользователь с такой почтой или хендлом уже существует.';
      }
    }

    if (path == '/auth/password-reset/request') {
      if (status == 400) {
        return 'Проверьте корректность почты.';
      }
    }

    if (path == '/auth/password-reset/confirm') {
      if (status == 400) {
        return 'Проверьте токен и совпадение нового пароля.';
      }
    }

    return null;
  }

  String _normalizeMessage(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Не удалось выполнить запрос. Попробуйте снова.';
    }

    final looksMojibake = trimmed.contains('Р') &&
        (trimmed.contains('С') || trimmed.contains('Ð') || trimmed.contains('Ñ'));
    if (!looksMojibake) {
      return trimmed;
    }

    try {
      final bytes = latin1.encode(trimmed);
      final decoded = utf8.decode(bytes);
      if (decoded.trim().isNotEmpty) {
        return decoded.trim();
      }
    } catch (_) {}

    return trimmed;
  }
}

class _AuthBrandHeader extends StatelessWidget {
  const _AuthBrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Habical',
        style: TextStyle(
          fontSize: 49,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0277BC),
          letterSpacing: -0.6,
          height: 1,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0277BC),
        letterSpacing: -0.4,
      ),
    );
  }
}

class _AuthInput extends StatelessWidget {
  const _AuthInput({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffix,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1C1C1E),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 15,
          color: Color(0xFFB0B0B5),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFD6D6DA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFF0277BC)),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0277BC),
          elevation: 2,
          shadowColor: const Color(0x40000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class _EyeButton extends StatelessWidget {
  const _EyeButton({
    required this.visible,
    required this.onTap,
  });

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: const Color(0xFF8E8E93),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFCC2D2D),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
