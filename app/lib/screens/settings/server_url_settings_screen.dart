import 'package:distributeapp/blocs/server_status_cubit.dart';
import 'package:distributeapp/components/blurry_app_bar.dart';
import 'package:distributeapp/core/utils/server_url_utils.dart';
import 'package:distributeapp/core/preferences/settings_cubit.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ServerUrlSettingsScreen extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const ServerUrlSettingsScreen({super.key, this.onNext, this.onBack});

  @override
  State<ServerUrlSettingsScreen> createState() =>
      _ServerUrlSettingsScreenState();
}

class _ServerUrlSettingsScreenState extends State<ServerUrlSettingsScreen> {
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

    final cubit = context.read<ServerStatusCubit>();
    final connectionResult = await cubit.discoverConnection(rawUrl);

    if (!mounted) return;

    connectionResult.when(
      success: (url) => _finalizeConnection(url),
      httpFallback: (url) async {
        final useHttp = await _showInsecureDialog();
        if (useHttp && mounted) {
          _finalizeConnection(url);
        } else if (mounted) {
          // If rejected, try original normalized URL to let it fail/show error
          _finalizeConnection(ServerUrlUtils.normalizeUrl(rawUrl));
        }
      },
      failure: () {
        // If discovery failed, fall back to normalized URL to show error state
        _finalizeConnection(ServerUrlUtils.normalizeUrl(rawUrl));
      },
    );
  }

  Future<void> _finalizeConnection(String url) async {
    await context.read<SettingsCubit>().setServerURL(url);
    if (!mounted) return;
    await context.read<ServerStatusCubit>().loadStatus();

    if (!mounted) return;
    final state = context.read<ServerStatusCubit>().state;
    final isSuccess = state.maybeWhen(
      loaded: (_, msg) => true,
      orElse: () => false,
    );

    if (isSuccess && mounted) {
      if (widget.onNext != null) {
        widget.onNext!();
      } else {
        context.pop();
      }
    } else if (mounted) {
      setState(() => _isValidating = false);
    }
  }

  Future<bool> _showInsecureDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Insecure Connection"),
            content: const Text(
              "Secure connection (HTTPS) failed. Connecting via HTTP worked, but it is not secure. Do you want to proceed?",
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: BlurryAppBar(
        center: Text(
          "Server Connection",
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          24,
          kToolbarHeight + MediaQuery.of(context).padding.top + 24,
          24,
          24,
        ),
        children: [
          Center(
            child: Icon(
              AppIcons.dns,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Connect to Server",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
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
              ),
              prefixIcon: Icon(AppIcons.dns),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _validateAndSave(),
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.url],
          ),
          const SizedBox(height: 16),
          // Validation/Status Display
          BlocBuilder<ServerStatusCubit, ServerStatusState>(
            builder: (context, state) {
              return Column(
                children: [
                  state.maybeWhen(
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
                        Icon(
                          AppIcons.errorOutline,
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
                    loaded: (info, warning) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Connected to ${info.version}",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (warning != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    warning,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              if (widget.onBack != null) ...[
                TextButton(onPressed: widget.onBack, child: const Text("Back")),
                const Spacer(),
              ],
              if (widget.onNext != null)
                FilledButton(
                  onPressed: _isValidating ? null : _validateAndSave,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text("Next"),
                )
              else
                Expanded(
                  child: FilledButton(
                    onPressed: _isValidating ? null : _validateAndSave,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text("Save"),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                launchUrl(
                  Uri.parse(
                    'https://distribute-docs.sourceloc.net/docs#step-2-installing-distributor',
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
          ),
        ],
      ),
    );
  }
}
