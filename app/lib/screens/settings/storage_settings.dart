import 'dart:io';

import 'package:distributeapp/blocs/storage/storage_cubit.dart';
import 'package:distributeapp/core/preferences/settings_cubit.dart';
import 'package:distributeapp/core/preferences/settings_state.dart';
import 'package:distributeapp/components/blurry_app_bar.dart';
import 'package:distributeapp/core/service_locator.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:distributeapp/components/hoverable_area.dart';

class StorageSettingsScreen extends StatelessWidget {
  const StorageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<StorageCubit>(),
      child: const _StorageSettingsView(),
    );
  }
}

class _StorageSettingsView extends StatefulWidget {
  const _StorageSettingsView();

  @override
  State<_StorageSettingsView> createState() => _StorageSettingsViewState();
}

class _StorageSettingsViewState extends State<_StorageSettingsView> {
  int _songsSize = 0;
  int _otherSize = 0;
  bool _calculating = true;

  @override
  void initState() {
    super.initState();
    _calculateStorage();
  }

  Future<void> _calculateStorage() async {
    if (!mounted) return;

    final settingsCubit = context.read<SettingsCubit>();
    String currentPath = settingsCubit.state.rootPath;

    // Check total size
    final rootDir = Directory(currentPath);
    int totalRoot = 0;
    if (await rootDir.exists()) {
      totalRoot = await _dirSize(rootDir);
    }

    int songs = 0;
    int other = 0;

    // Check downloads size only
    final downloadsDir = Directory('$currentPath/downloaded');
    if (await downloadsDir.exists()) {
      songs = await _dirSize(downloadsDir);
    }

    // Everything else in root is "other" (artwork, etc)
    other = totalRoot - songs;
    if (other < 0) other = 0; // safety

    if (mounted) {
      setState(() {
        _songsSize = songs;
        _otherSize = other > 0 ? other : 0;
        _calculating = false;
      });
    }
  }

  Future<int> _dirSize(Directory dir) async {
    int total = 0;
    try {
      if (await dir.exists()) {
        await for (var entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            total += await entity.length();
          }
        }
      }
    } catch (e) {
      debugPrint("Error calculating size: $e");
    }
    return total;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Listen to storage cubit for dialogs/feedback
    return BlocListener<StorageCubit, StorageState>(
      listener: (context, state) {
        state.maybeWhen(
          orElse: () {},
          insufficientSpace: (requiredBytes, availableBytes, pendingPath) async {
            final proceed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text("Insufficient Storage"),
                content: Text(
                  "The selected location only has ${_formatBytes(availableBytes)} free, but your songs require ${_formatBytes(requiredBytes)}. \n\nDo you want to continue without copying existing songs?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text("Continue anyway"),
                  ),
                ],
              ),
            );

            if (!context.mounted) return;

            if (proceed == true) {
              context.read<StorageCubit>().confirmMoveWithoutTransfer(
                pendingPath,
              );
            } else {
              context.read<StorageCubit>().reset();
            }
          },
          success: () {
            _calculateStorage(); // Refresh UI
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Storage location updated")),
            );
          },
          error: (msg) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Error: $msg")));
          },
        );
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: BlurryAppBar(
          center: Text("Storage", style: theme.textTheme.titleMedium),
        ),
        body: _calculating
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  kToolbarHeight + MediaQuery.of(context).padding.top + 12,
                  16,
                  12,
                ),
                children: [
                  _buildUsageCard(theme),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "Downloads",
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLocationTile(context),
                ],
              ),
      ),
    );
  }

  Widget _buildUsageCard(ThemeData theme) {
    final total = _songsSize + _otherSize;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Used",
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatBytes(total),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (total > 0) ...[
                    Flexible(
                      flex: (_songsSize * 100).toInt(),
                      child: Container(color: theme.colorScheme.primary),
                    ),
                    Flexible(
                      flex: (_otherSize * 100).toInt(),
                      child: Container(color: theme.colorScheme.tertiary),
                    ),
                  ] else
                    Expanded(
                      child: Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _LegendItem(
                color: theme.colorScheme.primary,
                label: "Music",
                size: _formatBytes(_songsSize),
              ),
              const SizedBox(width: 16),
              _LegendItem(
                color: theme.colorScheme.tertiary,
                label: "Other",
                size: _formatBytes(_otherSize),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTile(BuildContext context) {
    // We listen to SettingsCubit for the PATH display
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final currentPath = settingsState.customDownloadPath ?? "Default";

        // We listen to StorageCubit for PROGRESS display
        return BlocBuilder<StorageCubit, StorageState>(
          builder: (context, storageState) {
            final isTransferring = storageState.maybeWhen(
              transferring: (_) => true,
              checking: () => true,
              orElse: () => false,
            );

            final progress = storageState.maybeWhen(
              transferring: (p) => p,
              orElse: () => 0.0,
            );

            return Card(
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: HoverableArea(
                borderRadius: BorderRadius.circular(12),
                onTap: isTransferring
                    ? null
                    : () async {
                        final String? selectedDirectory = await FilePicker
                            .platform
                            .getDirectoryPath();
                        if (selectedDirectory != null && context.mounted) {
                          context.read<StorageCubit>().requestMove(
                            selectedDirectory,
                          );
                        }
                      },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            AppIcons.folderOpen,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Storage Location",
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentPath,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (!isTransferring)
                            Icon(
                              AppIcons.edit,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                      if (isTransferring) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progress > 0 ? progress : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          progress > 0
                              ? "Moving files... ${(progress * 100).toInt()}%"
                              : "Checking availability...",
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String size;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 4),
        Text(
          size,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
