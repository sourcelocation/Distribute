import 'package:flutter/material.dart';

class SettingsIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;

  const SettingsIcon(this.icon, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    // Determine background color based on brightness to ensure "gray" look in both modes.
    // However, using surfaceContainerHighest is usually the "standard" way to get a neutral background in M3.
    // If the user strictly wants gray, we can force it, but let's try to be adaptive first.
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // A nice accessible gray.
    final bgColor = isDark
        ? Colors.grey.withOpacity(0.2)
        : Colors.grey.withOpacity(0.1);

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10), // Rounded rectangle
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        // If color is not provided, use the theme's icon color or primary color?
        // Usually settings icons are colored or just standard icon color.
        // Let's stick to the default icon theme unless specified.
        color: color ?? Theme.of(context).iconTheme.color,
        size: 22,
      ),
    );
  }
}
