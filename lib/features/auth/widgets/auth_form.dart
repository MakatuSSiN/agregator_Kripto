import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../repositories/auth_repository.dart';
import 'widgets.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({super.key});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _canResendEmail = false;
  int _resendCooldown = 120; // 120 секунд
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    // Проверяем, нужно ли запускать таймер сразу (если мы на экране подтверждения)
    if (context.read<AuthBloc>().state is EmailVerificationSent) {
      _startResendTimer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentState = context.read<AuthBloc>().state;
    if (currentState is EmailVerificationSent && _resendTimer == null) {
      _startResendTimer();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    // Сбрасываем предыдущий таймер, если он был
    _resendTimer?.cancel();

    setState(() {
      _canResendEmail = false;
      _resendCooldown = 120;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        _resendCooldown--;
      });

      if (_resendCooldown <= 0) {
        timer.cancel();
        setState(() {
          _canResendEmail = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is EmailVerificationSent) {
          _startResendTimer();
        }
      },
      builder: (context, state) {
        if (state is EmailVerificationSent) {
          return VerificationSentWidget(
            email: state.email,
            canResend: _canResendEmail,
            resendCooldown: _resendCooldown,
            onResendPressed: () {
              context.read<AuthBloc>().add(ResendVerificationRequested(state.email));
              _startResendTimer();
            },
            onVerifiedPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.reload();
                final user = FirebaseAuth.instance.currentUser;

                if (user?.emailVerified ?? false) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Почта успешно проверена!')),
                  );
                  context.read<AuthBloc>().add(AuthCheckRequested());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пожалуйста, подтвердите почту')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: ${e is AuthException ? e.message : e.toString()}')),
                );
              }
            },
          );
        }
        return _buildAuthForm(state);
      },
    );
  }

  Widget _buildAuthForm(AuthState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
    child: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            SizedBox(
              width: 200,
              height: 100,
              child: Image.asset(
                "assets/logoOMGEX.png",
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _emailController,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 18,
              ),
              decoration: InputDecoration(
                labelText: 'Электронная почта',
                labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.secondary
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, введите почту';
                }
                if (!value.contains('@')) {
                  return 'Пожалуйста, введите правильную почту';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 18,
              ),
              decoration: InputDecoration(
                labelText: 'Пароль',
                labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.secondary
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                ),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, введите пароль';
                }
                if (value.length < 6) {
                  return 'Пароль должен содержать не менее 6 символов';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (state is AuthError)
              Text(
                (state).message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
              onPressed: state is AuthLoading ? null : _submit,
              child: state is AuthLoading
                  ? const CircularProgressIndicator()
                  : Text(_isLogin ? 'Войти' : 'Зарегистрироваться'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                });
              },
              child: Text(_isLogin
                  ? 'Создать аккаунт'
                  : 'У меня есть аккаунт'),
            ),
          ],
        ),
      ),
    )
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final password = _passwordController.text;

      if (_isLogin) {
        context.read<AuthBloc>().add(SignInRequested(email, password));
      } else {
        context.read<AuthBloc>().add(SignUpRequested(email, password));
      }
    }
  }
}