import 'package:distributeapp/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundScreen extends StatelessWidget {
  final GoRouterState? state;

  const NotFoundScreen({super.key, this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.warning,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              "Page Not Found",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "I said I wouldn't give you up. But I let you down :(",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (state?.error != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state!.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                context.go('/library');
              },
              icon: Icon(AppIcons.home),
              label: const Text("Go to Home"),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
