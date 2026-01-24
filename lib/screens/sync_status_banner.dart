import 'dart:ui';
import 'package:distributeapp/blocs/sync_cubit.dart';
import 'package:distributeapp/core/sync_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SyncStatusBanner extends StatefulWidget {
  const SyncStatusBanner({super.key});

  @override
  State<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends State<SyncStatusBanner> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SyncCubit, SyncStatus>(
      listenWhen: (previous, current) {
        // We can add specific listeners here if needed, e.g. haptic feedback on error
        return false;
      },
      listener: (context, state) {},
      builder: (context, state) {
        final isVisible = state.maybeWhen(
          idle: () => false,
          orElse: () => true,
        );

        Color backgroundColor = Theme.of(
          context,
        ).colorScheme.surface.withAlpha(200);
        String message = "";
        IconData? icon;
        Color? iconColor;
        Color? textColor;

        state.when(
          idle: () {},
          syncing: () {
            message = "Syncing Library...";
            icon = Icons.sync;
            iconColor = Theme.of(context).colorScheme.primary;
            textColor = Theme.of(context).colorScheme.primary;
          },
          error: (msg) {
            message = "Sync Error: $msg";
            icon = Icons.error_outline;
            iconColor = Theme.of(context).colorScheme.error;
            textColor = Theme.of(context).colorScheme.error;
            backgroundColor = Theme.of(
              context,
            ).colorScheme.errorContainer.withAlpha(50);
          },
        );

        return AnimatedSlide(
          offset: isVisible ? Offset.zero : const Offset(0, 1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: GestureDetector(
            onTap: () {
              state.maybeWhen(
                error: (msg) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Sync Error"),
                      content: SingleChildScrollView(
                        child: SelectableText(msg),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                },
                orElse: () {},
              );
            },
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: backgroundColor,
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          if (state.maybeWhen(
                            syncing: () => true,
                            orElse: () => false,
                          ))
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: iconColor,
                              ),
                            )
                          else
                            Icon(icon, size: 16, color: iconColor),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            message,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
