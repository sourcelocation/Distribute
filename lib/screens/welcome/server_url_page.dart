import 'package:distributeapp/blocs/server_status_cubit.dart';
import 'package:distributeapp/core/preferences/settings_cubit.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class ServerUrlPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ServerUrlPage({super.key, required this.onNext, required this.onBack});

  @override
  State<ServerUrlPage> createState() => _ServerUrlPageState();
}

class _ServerUrlPageState extends State<ServerUrlPage> {
  late final TextEditingController _controller;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    final currentUrl = context.read<SettingsCubit>().state.serverURL;
    _controller = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validateAndSave() async {
    final rawUrl = _controller.text.trim();
    if (rawUrl.isEmpty) return;

    setState(() {
      _isValidating = true;
    });

    // Determine the first URL to try.
    final firstUrl = _normalizeUrl(rawUrl);

    // Save and try first URL
    await context.read<SettingsCubit>().setServerURL(firstUrl);
    if (!mounted) return;
    await context.read<ServerStatusCubit>().loadStatus();

    // Check if successful
    if (!mounted) return;
    final firstState = context.read<ServerStatusCubit>().state;
    final firstSuccess = firstState.maybeWhen(
      loaded: (_) => true,
      orElse: () => false,
    );

    if (firstSuccess) {
      if (!mounted) return;
      setState(() => _isValidating = false);
      widget.onNext();
      return;
    }

    // If failed and we tried HTTPS, try HTTP fallback
    if (firstUrl.startsWith('https://')) {
      final httpUrl = firstUrl.replaceFirst('https://', 'http://');

      // Save and try HTTP URL
      await context.read<SettingsCubit>().setServerURL(httpUrl);
      if (!mounted) return;
      await context.read<ServerStatusCubit>().loadStatus();

      if (!mounted) return;
      final secondState = context.read<ServerStatusCubit>().state;
      final secondSuccess = secondState.maybeWhen(
        loaded: (_) => true,
        orElse: () => false,
      );

      if (secondSuccess) {
        final useHttp =
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Insecure Connection"),
                content: const Text(
                  "Secure connection (HTTPS) failed. connecting via HTTP worked, but it is not secure. Do you want to proceed?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("No"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Yes"),
                  ),
                ],
              ),
            ) ??
            false;

        if (useHttp) {
          if (!mounted) return;
          setState(() => _isValidating = false);
          widget.onNext();
          return;
        }
      }
    }

    // Revert to original URL if we are here (either HTTP failed, or user refused HTTP)
    if (!mounted) return;
    await context.read<SettingsCubit>().setServerURL(firstUrl);
    if (!mounted) return;
    await context.read<ServerStatusCubit>().loadStatus();

    if (!mounted) return;
    setState(() {
      _isValidating = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(
              Icons.dns_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Connect to Server",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Enter the URL of your Distribute server.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 32),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Server URL',
              hintText: 'https://example.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withAlpha(50),
              prefixIcon: const Icon(Icons.dns),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _validateAndSave(),
          ),
          TextButton(
            onPressed: () {
              launchUrl(
                Uri.parse(
                  'https://distribute-docs.sourceloc.net/docs#step-3-installing-distributor',
                ),
              );
            },
            child: Text(
              "Don't have one? Set it up here.",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary.withAlpha(200),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          BlocBuilder<ServerStatusCubit, ServerStatusState>(
            builder: (context, state) {
              return state.maybeWhen(
                loading: () => const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text("Checking connection..."),
                  ],
                ),
                error: (msg) => Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Could not connect: $msg",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
                loaded: (info) => Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                orElse: () => const SizedBox.shrink(),
              );
            },
          ),
          const Spacer(),
          Row(
            children: [
              TextButton(onPressed: widget.onBack, child: const Text("Back")),
              const Spacer(),
              FilledButton(
                onPressed: _isValidating ? null : _validateAndSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text("Next"),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
