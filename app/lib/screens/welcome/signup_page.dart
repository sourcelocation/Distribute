import 'package:distributeapp/blocs/auth_cubit.dart';
import 'package:distributeapp/core/preferences/settings_cubit.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a username and password")),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    await context.read<AuthCubit>().signup(username, password);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        state.maybeWhen(
          error: (msg) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Signup failed: $msg")));
          },
          authenticated: (user) {
            context.read<SettingsCubit>().setOnboardingCompleted(true);
            Navigator.of(
              context,
            ).popUntil((route) => route.settings.name != 'settings');
          },
          orElse: () {},
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(
                    AppIcons.personAdd,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Create Account",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Sign up for a new account.",
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
                        autofillHints: const [AutofillHints.newUsername],
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
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest.withAlpha(50),
                          prefixIcon: Icon(AppIcons.lockOutline),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _signup(),
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
                        onPressed: loading ? null : _signup,
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
                            : const Text("Sign Up"),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text("Already have an account? Log In"),
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
