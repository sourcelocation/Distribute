import 'package:distributeapp/components/hoverable_area.dart';
import 'package:flutter/material.dart';

class HoverableListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final BorderRadius? borderRadius;

  const HoverableListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
  });

  @override
  Widget build(BuildContext context) {
    return HoverableArea(
      onTap: enabled ? onTap : null,
      borderRadius: borderRadius,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        enabled: enabled,
        // Set onTap to null here so HoverableArea handles it
        // But we want visual disabled state if enabled is false
        onTap: null,
      ),
    );
  }
}
