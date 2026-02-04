import 'package:flutter/material.dart';

class HoverableIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double? iconSize;
  final String? tooltip;
  final EdgeInsetsGeometry padding;

  const HoverableIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.iconSize,
    this.tooltip,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  State<HoverableIconButton> createState() => _HoverableIconButtonState();
}

class _HoverableIconButtonState extends State<HoverableIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ?? Theme.of(context).iconTheme.color ?? Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Tooltip(
          message: widget.tooltip ?? '',
          child: Padding(
            padding: widget.padding,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: _isHovered
                  ? 0.7
                  : 1.0, // Or we could use a brightness filter
              child: IconTheme(
                data: IconThemeData(color: color, size: widget.iconSize),
                child: widget.icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
