import 'package:flutter/material.dart';

class AlbumSearchTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const AlbumSearchTile({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: Image.asset(
          'assets/default-album-lq.png',
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
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
