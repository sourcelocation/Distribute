import 'package:distributeapp/blocs/requests_cubit.dart';
import 'package:distributeapp/blocs/server_status_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:distributeapp/components/blurry_app_bar.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => RequestsScreenState();
}

class RequestsScreenState extends State<RequestsScreen> {
  final _messageController = TextEditingController();
  String category = 'song_only';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: BlurryAppBar(
        center: Text("Request", style: theme.textTheme.titleMedium),
      ),
      body: BlocListener<RequestsCubit, RequestsState>(
        listener: (context, state) {
          state.maybeWhen(
            success: () {
              _messageController.clear();
              _showDialog(
                'Request Submitted',
                'Your request has been submitted successfully.',
              );
            },
            failure: (error) {
              _showDialog('Submission Failed', error);
            },
            orElse: () {},
          );
        },
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16.0,
                20.0 + kToolbarHeight + MediaQuery.of(context).padding.top,
                16.0,
                20.0 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Submit Music Requests",
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Depending on your server's configuration, you may be able to request new music to be added to its library. Requests will be reviewed by the server administrator.",
                    style: theme.textTheme.bodySmall,
                  ),

                  BlocBuilder<ServerStatusCubit, ServerStatusState>(
                    builder: (context, state) {
                      return state.maybeWhen(
                        loaded: (info, _) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              info.requestMailAnnouncement,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your request message here...',
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 20),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 4.0,
                    children: [
                      const Text("Request Category: "),
                      BlocBuilder<ServerStatusCubit, ServerStatusState>(
                        builder: (context, state) {
                          return state.maybeWhen(
                            loaded: (info, _) {
                              if (info.requestMailCategories.isNotEmpty) {
                                return SegmentedButton<String>(
                                  style: ElevatedButton.styleFrom(
                                    side: BorderSide(color: theme.dividerColor),
                                    surfaceTintColor:
                                        theme.colorScheme.secondaryContainer,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  segments: info.requestMailCategories
                                      .map(
                                        (cat) => ButtonSegment<String>(
                                          value: cat,
                                          label: Text(cat.replaceAll('_', ' ')),
                                        ),
                                      )
                                      .toList(),
                                  selected: {category},
                                  onSelectionChanged: (newSelection) {
                                    setState(() {
                                      category = newSelection.first;
                                    });
                                  },
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            orElse: () => const SizedBox.shrink(),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  BlocBuilder<RequestsCubit, RequestsState>(
                    builder: (context, state) {
                      final isSubmitting = state.maybeWhen(
                        submitting: () => true,
                        orElse: () => false,
                      );

                      return ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _messageController,
                        builder: (_, value, _) {
                          final isTextEmpty = value.text.trim().isEmpty;
                          final isDisabled = isSubmitting || isTextEmpty;

                          return ElevatedButton(
                            onPressed: isDisabled
                                ? null
                                : () {
                                    context.read<RequestsCubit>().submitRequest(
                                      _messageController.text,
                                      category,
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  theme.colorScheme.secondaryContainer,
                              foregroundColor: Colors.white,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Submit a Request'),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
