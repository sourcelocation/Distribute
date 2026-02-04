import 'dart:ui';

import 'package:distributeapp/blocs/music/music_player_bloc.dart';
import 'package:distributeapp/repositories/audio/music_player_controller.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:distributeapp/components/hoverable_area.dart';

class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withAlpha(170),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withAlpha(30),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Queue',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<MusicPlayerBloc, ControllerState>(
                      builder: (context, state) {
                        final queue = state.queue;
                        if (queue.isEmpty) {
                          return const Center(child: Text("Queue is empty"));
                        }

                        return ListView.builder(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).padding.bottom + 16,
                          ),
                          controller: scrollController,
                          itemCount: queue.length,
                          itemBuilder: (context, index) {
                            final item = queue[index];
                            final isCurrent = index == state.queueIndex;

                            return HoverableArea(
                              onTap: () {
                                context.read<MusicPlayerBloc>().add(
                                  MusicPlayerEvent.skipToQueueItem(index),
                                );
                              },
                              borderRadius: BorderRadius.circular(8.0),
                              child: ListTile(
                                leading: isCurrent
                                    ? Icon(
                                        AppIcons.equalizer,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                title: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isCurrent
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                                subtitle: Text(
                                  item.artist ?? 'Unknown Artist',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: isCurrent
                                    ? Icon(
                                        AppIcons.equalizer,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                // onTap: handled by HoverableArea
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
