import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../repositories/auth_repository.dart';
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }
  void _startResendTimer() {
    setState(() {
      _canResendEmail = false;
      _resendCooldown = 120;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCooldown--;
      });

      if (_resendCooldown <= 0) {
        _resendTimer?.cancel();
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
      },
      builder: (context, state) {
        if (state is EmailVerificationSent) {
          return _buildVerificationSent(state.email);
        }
        return _buildAuthForm(state);
      },
    );
  }

  Widget _buildAuthForm(AuthState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _emailController,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 18,
              ),
              decoration: const InputDecoration(labelText: 'Email',),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter email';
                }
                if (!value.contains('@')) {
                  return 'Please enter valid email';
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
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
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
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: state is AuthLoading ? null : _submit,
              child: state is AuthLoading
                  ? const CircularProgressIndicator()
                  : Text(_isLogin ? 'Sign In' : 'Sign Up'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                });
              },
              child: Text(_isLogin
                  ? 'Create new account'
                  : 'I already have an account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSent(String email) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
                Icons.mark_email_read,
                size: 64,

          ),
            const SizedBox(height: 24),
            Text(
              'Verification Email Sent',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Please check your email $email and click the verification link',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.currentUser?.reload();
                    final user = FirebaseAuth.instance.currentUser;

                    if (user?.emailVerified ?? false) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email successfully verified!')),
                      );
                      // Очищаем возможные предыдущие ошибки
                      context.read<AuthBloc>().add(AuthCheckRequested());
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please verify your email first')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e is AuthException ? e.message : e.toString()}')),
                    );
                  }
                },
                child: Text('I have verified my email'),
              ),
            ),
            TextButton(
              onPressed: _canResendEmail ? () {
                context.read<AuthBloc>().add(
                  ResendVerificationRequested(email),
                );
                _startResendTimer();
              } : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Resend verification email'),
                  if (!_canResendEmail) ...[
                    const SizedBox(width: 8),
                    Text('($_resendCooldown)'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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