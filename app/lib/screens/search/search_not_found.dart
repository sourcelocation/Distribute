import 'package:flutter/material.dart';

class SearchNotFoundWidget extends StatelessWidget {
  final VoidCallback? onRequestTap;

  const SearchNotFoundWidget({super.key, this.onRequestTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      alignment: Alignment.topLeft,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("No results found :(", style: theme.bodyLarge),
            Text(
              "Did you know you can request songs to be added to the server?",
              style: theme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                onRequestTap?.call();
              },
              child: const Text("Request a song"),
            ),
          ],
        ),
      ),
    );
  }
}
