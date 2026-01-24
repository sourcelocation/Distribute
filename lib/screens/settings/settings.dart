import 'package:distributeapp/blocs/auth_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:distributeapp/blocs/server_status_cubit.dart';
import 'package:distributeapp/components/error_badge.dart';
import 'package:distributeapp/core/database/database.dart';
import 'package:distributeapp/core/preferences/settings_cubit.dart';
import 'package:distributeapp/core/preferences/settings_state.dart';
import 'package:distributeapp/core/service_locator.dart';
import 'package:distributeapp/core/sync_manager.dart';
import 'package:distributeapp/main.dart';
import 'package:distributeapp/screens/settings/settings_profile_header.dart';

import 'package:distributeapp/components/blurry_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: BlurryAppBar(
        center: Text("Settings", style: theme.textTheme.titleMedium),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          6,
          kToolbarHeight + MediaQuery.of(context).padding.top + 6,
          6,
          6,
        ),
        children: const [
          SettingsProfileHeader(),
          _UserSection(),
          _ServerSection(),
          _DebugSection(),
          _AboutSection(),
        ],
      ),
    );
  }
}

class _UserSection extends StatelessWidget {
  const _UserSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final serverUrl = settingsState.serverURL;
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final loggedInUser = authState.maybeWhen(
              authenticated: (user) => user,
              orElse: () => null,
            );

            final isLoading = authState.maybeWhen(
              loading: () => true,
              orElse: () => false,
            );

            if (loggedInUser != null) {
              return ListTile(
                title: const Text(
                  "Log out",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.read<AuthCubit>().logout();
                },
              );
            }

            return Column(
              children: [
                ListTile(
                  title: Row(
                    children: [
                      const Text(
                        "Log in",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (serverUrl.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: TagBadge(message: '⚠️ Not logged in'),
                        ),
                    ],
                  ),
                  enabled: !isLoading && serverUrl.isNotEmpty,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/login'),
                ),
                ListTile(
                  title: const Text(
                    "Sign up",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  enabled: !isLoading && serverUrl.isNotEmpty,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/signup'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ServerSection extends StatelessWidget {
  const _ServerSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final serverUrl = settingsState.serverURL;
        return Column(
          children: [
            ListTile(
              title: Row(
                children: [
                  const Text(
                    'Home server URL',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (serverUrl.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: TagBadge(),
                    ),
                ],
              ),
              subtitle: Text(
                serverUrl.isNotEmpty ? serverUrl : "https://example.com",
                style: theme.textTheme.bodySmall,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showServerUrlDialog(context, serverUrl),
            ),
            BlocBuilder<ServerStatusCubit, ServerStatusState>(
              builder: (context, serverState) {
                final serverVersion = serverState.maybeWhen(
                  loaded: (info) => info.version,
                  orElse: () => 'Disconnected',
                );

                final isLoaded = serverState.maybeWhen(
                  loaded: (_) => true,
                  orElse: () => false,
                );

                return ListTile(
                  title: Row(
                    children: [
                      const Text(
                        'Server version:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      TagBadge(
                        message: serverVersion,
                        bgColor: isLoaded || serverUrl.isEmpty
                            ? theme.colorScheme.secondaryContainer
                            : theme.colorScheme.errorContainer,
                        color: isLoaded || serverUrl.isEmpty
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onErrorContainer,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showServerUrlDialog(
    BuildContext context,
    String currentUrl,
  ) async {
    final isLoggedIn = context.read<AuthCubit>().state.maybeWhen(
      authenticated: (_) => true,
      orElse: () => false,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _ServerUrlDialog(
        currentUrl: currentUrl,
        showLogoutWarning: isLoggedIn,
      ),
    );

    if (!context.mounted || result == null) return;

    if (isLoggedIn) {
      await context.read<AuthCubit>().logout();
    }

    if (!context.mounted) return;

    final trimmed = result.trim();
    final normalized = _normalizeUrl(trimmed);
    context.read<SettingsCubit>().setServerURL(normalized);
    context.read<ServerStatusCubit>().loadStatus();
  }

  String _normalizeUrl(String input) {
    if (input.isEmpty) return input;
    if (input.contains('://')) return input;

    // Default to HTTP for local addresses, HTTPS for everything else
    final uri = Uri.tryParse('http://$input');
    if (uri == null) return 'https://$input';

    final host = uri.host;

    // Check for localhost or .local (mDNS)
    if (host == 'localhost' || host.endsWith('.local')) {
      return 'http://$input';
    }

    // Check for private IPv4 ranges
    // 127.0.0.0/8
    // 10.0.0.0/8
    // 192.168.0.0/16
    // 172.16.0.0/12
    final parts = host.split('.');
    if (parts.length == 4) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);

      if (p0 != null) {
        if (p0 == 127) return 'http://$input';
        if (p0 == 10) return 'http://$input';
        if (p0 == 192 && p1 == 168) return 'http://$input';
        if (p0 == 172 && p1 != null && p1 >= 16 && p1 <= 31) {
          return 'http://$input';
        }
      }
    }

    return 'https://$input';
  }
}

class _DebugSection extends StatelessWidget {
  const _DebugSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Column(
          children: [
            if (state.debugMode) ...[
              ListTile(
                title: const Text(
                  'Enable Discord RPC',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Switch.adaptive(
                  value: state.discordRPCEnabled,
                  onChanged: (value) {
                    context.read<SettingsCubit>().setDiscordRPCEnabled(value);
                  },
                ),
                onTap: () {
                  context.read<SettingsCubit>().setDiscordRPCEnabled(
                    !state.discordRPCEnabled,
                  );
                },
              ),
              ListTile(
                title: const Text(
                  "Don't play sound",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Switch.adaptive(
                  value: state.dummySoundEnabled,
                  onChanged: (value) {
                    context.read<SettingsCubit>().setDummySoundEnabled(value);
                  },
                ),
                onTap: () {
                  context.read<SettingsCubit>().setDummySoundEnabled(
                    !state.dummySoundEnabled,
                  );
                },
              ),
              ListTile(
                title: const Text(
                  'Wipe local database',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showWipeDatabaseDialog(context),
              ),
            ],
            const Divider(),
            ListTile(
              title: const Text(
                'Debug mode',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: Switch.adaptive(
                value: state.debugMode,
                onChanged: (value) {
                  context.read<SettingsCubit>().setDebugMode(value);
                },
              ),
              onTap: () {
                context.read<SettingsCubit>().setDebugMode(!state.debugMode);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showWipeDatabaseDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Demolish all data'),
        content: const Text(
          'this will lowkey wipe your local database. i mean, why not?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('goodbye data'),
          ),
        ],
      ),
    );

    if (!context.mounted || result == null) return;

    if (result) {
      await sl<AppDatabase>().wipeDatabase();
      await sl<SyncManager>().reset();
    }
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text(
            'Show legal',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/eula'),
        ),
        ListTile(
          title: const Text(
            'About',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'Distribute',
              applicationVersion: "v$version",
              applicationLegalese:
                  '© 2026 sourcelocation. All rights reserved.',
            );
          },
        ),
        ListTile(
          title: Text(
            "Distribute (App)\nv$version",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ServerUrlDialog extends StatefulWidget {
  final String currentUrl;
  final bool showLogoutWarning;

  const _ServerUrlDialog({
    required this.currentUrl,
    required this.showLogoutWarning,
  });

  @override
  State<_ServerUrlDialog> createState() => _ServerUrlDialogState();
}

class _ServerUrlDialogState extends State<_ServerUrlDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit server'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'https://example.com',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          if (widget.showLogoutWarning)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'Changing the server URL will log you out.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
