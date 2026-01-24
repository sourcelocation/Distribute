import 'package:distributeapp/blocs/file_system_bloc.dart';
import 'package:distributeapp/blocs/playlist_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PlaylistOptionsScreen extends StatefulWidget {
  final String playlistId;
  final bool fromPlaylistScreen;

  const PlaylistOptionsScreen({
    super.key,
    required this.playlistId,
    required this.fromPlaylistScreen,
  });

  @override
  State<PlaylistOptionsScreen> createState() => _PlaylistOptionsScreenState();
}

class _PlaylistOptionsScreenState extends State<PlaylistOptionsScreen> {
  void _showRenameDialog() {
    final nameController = TextEditingController();
    final widgetContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename Playlist'),
          content: TextField(
            controller: nameController,
            maxLength: 50,
            decoration: const InputDecoration(
              hintText: 'Playlist name',
              border: OutlineInputBorder(),
            ),

            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  if (widget.fromPlaylistScreen) {
                    final playlistBloc = context.read<PlaylistBloc>();
                    playlistBloc.add(
                      PlaylistEvent.rename(
                        playlistId: widget.playlistId,
                        name: name,
                      ),
                    );
                  } else {
                    final playlistBloc = widgetContext.read<FileSystemBloc>();
                    playlistBloc.add(
                      FileSystemEvent.renamePlaylist(widget.playlistId, name),
                    );
                  }

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Playlist'),
          content: const Text(
            'Are you sure you want to delete this playlist? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (widget.fromPlaylistScreen) {
                  final playlistBloc = context.read<PlaylistBloc>();
                  playlistBloc.add(
                    PlaylistEvent.delete(playlistId: widget.playlistId),
                  );
                } else {
                  final playlistBloc = context.read<FileSystemBloc>();
                  playlistBloc.add(
                    FileSystemEvent.deletePlaylist(widget.playlistId),
                  );
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename Playlist'),
            onTap: _showRenameDialog,
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Playlist'),
            onTap: _showDeleteDialog,
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Playlist'),
            onTap: null,
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_move_outline),
            title: const Text('Move Playlist'),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/folder-picker?itemId=${widget.playlistId}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Download All'),
            onTap: null,
          ),
        ],
      ),
    );
  }
}
