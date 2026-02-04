import 'package:distributeapp/core/artwork/artwork_cubit.dart';
import 'package:distributeapp/core/artwork/artwork_repository.dart';
import 'package:distributeapp/core/artwork/artwork_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LibraryLeadingIcon extends StatelessWidget {
  const LibraryLeadingIcon({
    super.key,
    required this.albumId,
    required this.isFolder,
  });

  final String? albumId;
  final bool isFolder;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ArtworkRepository>();
    final cubit = ArtworkCubit(repository);

    if (albumId != null) {
      cubit.loadImage(albumId!, ArtQuality.lq);
    }

    return BlocProvider(
      create: (context) => cubit,
      child: BlocBuilder<ArtworkCubit, ArtworkState>(
        builder: (context, state) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(albumId != null ? 8.0 : 0.0),
            child: albumId != null
                ? switch (state) {
                    ArtworkLoading() || ArtworkInitial() => Image.asset(
                      isFolder
                          ? 'assets/default-folder-lq.png'
                          : 'assets/default-playlist-lq.png',
                      key: ValueKey(
                        isFolder ? 'default-folder' : 'default-playlist',
                      ),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                    ArtworkVisible(image: final image) => Image.file(
                      image,
                      key: ValueKey('artwork-$albumId'),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                    ArtworkError() => Image.asset(
                      isFolder
                          ? 'assets/default-folder-lq.png'
                          : 'assets/default-playlist-lq.png',
                      key: ValueKey(
                        isFolder ? 'default-folder' : 'default-playlist',
                      ),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  }
                : Image.asset(
                    isFolder
                        ? 'assets/default-folder-lq.png'
                        : 'assets/default-playlist-lq.png',
                    key: ValueKey(
                      isFolder ? 'default-folder' : 'default-playlist',
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
