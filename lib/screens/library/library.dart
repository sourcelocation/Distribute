import 'package:distributeapp/blocs/file_system_bloc.dart';
import 'package:distributeapp/components/blurry_app_bar.dart';
import 'package:distributeapp/model/playlist.dart';
import 'package:distributeapp/model/playlist_folder.dart';
import 'package:distributeapp/screens/library/library_row.dart';
import 'package:distributeapp/screens/playlist/playlist_options.dart';
import 'package:distributeapp/screens/folder/folder_options.dart';
import 'package:distributeapp/core/service_locator.dart';
import 'package:distributeapp/core/sync_manager.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:distributeapp/components/hoverable_icon_button.dart';
import 'package:distributeapp/components/hoverable_list_tile.dart';

class LibraryScreen extends StatelessWidget {
  final String? folderId;
  final Function(BuildContext context, String playlistId)? onPlaylistSelected;
  final Function(BuildContext context, String? folderId)? onFolderSelected;

  const LibraryScreen({
    super.key,
    this.folderId,
    this.onPlaylistSelected,
    this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaylistPicker = onPlaylistSelected != null;
    final isFolderPicker = onFolderSelected != null;
    final isPickerMode = isPlaylistPicker || isFolderPicker;

    return _buildScaffold(context, isPickerMode, isFolderPicker);
  }

  Widget _buildScaffold(
    BuildContext context,
    bool isPickerMode,
    bool isFolderPicker,
  ) {
    return BlocBuilder<FileSystemBloc, FileSystemState>(
      builder: (context, state) {
        final currentTitle = state.maybeMap(
          loaded: (s) => s.currentFolderName,
          orElse: () => "",
        );
        final isRoot = state.maybeMap(
          loaded: (s) => s.isRoot,
          orElse: () => false,
        );
        final showBackButton = !isRoot && folderId != null || isPickerMode;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: BlurryAppBar(
            center: _buildAppBarTitle(
              context,
              isPickerMode,
              isFolderPicker,
              currentTitle,
              isRoot,
            ),
            actions: [
              HoverableIconButton(
                icon: Icon(AppIcons.add),
                onPressed: () => _showCreateOptions(context),
              ),
            ],
            automaticallyImplyLeading: showBackButton,
          ),
          body: state.maybeWhen(
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded:
                (
                  subFolders,
                  playlists,
                  currentFolderId,
                  currentFolderName,
                  isRoot,
                ) => _buildFolderView(
                  context,
                  currentFolderId,
                  subFolders,
                  playlists,
                ),
            orElse: () => const Center(child: CircularProgressIndicator()),
          ),
          floatingActionButton: isFolderPicker
              ? FloatingActionButton.extended(
                  onPressed: () {
                    onFolderSelected!(context, folderId);
                  },
                  label: const Text("Move Here"),
                  icon: Icon(AppIcons.check),
                )
              : null,
        );
      },
    );
  }

