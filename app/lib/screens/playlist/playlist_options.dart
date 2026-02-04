import 'package:distributeapp/blocs/download_cubit.dart';
import 'package:distributeapp/blocs/file_system_bloc.dart';
import 'package:distributeapp/blocs/playlist_bloc.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:distributeapp/components/hoverable_list_tile.dart';

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
      padding: EdgeInsets.fromLTRB(
        8.0,
        8.0,
        8.0,
        8.0 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          HoverableListTile(
            leading: Icon(AppIcons.edit),
            title: const Text('Rename Playlist'),
            onTap: _showRenameDialog,
          ),
          HoverableListTile(
            leading: Icon(AppIcons.deleteSimple),
            title: const Text('Delete Playlist'),
            onTap: _showDeleteDialog,
          ),
          HoverableListTile(
            leading: Icon(AppIcons.share),
            title: const Text('Share Playlist'),
            onTap: null,
          ),
          HoverableListTile(
            leading: Icon(AppIcons.move),
            title: const Text('Move Playlist'),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/folder-picker?itemId=${widget.playlistId}');
            },
          ),
          BlocBuilder<DownloadCubit, DownloadState>(
            builder: (context, downloadState) {
              // Try to get songs from PlaylistBloc if available (when fromPlaylistScreen is true)
              List<dynamic> songs = [];
              try {
                final playlistState = context.read<PlaylistBloc>().state;
                songs = playlistState.maybeWhen(
                  loaded: (playlist, songs) => songs,
                  orElse: () => <dynamic>[],
                );
              } catch (_) {
                // PlaylistBloc not available (from library screen)
              }
              
              // Check if any songs in the playlist are being downloaded
              final isDownloading = songs.isNotEmpty && songs.any((song) {
                final status = downloadState.queue[song.id];
                return status is DownloadStatusPending || 
                       status is DownloadStatusLoading;
              });
              
              return HoverableListTile(
                leading: isDownloading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(AppIcons.download),
                title: const Text('Download All'),
                onTap: isDownloading || songs.isEmpty
                  ? null
                  : () {
                      context.read<DownloadCubit>().downloadPlaylist(songs.cast());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Started downloading playlist"),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
              );
            },
          ),
        ],
      ),
    );
  }
}
