import 'package:distributeapp/components/song_list_tile.dart';
import 'package:flutter/material.dart';

class SongSearchTile extends StatelessWidget {
  final String title;
  final String artist;
  final String? albumId;
  final VoidCallback onTap;
  final VoidCallback? onAdd;

  const SongSearchTile({
    super.key,
    required this.title,
    required this.artist,
    required this.onTap,
    this.albumId,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SongListTile(
      title: title,
      artist: artist,
      albumId: albumId,
      onTap: onTap,
      onAdd: onAdd,
    );
  }
}