  Widget _buildAppBarTitle(
    BuildContext context,
    bool isPickerMode,
    bool isFolderPicker,
    String title,
    bool isRoot,
  ) {
    if (isPickerMode) {
      title = isFolderPicker ? "Select Folder" : "Select Playlist";
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        if (!isPickerMode && !isFolderPicker && isRoot)
          Image.asset('assets/logo-mono.png', height: 32),
        Text(
          isRoot ? "Distribute" : title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildFolderView(
    BuildContext context,
    String? targetId,
    List<PlaylistFolder> folders,
    List<Playlist> playlists,
  ) {
    final scheme = Theme.of(context).colorScheme;

    Widget content;
    if (folders.isEmpty && playlists.isEmpty) {
      content = CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  AppIcons.folderOpen,
                  size: 48,
                  color: scheme.secondary.withAlpha(100),
                ),
                const SizedBox(height: 16),
                Text(
                  "Woah, such empty!",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.secondary.withAlpha(150),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      content = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: folders.length + playlists.length,
        padding: EdgeInsets.fromLTRB(
          8,
          kToolbarHeight + MediaQuery.of(context).padding.top + 8,
          8,
          80 + MediaQuery.of(context).padding.bottom,
        ),
        itemBuilder: (context, index) {
          if (index < folders.length) {
            // --- FOLDER ROW ---
            final folder = folders[index];
            final bloc = context.read<FileSystemBloc>();
            return LibraryRowWidget(
              title: folder.name,
              albumId: null,
              isFolder: true,
              onLongPress: () async {
                await HapticFeedback.mediumImpact();
                if (context.mounted) {
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) {
                      return BlocProvider.value(
                        value: bloc,
                        child: FolderOptionsScreen(folder: folder),
                      );
                    },
                  );
                }
              },
              onTap: () {
                if (onPlaylistSelected != null) {
                  final songId = GoRouterState.of(
                    context,
                  ).uri.queryParameters['songId'];
                  final q = songId != null ? "?songId=$songId" : "";
                  context.push(
                    '/picker/${folder.id}$q',
                    extra: GoRouterState.of(context).extra,
                  );
                } else if (onFolderSelected != null) {
                  final pid = GoRouterState.of(
                    context,
                  ).uri.queryParameters['playlistId'];
                  final iid = GoRouterState.of(
                    context,
                  ).uri.queryParameters['itemId'];
                  // Prefer itemId if available, fallback to playlistId (legacy/playlist move)
                  final idParam = iid != null
                      ? "itemId=$iid"
                      : (pid != null ? "playlistId=$pid" : "");

                  // Also pass isFolder param if present
                  final isFolderParam = GoRouterState.of(
                    context,
                  ).uri.queryParameters['isFolder'];
                  final q = idParam.isNotEmpty
                      ? "?$idParam${isFolderParam != null ? "&isFolder=$isFolderParam" : ""}"
                      : "";

                  context.push('/folder-picker/${folder.id}$q');
                } else {
                  context.push('/library/${folder.id}');
                }
              },
            );
          } else {
            // --- PLAYLIST ROW ---
            final playlist = playlists[index - folders.length];
            final bloc = context.read<FileSystemBloc>();
            return LibraryRowWidget(
              title: playlist.name,
              albumId: null,
              isFolder: false,
              onLongPress: () {
                if (onPlaylistSelected == null && onFolderSelected == null) {
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) {
                      return BlocProvider.value(
                        value: bloc,
                        child: PlaylistOptionsScreen(
                          playlistId: playlist.id,
                          fromPlaylistScreen: false,
                        ),
                      );
                    },
                  );
                }
              },
              onTap: () {
                if (onPlaylistSelected != null) {
                  onPlaylistSelected!(context, playlist.id);
                } else if (onFolderSelected != null) {
                  // Do nothing
                } else {
                  context.push('/library/playlist/${playlist.id}');
                }
              },
            );
          }
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await HapticFeedback.mediumImpact();
        await sl<SyncManager>().triggerSync();
      },
      child: content,
    );
  }

  void _showCreateOptions(BuildContext context) {
    final bloc = context.read<FileSystemBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return BlocProvider.value(
          value: bloc,
          child: PlaylistAndFolderCreationScreen(parentFolderId: folderId),
        );
      },
    );
  }
}

class PlaylistAndFolderCreationScreen extends StatefulWidget {
  final String? parentFolderId;

  const PlaylistAndFolderCreationScreen({super.key, this.parentFolderId});

  @override
  State<PlaylistAndFolderCreationScreen> createState() =>
      _PlaylistAndFolderCreationScreenState();
}

class _PlaylistAndFolderCreationScreenState
    extends State<PlaylistAndFolderCreationScreen> {
  TextEditingController nameController = TextEditingController();
  var secondPage = false;
  var isPlaylist = true;

  @override
  Widget build(BuildContext context) {
    // final playlistsCubit = context.read<PlaylistsCubit>();

    if (secondPage) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom:
              MediaQuery.of(context).viewInsets.bottom +
              16.0 +
              MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16.0,
          children: [
            Text(
              isPlaylist ? 'New Playlist' : 'New Folder',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: nameController,
              maxLength: 50,
              decoration: const InputDecoration(hintText: 'Name'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  if (isPlaylist) {
                    context.read<FileSystemBloc>().add(
                      FileSystemEvent.createPlaylist(name),
                    );
                  } else {
                    context.read<FileSystemBloc>().add(
                      FileSystemEvent.createFolder(name),
                    );
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      );
    }

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
            leading: Icon(AppIcons.musicNote),
            title: const Text('New Playlist'),
            onTap: () {
              setState(() {
                isPlaylist = true;
                secondPage = true;
              });
              nameController.clear();
            },
          ),
          HoverableListTile(
            leading: Icon(AppIcons.folder),
            title: const Text('New Folder'),
            onTap: () {
              setState(() {
                isPlaylist = false;
                secondPage = true;
              });
              nameController.clear();
            },
          ),
        ],
      ),
    );
  }
}
