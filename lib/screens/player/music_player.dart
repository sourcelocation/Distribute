import 'dart:math';
import 'dart:ui';

import 'package:distributeapp/blocs/music/position_cubit.dart';
import 'package:distributeapp/screens/player/player_fullscreen_content.dart';
import 'package:distributeapp/core/preferences/settings_cubit.dart';
import 'package:distributeapp/core/preferences/settings_state.dart';
import 'package:distributeapp/screens/player/player_mini_content.dart';
import 'package:distributeapp/blocs/music/music_player_bloc.dart';
import 'package:distributeapp/repositories/audio/music_player_controller.dart';
import 'package:distributeapp/core/artwork/artwork_repository.dart';
import 'package:distributeapp/model/song.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MusicPlayer extends StatefulWidget {
  const MusicPlayer({super.key});

  @override
  State<MusicPlayer> createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer>
    with TickerProviderStateMixin {
  static const double _miniHeight = 85;
  static const double _miniRadius = 12.0;

  late final AnimationController _enterController;
  late final AnimationController _expandController;

  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  late final PageController _pageController;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _enterController, curve: Curves.easeOutCirc),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _enterController, curve: Curves.easeOut));

    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
      reverseDuration: const Duration(milliseconds: 300),
    );

    final state = context.read<MusicPlayerBloc>().state;
    if (state.currentSong != null) {
      _enterController.value = 1.0;
    }

    _pageController = PageController(initialPage: _getInitialPage());
  }

  int _getInitialPage() {
    final state = context.read<MusicPlayerBloc>().state;
    int initialPage = 50000;
    if (state.queue.isNotEmpty) {
      final length = state.queue.length;
      final index = state.queueIndex;
      initialPage = 50000 - (50000 % length) + index;
    }

    return initialPage;
  }

  @override
  void dispose() {
    _enterController.dispose();
    _expandController.dispose();
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onExpandTap() {
    if (_expandController.isDismissed) {
      _expandController.forward(from: 0);
      _focusNode.requestFocus();
    }
  }

  void _onCloseTap() {
    if (!_expandController.isDismissed) {
      _expandController.reverse();
      _focusNode.unfocus();
    }
  }

  Widget _buildArtwork(BuildContext context, ArtworkData artworkData) {
    final image = artworkData.imageFileHq != null
        ? Image.file(
            artworkData.imageFileHq!,
            key: ValueKey(artworkData.imageFileHq!.path),
            cacheWidth: 400,
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          )
        : Image.asset(
            'assets/default-playlist-hq.png',
            key: const ValueKey('default-asset'),
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          );

    return Container(
      key: ValueKey(artworkData.imageFileHq?.path),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: artworkData.backgroundColor,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255.0 * 0.2).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            foregroundDecoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.center,
                colors: [
                  const Color.fromARGB(80, 0, 0, 0),
                  const Color.fromARGB(20, 0, 0, 0),
                ],
              ),
            ),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 5,
                sigmaY: 5,
                tileMode: TileMode.clamp,
              ),
              child: OverflowBox(
                minWidth: 0,
                minHeight: 0,
                maxWidth: MediaQuery.of(context).size.width,
                maxHeight: MediaQuery.of(context).size.width,
                child: image,
              ),
            ),
          ),
          Container(color: Colors.black.withAlpha((255 * 0.2).toInt())),
        ],
      ),
    );
  }

  Widget _buildMiniContent(
    BuildContext context,
    MediaItem item,
    ArtworkData artworkData,
    bool isPlaying,
  ) {
    final song = Song(
      id: item.id,
      title: item.title,
      artists: [item.artist ?? 'Unknown'],
      albumTitle: item.album ?? '',
      albumId: '',
      fileId: null,
      format: null,
      isDownloaded: false,
    );

    final borderColor = Color.lerp(
      artworkData.backgroundColor.withAlpha(128),
      artworkData.effectColor,
      0.5,
    )!;

    return MiniPlayerContent(
      currentSong: song,
      isPlaying: isPlaying,
      onPlayPressed: () => context.read<MusicPlayerBloc>().add(
        MusicPlayerEvent.togglePlayPause(),
      ),
      borderColor: borderColor.withAlpha(50),
    );
  }

  Widget? _buildSlideContent(
    BuildContext context,
    MediaItem? item,
    ArtworkData? artworkData, {
    bool isCurrent = false,
  }) {
    if (item == null || artworkData == null) return null;

    return Stack(
      children: [
        _buildMiniContent(
          context,
          item,
          artworkData,
          isCurrent ? context.read<MusicPlayerBloc>().state.isPlaying : false,
        ),
        if (isCurrent)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BlocBuilder<PositionCubit, Duration>(
              builder: (context, currentPosition) {
                final state = context.read<MusicPlayerBloc>().state;
                final durationMs = state.duration.inMilliseconds;
                final progress = durationMs > 0
                    ? currentPosition.inMilliseconds / durationMs
                    : 0.0;
                return Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(height: 3, color: Colors.white),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxPlayerHeight = size.height;
    final maxPlayerWidth = size.width;

    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (previous, current) =>
          previous.vinylStyle != current.vinylStyle,
      builder: (context, settingsState) {
        return BlocConsumer<MusicPlayerBloc, ControllerState>(
          listenWhen: (previous, current) =>
              previous.currentSong != current.currentSong ||
              previous.queueIndex != current.queueIndex,
          listener: (context, state) {
            if (state.currentSong != null) {
              _enterController.forward();
            } else {
              _enterController.reverse();
              _expandController.reverse();
            }

            if (state.queue.isNotEmpty && _pageController.hasClients) {
              final length = state.queue.length;
              final currentPage =
                  _pageController.page?.round() ?? _getInitialPage();
              final currentQueueIndex = currentPage % length;

              if (currentQueueIndex != state.queueIndex) {
                final targetPage =
                    currentPage - currentQueueIndex + state.queueIndex;
                final offset =
                    (targetPage - (_pageController.page ?? targetPage)).abs();

                if (offset > 1) {
                  _pageController.jumpToPage(targetPage);
                } else if (_pageController.position.userScrollDirection ==
                    ScrollDirection.idle) {
                  _pageController.animateToPage(
                    targetPage,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              }
            }
          },
          builder: (context, state) {
            final currentSong = state.currentSong;
            final artworkData = state.artworkData;
            final isPlaying = state.isPlaying;
            final miniMargin = EdgeInsets.fromLTRB(
              10,
              10,
              0,
              MediaQuery.of(context).padding.bottom + 90,
            );

            if (currentSong == null && _enterController.isDismissed) {
              return const SizedBox.shrink();
            }

            final Widget fullPlayer = FullPlayerContent(
              currentSong: currentSong,
              artworkData: artworkData,
              safePadding: MediaQuery.of(context).padding,
              onCloseTap: _onCloseTap,
              isPlaying: isPlaying,
              onPlayPause: () => context.read<MusicPlayerBloc>().add(
                MusicPlayerEvent.togglePlayPause(),
              ),
              style: settingsState.vinylStyle,
            );

            return AnimatedBuilder(
              animation: Listenable.merge([
                _enterController,
                _expandController,
              ]),
              builder: (context, _) {
                final t = CurvedAnimation(
                  parent: _expandController,
                  curve: _expandController.status == AnimationStatus.forward
                      ? Curves.linearToEaseOut
                      : Curves.easeInOutCubic,
                ).value;

                final currentHeight = lerpDouble(
                  _miniHeight,
                  maxPlayerHeight,
                  t,
                )!;
                final currentMargin = EdgeInsets.lerp(
                  miniMargin,
                  EdgeInsets.zero,
                  t,
                )!;
                final miniPlayerWidth = maxPlayerWidth - (miniMargin.left * 2);
                final currentWidth = lerpDouble(
                  miniPlayerWidth,
                  maxPlayerWidth,
                  t,
                )!;
                final currentRadius = lerpDouble(_miniRadius, 0, t)!;
                final enterOffset = _slideAnimation.value.dy * _miniHeight;

                final imageSide = lerpDouble(
                  miniPlayerWidth,
                  max(maxPlayerHeight, maxPlayerWidth),
                  t,
                )!;

                final Widget rawImage = OverflowBox(
                  maxWidth: imageSide,
                  maxHeight: imageSide,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: artworkData.imageFileHq != null
                        ? Image.file(
                            artworkData.imageFileHq!,
                            key: ValueKey(artworkData.imageFileHq!.path),
                            cacheWidth: 800,
                            fit: BoxFit.cover,
                            height: double.infinity,
                            width: double.infinity,
                          )
                        : Image.asset(
                            'assets/default-playlist-hq.png',
                            key: const ValueKey('default-playlist'),
                            fit: BoxFit.cover,
                            height: double.infinity,
                            width: double.infinity,
                          ),
                  ),
                );

                final Widget staticFullBackground = Container(
                  foregroundDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color.lerp(
                          artworkData.backgroundColor,
                          Colors.black,
                          0.2,
                        )!,
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: 7,
                      sigmaY: 7,
                      tileMode: TileMode.clamp,
                    ),
                    child: rawImage,
                  ),
                );

                return Positioned(
                  height: currentHeight,
                  width: currentWidth,
                  left: currentMargin.left,
                  bottom: currentMargin.bottom - enterOffset,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: artworkData.backgroundColor,
                        borderRadius: BorderRadius.circular(currentRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(
                              (255.0 * 0.2).toInt(),
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: _buildArtwork(context, artworkData),
                          ),
                          ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                              },
                            ),
                            child: GestureDetector(
                              onTap: _onExpandTap,
                              onVerticalDragUpdate: (details) {
                                final double delta =
                                    details.primaryDelta! /
                                    (maxPlayerHeight - _miniHeight);
                                if (_miniHeight + (details.primaryDelta ?? 0) >
                                    maxPlayerHeight) {
                                  return;
                                }
                                _expandController.value -= delta;
                              },
                              onVerticalDragEnd: (details) {
                                const double velocityThreshold = 300.0;
                                final double velocity =
                                    details.primaryVelocity!;

                                if (velocity < -velocityThreshold) {
                                  _expandController.forward();
                                } else if (velocity > velocityThreshold) {
                                  _expandController.reverse();
                                } else if (_expandController.value > 0.5) {
                                  _expandController.forward();
                                } else {
                                  _expandController.reverse();
                                }
                              },
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: null,
                                physics: const PageScrollPhysics(),
                                onPageChanged: (page) {
                                  if (state.queue.isEmpty) return;
                                  var index = page % state.queue.length;

                                  debugPrint("page changed: $index");

                                  debugPrint("targetQueueIndex: $index");
                                  debugPrint("queueIndex: ${state.queueIndex}");

                                  if (index != state.queueIndex) {
                                    context.read<MusicPlayerBloc>().add(
                                      MusicPlayerEvent.skipToQueueItem(index),
                                    );
                                  }
                                },
                                itemBuilder: (context, index) {
                                  if (state.queue.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  final queueIndex = index % state.queue.length;
                                  final item = state.queue[queueIndex];
                                  final isCurrentItem =
                                      queueIndex == state.queueIndex;

                                  return _buildSlideContent(
                                    context,
                                    item,
                                    artworkData,
                                    isCurrent: isCurrentItem,
                                  );
                                },
                              ),
                            ),
                          ),
                          if (t > 0)
                            Opacity(
                              opacity: t.clamp(0.0, 1.0),
                              child: staticFullBackground,
                            ),
                          if (t > 0)
                            Container(
                              color: Colors.black.withAlpha(
                                (255 * 0.2 * t).toInt(),
                              ),
                            ),
                          Visibility(
                            visible: t > 0.0,
                            maintainState: true,
                            maintainAnimation: true,
                            maintainSize: true,
                            child: TickerMode(
                              enabled: t > 0.0,
                              child: Opacity(
                                key: const ValueKey('full_player'),
                                opacity: t.clamp(0.0, 1.0),
                                child: Transform.translate(
                                  offset: Offset(0, (1.0 - t) * 50),
                                  child: OverflowBox(
                                    maxWidth: maxPlayerWidth,
                                    minWidth: maxPlayerWidth,
                                    maxHeight: maxPlayerHeight,
                                    minHeight: maxPlayerHeight,
                                    child: fullPlayer,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
