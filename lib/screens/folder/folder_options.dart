import 'package:distributeapp/blocs/file_system_bloc.dart';
import 'package:distributeapp/model/playlist_folder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class FolderOptionsScreen extends StatefulWidget {
  final PlaylistFolder folder;

  const FolderOptionsScreen({super.key, required this.folder});

  @override
  State<FolderOptionsScreen> createState() => _FolderOptionsScreenState();
}

class _FolderOptionsScreenState extends State<FolderOptionsScreen> {
  void _showRenameDialog() {
    final nameController = TextEditingController(text: widget.folder.name);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename Folder'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Folder name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty && name != widget.folder.name) {
                  context.read<FileSystemBloc>().add(
                    FileSystemEvent.renameFolder(widget.folder.id, name),
                  );

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                } else {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: Text(
            'Are you sure you want to delete "${widget.folder.name}"? This will also delete all playlists and folders inside it. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<FileSystemBloc>().add(
                  FileSystemEvent.deleteFolder(widget.folder.id),
                );

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showMoveFolderDialog() {
    Navigator.of(context).pop(); // Close the options sheet first
    context.push('/folder-picker?itemId=${widget.folder.id}&isFolder=true');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename Folder'),
            onTap: _showRenameDialog,
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_move),
            title: const Text('Move to Folder'),
            onTap: _showMoveFolderDialog,
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Folder'),
            onTap: _showDeleteDialog,
          ),
        ],
      ),
    );
  }
}
