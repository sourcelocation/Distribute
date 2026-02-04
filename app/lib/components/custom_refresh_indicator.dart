import 'package:flutter/material.dart';

class CustomRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      edgeOffset: MediaQuery.of(context).padding.top,
      // (Platform.isMacOS ? 58.0 : kToolbarHeight),
      onRefresh: onRefresh,
      child: child,
    );
  }
}
