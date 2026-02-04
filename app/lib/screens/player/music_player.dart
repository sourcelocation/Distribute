import 'dart:ui';

import 'package:distributeapp/blocs/music/position_cubit.dart';
import 'package:distributeapp/screens/player/player_fullscreen_content.dart';
import 'package:distributeapp/core/preferences/settings_cubit.dart';
import 'package:distributeapp/core/ui/dimensions.dart';
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

/// Duration for the artwork crossfade animation
const Duration _artworkCrossfadeDuration = Duration(milliseconds: 600);

class MusicPlayer extends StatefulWidget {
  const MusicPlayer({super.key});

  @override
  State<MusicPlayer> createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const double _miniHeight = Dimensions.kMiniPlayerHeight;
  static const double _miniRadius = 12.0;

  late final AnimationController _enterController;
  late final AnimationController _expandController;

  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  late final PageController _pageController;

  final FocusNode _focusNode = FocusNode();
  bool _isProgrammaticPageChange = false;
  int _programmaticTargetIndex = -1;
  bool _isWindowFocused = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isWindowFocused =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final focused = state == AppLifecycleState.resumed;
    if (_isWindowFocused != focused) {
      setState(() {
        _isWindowFocused = focused;
      });
    }
  }

  void _onExpandTap() {
    if (_expandController.value < 0.5) {
      _expandController.animateTo(
        1.0,
        curve: Curves.linearToEaseOut,
        duration: const Duration(milliseconds: 500),
      );
      _focusNode.requestFocus();
    }
  }

  void _onCloseTap() {
    if (!_expandController.isDismissed) {
      _expandController.animateTo(
        0.0,
        curve: Curves.linearToEaseOut,
        duration: const Duration(milliseconds: 500),
      );
      _focusNode.unfocus();
    }
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
    bool showMiniProgress = true,
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
        if (isCurrent && showMiniProgress)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: RepaintBoundary(
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
          previous.vinylStyle != current.vinylStyle ||
          previous.keepVinylSpinningWhenUnfocused !=
              current.keepVinylSpinningWhenUnfocused,
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
              _expandController.animateTo(
                0.0,
                curve: Curves.linearToEaseOut,
                duration: const Duration(milliseconds: 500),
              );
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
                  _isProgrammaticPageChange = true;
                  _programmaticTargetIndex = state.queueIndex;
                  _pageController.jumpToPage(targetPage);
                } else if (_pageController.position.userScrollDirection ==
                    ScrollDirection.idle) {
                  _isProgrammaticPageChange = true;
                  _programmaticTargetIndex = state.queueIndex;
                  _pageController.animateToPage(
                    targetPage,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.linearToEaseOut,
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
              10,
              MediaQuery.of(context).padding.bottom + 90,
            );

            void handleDragUpdate(DragUpdateDetails details) {
              final double delta =
                  details.primaryDelta! / (maxPlayerHeight - _miniHeight);
              if (_miniHeight + (details.primaryDelta ?? 0) > maxPlayerHeight) {
                return;
              }
              _expandController.value -= delta;
            }

            void handleDragEnd(DragEndDetails details) {
              const double velocityThreshold = 300.0;
              final double velocity = details.primaryVelocity!;

              final Curve curve = Curves.linearToEaseOut;
              const duration = Duration(milliseconds: 500);
              if (velocity < -velocityThreshold) {
                _expandController.animateTo(
                  1.0,
                  curve: curve,
                  duration: duration,
                );
              } else if (velocity > velocityThreshold) {
                _expandController.animateTo(
                  0.0,
                  curve: curve,
                  duration: duration,
                );
              } else if (_expandController.value > 0.5) {
                _expandController.animateTo(
                  1.0,
                  curve: curve,
                  duration: duration,
                );
              } else {
                _expandController.animateTo(
                  0.0,
                  curve: curve,
                  duration: duration,
                );
              }
            }

            if (currentSong == null && _enterController.isDismissed) {
              return const SizedBox.shrink();
            }

            final Widget fullPlayer = GestureDetector(
              onVerticalDragUpdate: handleDragUpdate,
              onVerticalDragEnd: handleDragEnd,
                child: FullPlayerContent(
                  currentSong: currentSong,
                  artworkData: artworkData,
                  safePadding: MediaQuery.of(context).padding,
                  onCloseTap: _onCloseTap,
                  isPlaying: isPlaying,
                  onPlayPause: () => context.read<MusicPlayerBloc>().add(
                    MusicPlayerEvent.togglePlayPause(),
                  ),
                  style: settingsState.vinylStyle,
                  isWindowFocused: _isWindowFocused,
                  keepVinylSpinningWhenUnfocused:
                      settingsState.keepVinylSpinningWhenUnfocused,
                ),
            );

            return AnimatedBuilder(
              animation: Listenable.merge([
                _enterController,
                _expandController,
              ]),
              builder: (context, _) {
                final t = _expandController.value;

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
                final miniPlayerWidth =
                    maxPlayerWidth - miniMargin.left - miniMargin.right;
                final currentWidth = lerpDouble(
                  miniPlayerWidth,
                  maxPlayerWidth,
                  t,
                )!;
                final currentRadius = lerpDouble(_miniRadius, 0, t)!;
                final enterOffset = _slideAnimation.value.dy * _miniHeight;

                final Widget backgroundColorOverlay = Container(
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
                );

                return Positioned(
                  height: currentHeight,
                  width: currentWidth,
                  left: currentMargin.left,
                  bottom: currentMargin.bottom - enterOffset,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      clipBehavior: Clip.hardEdge,
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
                          _CrossfadeArtwork(currentArtwork: artworkData),
                          ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                              },
                            ),
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: _onExpandTap,
                              onVerticalDragUpdate: handleDragUpdate,
                              onVerticalDragEnd: handleDragEnd,
                              child: Opacity(
                                opacity: 1.0 - t,
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: null,
                                  physics: const PageScrollPhysics(),
                                  onPageChanged: (page) {
                                    if (state.queue.isEmpty) return;
                                    var index = page % state.queue.length;

                                    if (_isProgrammaticPageChange) {
                                      if (index == _programmaticTargetIndex) {
                                        _isProgrammaticPageChange = false;
                                        _programmaticTargetIndex = -1;
                                      }
                                      return;
                                    }

                                    debugPrint("index: $index");
                                    debugPrint(
                                      "queueIndex: ${state.queueIndex}",
                                    );

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
                                    final queueIndex =
                                        index % state.queue.length;
                                    final item = state.queue[queueIndex];
                                    final isCurrentItem =
                                        queueIndex == state.queueIndex;

                                    return _buildSlideContent(
                                      context,
                                      item,
                                      artworkData,
                                      isCurrent: isCurrentItem,
                                      showMiniProgress: t < 0.5,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          IgnorePointer(
                            ignoring: t < 0.5,
                            child: Opacity(
                              opacity: t.clamp(0.0, 1.0),
                              child: backgroundColorOverlay,
                            ),
                          ),
                          IgnorePointer(
                            ignoring: t < 0.5,
                            child: Visibility(
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

/// Widget that displays artwork with crossfade support between song changes
class _CrossfadeArtwork extends StatefulWidget {
  final ArtworkData currentArtwork;

  const _CrossfadeArtwork({required this.currentArtwork});

  @override
  State<_CrossfadeArtwork> createState() => _CrossfadeArtworkState();
}

class _CrossfadeArtworkState extends State<_CrossfadeArtwork>
    with TickerProviderStateMixin {
  ArtworkData? _displayedArtwork;
  ArtworkData? _fadingOutArtwork;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _displayedArtwork = widget.currentArtwork;
    _fadeController = AnimationController(
      vsync: this,
      duration: _artworkCrossfadeDuration,
    );
    _fadeController.value = 1.0;
  }

  @override
  void didUpdateWidget(_CrossfadeArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if artwork actually changed
    final oldPath = _getArtworkKey(oldWidget.currentArtwork);
    final newPath = _getArtworkKey(widget.currentArtwork);

    if (oldPath != newPath) {
      // Start crossfade
      _fadingOutArtwork = oldWidget.currentArtwork;
      _displayedArtwork = widget.currentArtwork;

      _fadeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _getArtworkKey(ArtworkData artwork) {
    return artwork.imageFileLq?.path ??
        artwork.imageFileHq?.path ??
        artwork.artUri?.toString() ??
        'default-artwork';
  }

  Widget _buildImage(ArtworkData artwork) {
    return artwork.imageFileHq != null
        ? Image.file(
            artwork.imageFileHq!,
            key: ValueKey(artwork.imageFileHq!.path),
            cacheWidth: 400,
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          )
        : Image.asset(
            'assets/default-playlist-lq.png',
            key: const ValueKey('default-asset'),
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          );
  }

  Widget _buildBlurredLayer(Widget child) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: 6,
        sigmaY: 6,
        tileMode: TileMode.clamp,
      ),
      child: SizedBox.expand(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: widget.currentArtwork.backgroundColor,
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
          // Fading out artwork (previous)
          if (_fadingOutArtwork != null)
            AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Opacity(
                  opacity: 1.0 - _fadeController.value,
                  child: child,
                );
              },
              child: _buildBlurredLayer(_buildImage(_fadingOutArtwork!)),
            ),
          // Fading in artwork (current)
          AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return Opacity(opacity: _fadeController.value, child: child);
            },
            child: _buildBlurredLayer(_buildImage(_displayedArtwork!)),
          ),
        ],
      ),
    );
  }
}
