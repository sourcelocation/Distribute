import 'package:flutter/material.dart';

class HoverableArea extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;

  const HoverableArea({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
  });

  @override
  State<HoverableArea> createState() => _HoverableAreaState();
}

class _HoverableAreaState extends State<HoverableArea> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            color:
                (_isHovered &&
                    (widget.onTap != null || widget.onLongPress != null))
                ? Colors.white.withAlpha(20)
                : Colors.transparent,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
