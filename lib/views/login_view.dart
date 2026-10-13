import 'package:flutter/material.dart';

import '../viewmodels/auth_viewmodel.dart';

/// 로그인 화면.
class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    widget.viewModel.login(_idController.text, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  final error = widget.viewModel.errorMessage;
                  final hint = widget.viewModel.loginHint;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.school, size: 56, color: scheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'LMS',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text('학습관리시스템', textAlign: TextAlign.center),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _idController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: '아이디',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: '비밀번호',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            error,
                            style: TextStyle(color: scheme.error),
                          ),
                        ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: widget.viewModel.loading ? null : _submit,
                        child: Text(
                          widget.viewModel.loading ? '로그인 중...' : '로그인',
                        ),
                      ),
                      if (hint != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(
                            hint,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
