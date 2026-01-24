import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:distributeapp/core/preferences/settings_cubit.dart';
import 'package:distributeapp/core/services/navigation_service.dart';
import 'package:flutter/material.dart';

/// Service that handles deep links for the Distribute app.
///
/// Supports the following URL schemes:
/// - `distribute://add-server/<server_url>` - Sets the home server URL after user confirmation
class AppLinksService {
  final AppLinks _appLinks = AppLinks();
  final NavigationService _navigationService;
  final SettingsCubit _settingsCubit;

  StreamSubscription<Uri>? _linkSubscription;

  AppLinksService({
    required NavigationService navigationService,
    required SettingsCubit settingsCubit,
  }) : _navigationService = navigationService,
       _settingsCubit = settingsCubit;

  /// Initialize the app links service.
  /// This should be called once when the app starts.
  Future<void> init() async {
    // Handle the initial link if the app was launched via a deep link
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri);
    }

    // Listen for incoming links while the app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (err) {
        debugPrint('AppLinks error: $err');
      },
    );
  }

  /// Dispose of the service and cancel subscriptions.
  void dispose() {
    _linkSubscription?.cancel();
  }

  /// Handle an incoming URI.
  void _handleUri(Uri uri) {
    debugPrint('AppLinks received URI: $uri');

    // Check if this is a distribute:// scheme
    if (uri.scheme != 'distribute') {
      debugPrint('AppLinks: Unknown scheme ${uri.scheme}');
      return;
    }

    // Handle different paths
    switch (uri.host) {
      case 'add-server':
        _handleAddServer(uri);
        break;
      default:
        debugPrint('AppLinks: Unknown host ${uri.host}');
    }
  }

  /// Handle the add-server deep link.
  /// URL format: `distribute://add-server/encoded_server_url`
  void _handleAddServer(Uri uri) {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) {
      debugPrint('AppLinks: No server URL provided in add-server link');
      return;
    }

    // Reconstruct the server URL from path segments
    String serverUrl = pathSegments.join('/');

    // URL decode the server URL
    serverUrl = Uri.decodeComponent(serverUrl);

    debugPrint('AppLinks: Extracted server URL: $serverUrl');

    // Show confirmation dialog after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAddServerConfirmation(serverUrl);
    });
  }

  /// Show a confirmation dialog before setting the server URL.
  void _showAddServerConfirmation(String serverUrl) {
    final context = _navigationService.currentContext;
    if (context == null) {
      debugPrint('AppLinks: No context available for dialog');
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

  /// Set the server URL in preferences.
  void _setServerUrl(String serverUrl) {
    _settingsCubit.setServerURL(serverUrl);

    final context = _navigationService.currentContext;
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
