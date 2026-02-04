import 'package:distributeapp/screens/library/album_image.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:distributeapp/components/hoverable_area.dart';

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
    return HoverableArea(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8.0),
      child: ListTile(
        leading: LibraryLeadingIcon(albumId: albumId, isFolder: isFolder),
        trailing: Icon(AppIcons.chevronRight, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        dense: true,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // onTap handled by HoverableArea
      ),
    );
  }
}
