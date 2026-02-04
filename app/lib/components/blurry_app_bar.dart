import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:distributeapp/components/hoverable_icon_button.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:go_router/go_router.dart';

class BlurryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget? center;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  const BlurryAppBar({
    super.key,
    this.leading,
    this.center,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMac = Platform.isMacOS;
    final double macLeadingOffset = isMac ? 70.0 : 0.0;

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null &&
        automaticallyImplyLeading &&
        context.canPop()) {
      effectiveLeading = HoverableIconButton(
        icon: Icon(AppIcons.arrowBack),
        onPressed: () => context.pop(),
        color: Theme.of(context).colorScheme.onSurface,
      );
    }

    final double titleLeftPadding = (isMac && effectiveLeading == null)
        ? macLeadingOffset
        : 0.0;

    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: automaticallyImplyLeading,
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
