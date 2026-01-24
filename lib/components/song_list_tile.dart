import 'package:distributeapp/screens/library/album_image.dart';
import 'package:flutter/material.dart';

class SongListTile extends StatelessWidget {
  final String title;
  final String artist;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final String? albumId;

  const SongListTile({
    super.key,
    required this.title,
    required this.artist,
    required this.onTap,
    this.albumId,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: LibraryLeadingIcon(albumId: albumId, isFolder: false),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(artist, style: Theme.of(context).textTheme.bodySmall),
      trailing: onAdd == null
          ? null
          : IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add, color: Colors.white),
            ),
      onTap: onAdd ?? onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }
}
