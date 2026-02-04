import 'package:flutter/material.dart';

class OnboardingScaffold extends StatelessWidget {
  final Widget child;

  const OnboardingScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
