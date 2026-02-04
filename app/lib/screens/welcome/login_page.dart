import 'package:distributeapp/blocs/auth_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool canSkip;

  const LoginPage({
    super.key,
    required this.onNext,
    required this.onBack,
    this.canSkip = true,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a username and password")),
      );
      return;
    }
    await context.read<AuthCubit>().login(username, password);

    if (!mounted) return;

    context.read<AuthCubit>().state.maybeWhen(
      authenticated: (user) {
        widget.onNext();
      },
      error: (msg) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
      orElse: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        state.maybeWhen(
          error: (msg) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Login failed: $msg")));
          },
          authenticated: (user) {},
          orElse: () {},
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            // Handle keyboard
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(
                    AppIcons.account,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Who are you?",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Log in to your account.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                AutofillGroup(
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest.withAlpha(50),
                          prefixIcon: Icon(AppIcons.person),
                        ),
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest.withAlpha(50),
                          prefixIcon: Icon(AppIcons.lock),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        autofillHints: const [AutofillHints.password],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final loading = state.maybeWhen(
                        loading: () => true,
                        orElse: () => false,
                      );
                      return FilledButton(
                        onPressed: loading ? null : _login,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Log In"),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () => context.push('/signup'),
                        child: const Text("Don't have an account? Sign Up"),
                      ),
                      if (widget.canSkip)
                        TextButton(
                          onPressed: widget.onNext,
                          child: const Text("Skip Login"),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
