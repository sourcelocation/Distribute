import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:io';

class BlurryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget? center;
  final List<Widget>? actions;

  const BlurryAppBar({super.key, this.leading, this.center, this.actions});

  @override
  Widget build(BuildContext context) {
    final isMac = Platform.isMacOS;
    final double macLeadingOffset = isMac ? 70.0 : 0.0;

    Widget? effectiveLeading = leading;

    final double titleLeftPadding = (isMac && effectiveLeading == null)
        ? macLeadingOffset
        : 0.0;

    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: true,
      leading: effectiveLeading,
      leadingWidth: isMac ? 186 : null,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: titleLeftPadding),
        child: center,
      ),
      centerTitle: true,
      actions: actions,
      actionsPadding: const EdgeInsets.only(right: 8),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Theme.of(context).colorScheme.surface.withAlpha(128),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    final isMac = Platform.isMacOS;
    return Size.fromHeight(isMac ? 58.0 : kToolbarHeight);
  }
}
