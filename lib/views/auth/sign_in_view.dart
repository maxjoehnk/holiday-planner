import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/services/auth_service.dart';

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

enum _Stage { entry, sending, sent }

class _SignInViewState extends State<SignInView> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _Stage _stage = _Stage.entry;
  String? _error;
  StreamSubscription<void>? _autoCloseSub;

  @override
  void initState() {
    super.initState();
    // Once Dart's Supabase SDK completes the magic-link flow, AuthService
    // emits a signed-in user — dismiss this screen automatically.
    _autoCloseSub = AuthService.instance.changes.listen((user) {
      if (user != null && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _autoCloseSub?.cancel();
    _emailController.dispose();
    // If the user backs out while a desktop magic-link is still waiting on
    // the email click, tear down the loopback listener.
    AuthService.instance.cancelPendingSignIn();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _stage = _Stage.sending;
      _error = null;
    });
    try {
      await AuthService.instance.sendMagicLink(email: _emailController.text.trim());
      if (!mounted) return;
      setState(() => _stage = _Stage.sent);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.entry;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _stage == _Stage.sent ? _buildSent() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sign in to sync trips across your devices and share them with others.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Email is required';
              if (!text.contains('@')) return 'Enter a valid email';
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: _stage == _Stage.sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.mail_outline),
            label: const Text('Send magic link'),
            onPressed: _stage == _Stage.sending ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildSent() {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.mark_email_read_outlined, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('Check your email', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'We sent a magic link to ${_emailController.text.trim()}. Open it on this device to finish signing in.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => setState(() => _stage = _Stage.entry),
          child: const Text('Use a different email'),
        ),
      ],
    );
  }
}
