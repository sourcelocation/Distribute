import 'package:distributeapp/theme/app_icons.dart';
import 'package:flutter/material.dart';

class ErrorMessage extends StatelessWidget {
  final String message;

  const ErrorMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    debugPrint(message);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.errorOutline, color: Colors.redAccent, size: 40),
        const SizedBox(height: 10),
        Text(message, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
