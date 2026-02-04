import 'package:distributeapp/blocs/download_cubit.dart';
import 'package:distributeapp/components/blurry_app_bar.dart';
import 'package:distributeapp/blocs/playlist_bloc.dart';
import 'package:distributeapp/model/playlist.dart';
import 'package:distributeapp/model/song.dart';
import 'package:distributeapp/screens/error_message.dart';
import 'package:distributeapp/screens/library/album_image.dart';
import 'package:distributeapp/repositories/audio/music_player_controller.dart';
import 'package:distributeapp/repositories/playlist_repository.dart';
import 'package:distributeapp/model/available_file.dart';
import 'package:distributeapp/blocs/music/music_player_bloc.dart';
import 'package:distributeapp/screens/playlist/playlist_options.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:distributeapp/core/service_locator.dart';
import 'package:distributeapp/components/hoverable_icon_button.dart';
import 'package:distributeapp/components/hoverable_area.dart';
import 'package:distributeapp/components/hoverable_list_tile.dart';
import 'package:distributeapp/core/sync_manager.dart';
import 'package:distributeapp/components/custom_refresh_indicator.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistId;

  const PlaylistScreen({super.key, required this.playlistId});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: BlurryAppBar(
        actions: [
          HoverableIconButton(
            icon: Icon(
              AppIcons.edit,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              final playlistBloc = context.read<PlaylistBloc>();
              playlistBloc.state.maybeWhen(
                loaded: (playlist, songs) =>
                    _showPlaylistOptions(context, playlist),
                orElse: () {},
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocConsumer<PlaylistBloc, PlaylistState>(
            listener: (context, state) {
              state.maybeWhen(
                deleted: () {
                  Navigator.pop(context);
                },
                orElse: () {},
              );
            },
            builder: (context, state) {
              return state.maybeWhen(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (message) => ErrorMessage(message: message),
                loaded: (playlist, songs) =>
                    _buildList(context, playlist, songs),
                orElse: () => const Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Playlist playlist,
    List<Song> songs,
  ) {
    final icon = null;
    const iconSize = 230.0;

    final isAllDownloaded =
        songs.isNotEmpty &&
        songs.isNotEmpty &&
        songs.every((s) => s.isDownloaded);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(icon != null ? 8.0 : 0.0),
          child: icon != null
              ? Image(
                  image: icon!,
                  key: ValueKey(icon),
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  'assets/default-playlist-hq.png',
                  key: ValueKey('default-playlist'),
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.cover,
                ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                playlist.name,
                style: Theme.of(context).textTheme.headlineLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 4,
          children: [
            Icon(
              AppIcons.account,
              size: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
            Text('You', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            FilledButton.tonal(
              style: FilledButton.styleFrom(minimumSize: const Size(100, 36)),
              onPressed: () {
                setState(() {
                  _isEditMode = !_isEditMode;
                });
              },
              child: Row(
                spacing: 6,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isEditMode ? AppIcons.check : AppIcons.menu),
                  Text(_isEditMode ? 'Done' : 'Edit'),
                ],
              ),
            ),
            if (isAllDownloaded)
              FilledButton.tonal(
                style: FilledButton.styleFrom(minimumSize: const Size(100, 36)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Remove Downloads"),
                        content: const Text(
                          "Are you sure you want to remove all downloads for this playlist? This action cannot be undone.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context
                                  .read<DownloadCubit>()
                                  .removeDownloadsFromPlaylist(songs);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Removing downloads from playlist",
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              overlayColor: Colors.red,
                              foregroundColor: Colors.red,
                            ),
                            child: const Text("Remove"),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Row(
                  spacing: 6,
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(AppIcons.delete), Text('Remove Downloads')],
                ),
              )
            else
              FilledButton.tonal(
                style: FilledButton.styleFrom(minimumSize: const Size(100, 36)),
                onPressed: () {
                  final playlistBloc = context.read<PlaylistBloc>();
                  playlistBloc.state.maybeWhen(
                    loaded: (playlist, songs) {
                      context.read<DownloadCubit>().downloadPlaylist(songs);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Started downloading playlist"),
                        ),
                      );
                    },
                    orElse: () {},
                  );
                },
                child: Row(
                  spacing: 6,
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(AppIcons.download), Text('Download')],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, Playlist playlist, List<Song> songs) {
    return Expanded(
      child: CustomRefreshIndicator(
        onRefresh: () async {
          await sl<SyncManager>().triggerSync();
        },
        child: ReorderableListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          header: Padding(
            key: const ValueKey('header'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: _buildHeader(context, playlist, songs),
          ),
          itemCount: songs.length,
          padding: EdgeInsets.fromLTRB(
            8,
            MediaQuery.of(context).padding.top + 8,
            8,
            8 + MediaQuery.of(context).padding.bottom,
          ),
          onReorder: (int oldIndex, int newIndex) {
            final song = songs[oldIndex];
            context.read<PlaylistBloc>().add(
              PlaylistEvent.moveSong(
                playlistId: playlist.id,
                songId: song.id,
                oldIndex: oldIndex,
                newIndex: newIndex,
              ),
            );
          },
          itemBuilder: (context, index) {
            final song = songs[index];

            return _SongTile(
              key: ValueKey(song.id),
              song: song,
              index: index,
              isEditMode: _isEditMode,
              onPlay: () {
                context.read<MusicPlayerBloc>().add(
                  MusicPlayerEvent.playPlaylist(songs, index),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showPlaylistOptions(BuildContext context, Playlist playlist) {
    final playlistBloc = context.read<PlaylistBloc>();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return BlocProvider.value(
          value: playlistBloc,
          child: PlaylistOptionsScreen(
            playlistId: playlist.id,
            fromPlaylistScreen: true,
          ),
        );
      },
    );
  }
}

class _SongTile extends StatefulWidget {
  final Song song;
  final VoidCallback onPlay;
  final int index;
  final bool isEditMode;

  const _SongTile({
    super.key,
    required this.song,
    required this.onPlay,
    required this.index,
    required this.isEditMode,
  });

  @override
  State<_SongTile> createState() => _SongTileState();
}

class _SongTileState extends State<_SongTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HoverableArea(
      onTap: _onTap,
      onLongPress: () => _showOptions(context),
      borderRadius: BorderRadius.circular(8.0),
      child: ListTile(
        leading: LibraryLeadingIcon(
          albumId: widget.song.albumId,
          isFolder: false,
        ),
        title: Text(
          widget.song.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          widget.song.artist,
          style: theme.textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocBuilder<DownloadCubit, DownloadState>(
              buildWhen: (previous, current) {
                final prevStatus = previous.queue[widget.song.id];
                final currStatus = current.queue[widget.song.id];
                return prevStatus != currStatus;
              },
              builder: (context, state) {
                final downloadStatus =
                    state.queue[widget.song.id] ??
                    const DownloadStatus.initial();

                return downloadStatus.when(
                  initial: () => widget.song.isDownloaded
                      ? Icon(AppIcons.check, color: theme.colorScheme.secondary)
                      : Icon(
                          AppIcons.cloud,
                          color: theme.colorScheme.secondary,
                        ),
                  pending: () => Icon(
                    AppIcons.downloading,
                    color: theme.colorScheme.secondary,
                  ),
                  loading: (progress) => SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: progress,
                    ),
                  ),
                  success: () =>
                      Icon(AppIcons.check, color: theme.colorScheme.secondary),
                  error: (message) =>
                      Icon(AppIcons.error, color: theme.colorScheme.error),
                );
              },
            ),
            if (widget.isEditMode) ...[
              const SizedBox(width: 12),
              ReorderableDragStartListener(
                index: widget.index,
                child: Icon(
                  Icons.drag_handle,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        dense: true,
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final playlistBloc = context.read<PlaylistBloc>();
    final pId = playlistBloc.playlistId;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final isDownloaded = widget.song.isDownloaded;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            8.0,
            8.0,
            8.0,
            8.0 + MediaQuery.of(sheetContext).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HoverableListTile(
                leading: Icon(AppIcons.removeCircle),
                title: const Text('Remove from Playlist'),
                onTap: () async {
                  context.read<PlaylistBloc>().add(
                    PlaylistEvent.removeSong(
                      playlistId: pId,
                      songId: widget.song.id,
                    ),
                  );

                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
              if (isDownloaded)
                HoverableListTile(
                  leading: Icon(AppIcons.delete),
                  title: const Text('Remove from Downloads'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await context.read<DownloadCubit>().deleteFile(widget.song);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Removed from downloads")),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _onTap() async {
    final controller = sl<MusicPlayerController>();
    final fileExists = await controller.isSongAvailable(widget.song);

    if (fileExists && mounted) {
      widget.onPlay();
      return;
    }

    if (!mounted) return;

    try {
      final repo = sl<PlaylistRepository>();
      final files = await repo.fetchSongFiles(widget.song.id);

      if (!mounted) return;

      if (files.isEmpty) {
        repo.updateSongDownloaded(widget.song.id, false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No files available for download.")),
        );
        return;
      }

      if (files.length == 1) {
        _startDownload(files.first);
      } else {
        _showFileSelection(context, widget.song, files);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error fetching files: $e")));
      }
    }
  }

  void _startDownload(AvailableFile file) async {
    try {
      await sl<PlaylistRepository>().updateSongFile(
        widget.song.id,
        file.id,
        file.format,
      );

      if (!mounted) return;

      final updatedSong = widget.song.copyWith(
        fileId: file.id,
        format: file.format,
      );

      context.read<DownloadCubit>().downloadSong(updatedSong);

      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(const SnackBar(content: Text("Download started")));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error starting download: $e")));
      }
    }
  }

  void _showFileSelection(
    BuildContext context,
    Song song,
    List<AvailableFile> files,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16.0,
            16.0,
            16.0,
            16.0 + MediaQuery.of(ctx).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select File Quality",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...files.map((file) {
                return HoverableListTile(
                  title: Text(file.format.toUpperCase()),
                  subtitle: Text(
                    "Size: ${(file.size / 1024 / 1024).toStringAsFixed(2)} MB",
                  ),
                  trailing: Icon(AppIcons.download),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _startDownload(file);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
