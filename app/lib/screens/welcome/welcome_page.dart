import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomePage({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // App Icon
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/icon/icon-rounded.png',
                width: 120,
                height: 120,
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Welcome Text
          Text(
            "Welcome to Distribute",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            "Your decentralized, offline-first music player.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Get Started",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
