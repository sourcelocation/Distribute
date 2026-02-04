import 'package:flutter/material.dart';

class SettingsIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;

  const SettingsIcon(this.icon, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? Colors.grey.withValues(alpha: 0.2)
        : Colors.grey.withValues(alpha: 0.1);

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: color ?? Theme.of(context).iconTheme.color,
        size: 22,
      ),
    );
  }
}
