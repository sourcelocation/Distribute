import 'package:flutter/material.dart';

class TagBadge extends StatelessWidget {
  final String message;
  final Color? color;
  final Color? bgColor;

  const TagBadge({
    super.key,
    this.message = '⚠︎ Not set',
    this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color ?? theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
