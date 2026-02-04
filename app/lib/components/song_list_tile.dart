import 'package:distributeapp/screens/library/album_image.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:distributeapp/components/hoverable_icon_button.dart';
import 'package:distributeapp/components/hoverable_area.dart';

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
    return HoverableArea(
      onTap: onAdd ?? onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: ListTile(
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
            : HoverableIconButton(
                onPressed: onAdd,
                icon: Icon(AppIcons.add, color: Colors.white, size: 20),
              ),
        // onTap: onAdd ?? onTap, // Moved to HoverableArea
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        dense: true,
      ),
    );
  }
}
