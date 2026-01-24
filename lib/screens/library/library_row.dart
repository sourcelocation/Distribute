import 'package:distributeapp/screens/library/album_image.dart';
import 'package:flutter/material.dart';

class LibraryRowWidget extends StatelessWidget {
  final String title;
  final String? albumId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isFolder;

  const LibraryRowWidget({
    required this.title,
    required this.onTap,
    this.onLongPress,
    required this.albumId,
    required this.isFolder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: LibraryLeadingIcon(albumId: albumId, isFolder: isFolder),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
