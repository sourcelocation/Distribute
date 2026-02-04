import 'package:distributeapp/blocs/search_bloc.dart';

import 'package:distributeapp/model/local_search_result.dart';
import 'package:distributeapp/model/server_search_result.dart';
import 'package:distributeapp/screens/error_message.dart';
import 'package:distributeapp/screens/search/search_not_found.dart';
import 'package:distributeapp/screens/search/rows/album_search_tile.dart';
import 'package:distributeapp/screens/search/rows/artist_search_tile.dart';
import 'package:distributeapp/screens/search/rows/playlist_search_tile.dart';
import 'package:distributeapp/screens/search/rows/song_search_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:distributeapp/components/blurry_app_bar.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: BlurryAppBar(
        center: Text("Search", style: theme.textTheme.titleMedium),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          8.0,
          10.0 + kToolbarHeight + MediaQuery.of(context).padding.top,
          8.0,
          10.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildSearchBar(context),
            ),
            const SizedBox(height: 20),
            _buildResultList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      onChanged: (value) =>
          context.read<SearchBloc>().add(SongSearchEvent.queryChanged(value)),
      decoration: InputDecoration(
        hintText: "Search songs...",
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _buildResultList() {
    return BlocBuilder<SearchBloc, SongSearchState>(
      builder: (context, state) {
        return state.when(
          // 1. Initial State
          initial: () => _startTypingToSearch(context),

          // 2. Error State
          error: (message) => Center(child: ErrorMessage(message: message)),

          // 3. Content State (Handles Data + Loading)
          content: (localResults, remoteResults, isRemoteLoading) {
            // Case A: Nothing found anywhere and not loading
            if (localResults.isEmpty &&
                remoteResults.isEmpty &&
                !isRemoteLoading) {
              return SearchNotFoundWidget(
                onRequestTap: () => context.go('/settings/requests'),
              );
            }

            // Case B: Render the lists
            return _buildContentList(
              context,
              localResults,
              remoteResults,
              isRemoteLoading,
            );
          },
        );
      },
    );
  }

  Widget _buildContentList(
    BuildContext context,
    List<LocalSearchResult> local,
    List<ServerSearchResult> remote,
    bool isLoading,
  ) {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        children: [
          // --- Local Section ---
          if (local.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Library",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...local.map((song) => _buildSongTile(context, song)),
          ],

          // --- Remote Section ---
          if (remote.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Global Search",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...remote.map((item) => _buildRemoteResultTile(context, item)),
          ],

          // --- Loading Indicator ---
          // Appears at the bottom while remote search is active
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSongTile(BuildContext context, LocalSearchResult song) {
    return SongSearchTile(
      title: song.title,
      artist: song.artistName,
      albumId: song.albumId,
      onAdd: () => onLocalSongTap(context, song),
      onTap: () {},
    );
  }

  Widget _buildRemoteResultTile(BuildContext context, ServerSearchResult item) {
    return item.map(
      song: (s) => SongSearchTile(
        title: s.title,
        artist: s.artists.map((a) => a.name).join(', '),
        albumId: s.albumId,
        onAdd: () => onRemoteSongTap(context, s),
        onTap: () {},
      ),
      artist: (a) => ArtistSearchTile(name: a.title),
      album: (a) => AlbumSearchTile(title: a.title),
      playlist: (p) => PlaylistSearchTile(title: p.title),
      unknown: (_) => const SizedBox.shrink(),
    );
  }

  Widget _startTypingToSearch(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 64.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              AppIcons.musicNoteRounded,
              size: 24,
              color: theme.colorScheme.secondary,
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                "Start typing to search",
                style: TextStyle(color: theme.colorScheme.secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onLocalSongTap(BuildContext context, LocalSearchResult song) {
    context.push('/picker?songId=${song.id}', extra: song);
  }

  void onRemoteSongTap(BuildContext context, ServerSearchResult song) {
    context.push('/picker?songId=${song.id}', extra: song);
  }
}
