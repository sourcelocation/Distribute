import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:distributeapp/core/preferences/settings_cubit.dart';
import 'package:flutter/material.dart';

class AppLinksHandler {
  final AppLinks _appLinks = AppLinks();
  final GlobalKey<NavigatorState> navigatorKey;
  final SettingsCubit settingsCubit;

  StreamSubscription<Uri>? _linkSubscription;

  AppLinksHandler({required this.navigatorKey, required this.settingsCubit});

  Future<void> init() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (err) {
        debugPrint('AppLinksHandler error: $err');
      },
    );
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  void _handleUri(Uri uri) {
    debugPrint('AppLinksHandler received URI: $uri');

    if (uri.scheme != 'distribute') {
      debugPrint('AppLinksHandler: Unknown scheme ${uri.scheme}');
      return;
    }

    switch (uri.host) {
      case 'add-server':
        _handleAddServer(uri);
        break;
      default:
        debugPrint('AppLinksHandler: Unknown host ${uri.host}');
    }
  }

  void _handleAddServer(Uri uri) {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) {
      debugPrint('AppLinksHandler: No server URL provided in add-server link');
      return;
    }

    String serverUrl = pathSegments.join('/');

    serverUrl = Uri.decodeComponent(serverUrl);

    debugPrint('AppLinksHandler: Extracted server URL: $serverUrl');

    _showAddServerConfirmation(serverUrl);
  }

  void _showAddServerConfirmation(String serverUrl) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('AppLinksHandler: No context available for dialog');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Server'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to set your home server to:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    dialogContext,
                  ).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  serverUrl,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Theme.of(dialogContext).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This will change your server connection. '
                'Only proceed if you trust this server.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _setServerUrl(serverUrl);
              },
              child: const Text('Add Server'),
            ),
          ],
        );
      },
    );
  }

  void _setServerUrl(String serverUrl) {
    settingsCubit.setServerURL(serverUrl);

    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server URL set to: $serverUrl'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
