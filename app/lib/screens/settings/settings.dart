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
import 'package:distributeapp/components/settings_icon.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:distributeapp/components/hoverable_list_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: BlurryAppBar(
        center: Text("Settings", style: theme.textTheme.titleMedium),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          kToolbarHeight + MediaQuery.of(context).padding.top + 12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        children: const [
          SettingsProfileHeader(),
          Card(child: _UserSection()),
          Card(child: _DataSection()),
          Card(child: _ServerSection()),
          Card(child: _DebugSection()),
          Card(child: _AboutSection()),
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
              return HoverableListTile(
                leading: SettingsIcon(AppIcons.logout),
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
                HoverableListTile(
                  leading: SettingsIcon(AppIcons.login),
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
                HoverableListTile(
                  leading: SettingsIcon(AppIcons.personAdd),
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

class _DataSection extends StatelessWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HoverableListTile(
          title: const Text(
            'Storage',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          leading: SettingsIcon(AppIcons.folder),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/storage'),
        ),
        HoverableListTile(
          title: const Text(
            'Customization',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          leading: SettingsIcon(
            AppIcons.brush,
          ), // Assuming brush icon exists or use another one
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/customization'),
        ),
      ],
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
            BlocBuilder<ServerStatusCubit, ServerStatusState>(
              builder: (context, serverState) {
                final validationMessage = serverState.maybeWhen(
                  loaded: (_, msg) => msg,
                  orElse: () => null,
                );

                return HoverableListTile(
                  leading: SettingsIcon(AppIcons.dns),
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
                      if (validationMessage != null)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: TagBadge(
                            message: '!',
                            bgColor: Colors.amber,
                            color: Colors.black,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    serverUrl.isNotEmpty ? serverUrl : "https://example.com",
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/server'),
                );
              },
            ),
            BlocBuilder<ServerStatusCubit, ServerStatusState>(
              builder: (context, serverState) {
                final serverVersion = serverState.maybeWhen(
                  loaded: (info, _) => info.version,
                  orElse: () => 'Disconnected',
                );

                final isLoaded = serverState.maybeWhen(
                  loaded: (_, msg) => true,
                  orElse: () => false,
                );

                return HoverableListTile(
                  leading: SettingsIcon(AppIcons.info),
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
            HoverableListTile(
              title: const Text(
                'Requests',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              leading: SettingsIcon(AppIcons.requests),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/requests'),
            ),
          ],
        );
      },
    );
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
            HoverableListTile(
              leading: SettingsIcon(AppIcons.bugReport),
              title: const Text('Debug mode'),
              trailing: Switch.adaptive(
                value: state.debugMode,
                onChanged: (value) {
                  context.read<SettingsCubit>().setDebugMode(value);
                },
              ),
            ),
            if (state.debugMode) ...[
              const Divider(),
              HoverableListTile(
                leading: SettingsIcon(AppIcons.webhook),
                title: const Text('Enable Discord RPC'),
                trailing: Switch.adaptive(
                  value: state.discordRPCEnabled,
                  onChanged: (value) {
                    context.read<SettingsCubit>().setDiscordRPCEnabled(value);
                  },
                ),
              ),
              HoverableListTile(
                leading: SettingsIcon(AppIcons.volumeOff),
                title: const Text("Don't play sound"),
                trailing: Switch.adaptive(
                  value: state.dummySoundEnabled,
                  onChanged: (value) {
                    context.read<SettingsCubit>().setDummySoundEnabled(value);
                  },
                ),
              ),
              HoverableListTile(
                leading: SettingsIcon(AppIcons.fastForward),
                title: const Text('Preload next song'),
                trailing: Switch.adaptive(
                  value: state.preloadNextSongEnabled,
                  onChanged: (value) {
                    context.read<SettingsCubit>().setPreloadNextSongEnabled(
                      value,
                    );
                  },
                ),
              ),
              HoverableListTile(
                leading: SettingsIcon(
                  AppIcons.deleteForever,
                  color: Colors.red,
                ),
                title: const Text(
                  'Wipe local database',
                  style: TextStyle(color: Colors.red),
                ),
                trailing: Icon(AppIcons.chevronRight, color: Colors.red),
                onTap: () => _showWipeDatabaseDialog(context),
              ),
            ],
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
        HoverableListTile(
          leading: SettingsIcon(AppIcons.legal),
          title: const Text(
            'Show legal',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/eula'),
        ),
        HoverableListTile(
          leading: SettingsIcon(AppIcons.about),
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
        HoverableListTile(
          title: Text(
            "Distribute (App)\nv$version",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
