import 'dart:io';

import 'package:distributeapp/core/artwork/artwork_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:distributeapp/core/artwork/artwork_repository.dart';

class ArtworkCubit extends Cubit<ArtworkState> {
  final ArtworkRepository repository;

  ArtworkCubit(this.repository) : super(ArtworkInitial());

  Future<void> loadImage(String albumId, ArtQuality quality) async {
    if (state is ArtworkVisible) {
      final currentState = state as ArtworkVisible;
      final expectedPath = repository.getAbsolutePath(albumId, quality);
      if (currentState.image.path == expectedPath) {
        return;
      }
    }

    emit(ArtworkLoading());

    try {
      final result = await repository.getArtworkData(albumId, quality);

      final File? targetFile = quality == ArtQuality.hq
          ? result.imageFileHq
          : result.imageFileLq;

      if (targetFile != null) {
        emit(
          ArtworkVisible(
            image: targetFile,
            backgroundColor: result.backgroundColor,
            effectColor: result.effectColor,
          ),
        );
      } else {
        emit(ArtworkError("Image file missing in data"));
      }
    } catch (e) {
      emit(ArtworkError(e.toString()));
    }
  }
}
