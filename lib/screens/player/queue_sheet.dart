import 'package:distributeapp/blocs/music/music_player_bloc.dart';
import 'package:distributeapp/repositories/audio/music_player_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Queue',
                style: Theme.of(context).textTheme.headlineSmall,
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
                    controller: scrollController,
                    itemCount: queue.length,
                    itemBuilder: (context, index) {
                      final item = queue[index];
                      final isCurrent = index == state.queueIndex;

                      return ListTile(
                        leading: isCurrent
                            ? Icon(
                                Icons.equalizer,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.grey),
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
                        onTap: () {
                          context.read<MusicPlayerBloc>().add(
                            MusicPlayerEvent.skipToQueueItem(index),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
