import 'package:flutter/material.dart';
import 'package:distributeapp/components/hoverable_area.dart';

class PlaylistSearchTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const PlaylistSearchTile({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoverableArea(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: Image.asset(
            'assets/default-playlist-lq.png',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        dense: true,
      ),
    );
  }
}
