import 'package:distributeapp/model/song.dart';
import 'package:distributeapp/screens/player/player_slider.dart';
import 'package:distributeapp/screens/player/queue_sheet.dart';
import 'package:distributeapp/screens/player/vinyl.dart';
import 'package:distributeapp/core/preferences/vinyl_style.dart';
import 'package:distributeapp/core/artwork/artwork_repository.dart';
import 'package:distributeapp/blocs/music/music_player_bloc.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:distributeapp/components/hoverable_icon_button.dart';
import 'dart:io';

class FullPlayerContent extends StatelessWidget {
  final Song? currentSong;
  final ArtworkData artworkData;
  final EdgeInsets safePadding;
  final VoidCallback onCloseTap;
  final VoidCallback onPlayPause;
  final bool isPlaying;
  final bool isWindowFocused;
  final bool keepVinylSpinningWhenUnfocused;
  final VinylStyle style;

  const FullPlayerContent({
    super.key,
    required this.currentSong,
    required this.artworkData,
    required this.safePadding,
    required this.onCloseTap,
    required this.onPlayPause,
    required this.isPlaying,
    required this.isWindowFocused,
    required this.keepVinylSpinningWhenUnfocused,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final artworkFile = artworkData.imageFileHq;

    final easterEggs = [
      currentSong?.title.contains("You Spin Me Round (Like a Record)") ??
          false, // 0 - fast spin
      ((currentSong?.title.contains("Money") ?? false) &&
          (currentSong?.artist.contains("Pink Floyd") ??
              false)), // 1 - gold record
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: Platform.isMacOS ? 136.0 : null, // 56 + 80
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HoverableIconButton(
                  icon: Icon(AppIcons.menu, color: Colors.white),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const QueueSheet(),
                    );
                  },
                ),
                HoverableIconButton(
                  icon: Icon(AppIcons.arrowDown, color: Colors.white),
                  onPressed: onCloseTap,
                ),
              ],
            ),
          ),
        ],
      ),
      body: RepaintBoundary(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: artworkFile != null
                      ? VinylWidget(
                          coverFile: artworkFile,
                          backgroundColor: artworkData.backgroundColor,
                          effectColor: artworkData.effectColor,
                          isPlaying: isPlaying,
                          easterEggs: easterEggs,
                          isWindowFocused: isWindowFocused,
                          keepSpinningWhenUnfocused:
                              keepVinylSpinningWhenUnfocused,
                          style: style,
                        )
                      : const SizedBox(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 40.0,
                      left: 28.0,
                      right: 28.0,
                      top: 8.0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final title =
                                      currentSong?.title ?? 'Unknown Title';
                                  final format =
                                      ".${currentSong?.format ?? 'flac'}";
                                  const bitrate = "16-bit / 44.1kHz";

                                  final titleStyle = const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  );
                                  final tagStyle = TextStyle(
                                    color: artworkData.primaryColor,
                                    fontSize: 12,
                                  );

                                  double measureText(
                                    String text,
                                    TextStyle style,
                                  ) {
                                    final textPainter = TextPainter(
                                      text: TextSpan(text: text, style: style),
                                      maxLines: 1,
                                      textDirection: TextDirection.ltr,
                                    );
                                    textPainter.layout();
                                    return textPainter.size.width;
                                  }

                                  final titleWidth = measureText(
                                    title,
                                    titleStyle,
                                  );
                                  final formatWidth =
                                      measureText(format, tagStyle) + 20;
                                  final bitrateWidth =
                                      measureText(bitrate, tagStyle) + 20;

                                  const gap1 = 8.0;
                                  const gap2 = 4.0;

                                  final allTagsWidth =
                                      gap1 + formatWidth + gap2 + bitrateWidth;
                                  final oneTagWidth = gap1 + formatWidth;

                                  final availableWidth = constraints.maxWidth;
                                  final showAll =
                                      titleWidth + allTagsWidth <=
                                      availableWidth;
                                  final showOne =
                                      !showAll &&
                                      (titleWidth + oneTagWidth <=
                                          availableWidth);

                                  return Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          title,
                                          textAlign: TextAlign.left,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: titleStyle,
                                        ),
                                      ),
                                      if (showAll || showOne)
                                        SizedBox(width: gap1),
                                      if (showAll || showOne)
                                        QualityTagWidget(
                                          title: format,
                                          color: artworkData.tintedColor(),
                                        ),
                                      if (showAll) SizedBox(width: gap2),
                                      if (showAll &&
                                          currentSong?.format == "flac")
                                        QualityTagWidget(
                                          title: bitrate,
                                          color: artworkData.tintedColor(),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentSong?.artist ?? 'Unknown Artist',
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          MusicPlayerSlider(
                            primaryColor: artworkData.tintedColor(),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HoverableIconButton(
                                onPressed: () {
                                  context.read<MusicPlayerBloc>().add(
                                    const MusicPlayerEvent.skipToPrevious(),
                                  );
                                },
                                iconSize: AppIcons.isCupertino ? 36 : 50,
                                color: artworkData.tintedColor(),
                                icon: Icon(AppIcons.fastRewind),
                              ),
                              SizedBox(width: AppIcons.isCupertino ? 44 : 32),
                              HoverableIconButton(
                                onPressed: onPlayPause,
                                iconSize: AppIcons.isCupertino ? 54 : 50,
                                color: artworkData.tintedColor(),
                                icon: Icon(
                                  isPlaying ? AppIcons.pause : AppIcons.play,
                                ),
                              ),
                              SizedBox(width: AppIcons.isCupertino ? 44 : 32),
                              HoverableIconButton(
                                onPressed: () {
                                  context.read<MusicPlayerBloc>().add(
                                    const MusicPlayerEvent.skipToNext(),
                                  );
                                },
                                iconSize: AppIcons.isCupertino ? 36 : 50,
                                color: artworkData.tintedColor(),
                                icon: Icon(AppIcons.fastForward),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QualityTagWidget extends StatelessWidget {
  const QualityTagWidget({super.key, required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        // child: BackdropFilter(
        // filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withAlpha(30),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(title, style: TextStyle(color: color, fontSize: 12)),
        ),
        // ),
      ),
    );
  }
}
