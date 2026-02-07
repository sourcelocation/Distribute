import 'package:distributeapp/core/artwork/artwork_cubit.dart';
import 'package:distributeapp/core/artwork/artwork_repository.dart';
import 'package:distributeapp/core/artwork/artwork_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LibraryLeadingIcon extends StatefulWidget {
  const LibraryLeadingIcon({
    super.key,
    required this.albumId,
    required this.isFolder,
  });

  final String? albumId;
  final bool isFolder;

  @override
  State<LibraryLeadingIcon> createState() => _LibraryLeadingIconState();
}

class _LibraryLeadingIconState extends State<LibraryLeadingIcon> {
  late final ArtworkCubit _cubit;

  @override
  void initState() {
    super.initState();
    final repository = context.read<ArtworkRepository>();
    _cubit = ArtworkCubit(repository);
    _loadIfNeeded(widget.albumId);
  }

  @override
  void didUpdateWidget(covariant LibraryLeadingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.albumId != widget.albumId) {
      _loadIfNeeded(widget.albumId);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _loadIfNeeded(String? albumId) {
    if (albumId != null) {
      _cubit.loadImage(albumId, ArtQuality.lq);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<ArtworkCubit, ArtworkState>(
        builder: (context, state) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(
              widget.albumId != null ? 8.0 : 0.0,
            ),
            child: widget.albumId != null
                ? switch (state) {
                    ArtworkLoading() || ArtworkInitial() => Image.asset(
                      widget.isFolder
                          ? 'assets/default-folder-lq.png'
                          : 'assets/default-playlist-lq.png',
                      key: ValueKey(
                        widget.isFolder ? 'default-folder' : 'default-playlist',
                      ),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                    ArtworkVisible(image: final image) => Image.file(
                      image,
                      key: ValueKey('artwork-${widget.albumId}'),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                    ArtworkError() => Image.asset(
                      widget.isFolder
                          ? 'assets/default-folder-lq.png'
                          : 'assets/default-playlist-lq.png',
                      key: ValueKey(
                        widget.isFolder ? 'default-folder' : 'default-playlist',
                      ),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  }
                : Image.asset(
                    widget.isFolder
                        ? 'assets/default-folder-lq.png'
                        : 'assets/default-playlist-lq.png',
                    key: ValueKey(
                      widget.isFolder ? 'default-folder' : 'default-playlist',
                    ),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
          );
        },
      ),
    );
  }
}
