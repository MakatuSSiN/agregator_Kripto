import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';

class VerificationSentWidget extends StatelessWidget {
  final String email;
  final bool canResend;
  final int resendCooldown;
  final VoidCallback onResendPressed;
  final VoidCallback onVerifiedPressed;

  const VerificationSentWidget({
    super.key,
    required this.email,
    required this.canResend,
    required this.resendCooldown,
    required this.onResendPressed,
    required this.onVerifiedPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
        child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_read,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 24),
            Text(
              'Письмо с подтверждением отправлено',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Пожалуйста, проверьте свою почту $email и перейдите по ссылке для подтверждения',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                onPressed: onVerifiedPressed,
                child: const Text('Я подтвердил свою почту'),
              ),
            ),
            TextButton(
              onPressed: canResend ? onResendPressed : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Повторно отправить письмо',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  if (!canResend) ...[
                    const SizedBox(width: 8),
                    Text(
                      '($resendCooldown)',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}