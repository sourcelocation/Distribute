import 'dart:math';
import 'dart:ui';

import 'package:distributeapp/blocs/music/position_cubit.dart';
import 'package:distributeapp/screens/player/player_fullscreen_content.dart';
import 'package:distributeapp/screens/player/player_mini_content.dart';
import 'package:distributeapp/blocs/music/music_player_bloc.dart';
import 'package:distributeapp/repositories/audio/music_player_controller.dart';
import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
    _enterController.dispose();
    _expandController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxPlayerHeight = size.height;
    final maxPlayerWidth = size.width;

    return BlocConsumer<MusicPlayerBloc, ControllerState>(
      listenWhen: (previous, current) =>
          previous.currentSong != current.currentSong,
      listener: (context, state) {
        if (state.currentSong != null) {
          _enterController.forward();
        } else {
          _enterController.reverse();
          _expandController.reverse();
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

        final borderColor = Color.lerp(
          artworkData.backgroundColor.withAlpha(128),
          artworkData.effectColor,
          0.5,
        )!;
        final Widget miniPlayer = MiniPlayerContent(
          currentSong: currentSong,
          isPlaying: isPlaying,
          onPlayPressed: () => context.read<MusicPlayerBloc>().add(
            MusicPlayerEvent.togglePlayPause(),
          ),
          borderColor: borderColor.withAlpha(50),
        );

        final Widget fullPlayer = FullPlayerContent(
          currentSong: currentSong,
          artworkData: artworkData,
          safePadding: MediaQuery.of(context).padding,
          onCloseTap: _onCloseTap,
          isPlaying: isPlaying,
          onPlayPause: () => context.read<MusicPlayerBloc>().add(
            MusicPlayerEvent.togglePlayPause(),
          ),
        );

        return AnimatedBuilder(
          animation: Listenable.merge([_enterController, _expandController]),
          builder: (context, _) {
            final t = CurvedAnimation(
              parent: _expandController,
              curve: _expandController.status == AnimationStatus.forward
                  ? Curves.linearToEaseOut
                  : Curves.easeInOutCubic,
            ).value;

            final currentHeight = lerpDouble(_miniHeight, maxPlayerHeight, t)!;
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

            final Widget staticMiniBackground = RepaintBoundary(
              child: Container(
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
                  child: rawImage,
                ),
              ),
            );

            final Widget staticFullBackground = RepaintBoundary(
              child: Container(
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
                  child: Transform.scale(scale: 1.0, child: rawImage),
                ),
              ),
            );

            var fadeTransition = FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: _onExpandTap,
                onVerticalDragUpdate: (details) {
                  final double delta =
                      details.primaryDelta! / (maxPlayerHeight - _miniHeight);
                  _expandController.value -= delta;
                },
                onVerticalDragEnd: (details) {
                  const double velocityThreshold = 300.0;
                  final double velocity = details.primaryVelocity!;

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
                behavior: t > 0
                    ? HitTestBehavior.opaque
                    : HitTestBehavior.deferToChild,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: artworkData.backgroundColor,
                    borderRadius: BorderRadius.circular(currentRadius),
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
                      staticMiniBackground,
                      if (t > 0)
                        Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: staticFullBackground,
                        ),
                      Container(
                        color: Colors.black.withAlpha((255 * 0.2 * t).toInt()),
                      ),
                      if (t < 1.0)
                        Opacity(
                          key: const ValueKey('mini_player'),
                          opacity: (1.0 - t).clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, t * -50),
                            child: miniPlayer,
                          ),
                        ),
                      if (t < 1.0)
                        BlocBuilder<PositionCubit, Duration>(
                          builder: (context, currentPosition) {
                            final durationMs = state.duration.inMilliseconds;
                            final progress = durationMs > 0
                                ? currentPosition.inMilliseconds / durationMs
                                : 0.0;
                            return Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: progress.clamp(0.0, 1.0),
                                  child: Container(
                                    height: 3,
                                    color: Colors.white.withAlpha(
                                      ((1.0 - t * 7.0).clamp(0.0, 1.0) * 255)
                                          .toInt(),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
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
            return Positioned(
              height: currentHeight,
              width: currentWidth,
              left: currentMargin.left,
              bottom: currentMargin.bottom - enterOffset,
              child: fadeTransition,
            );
          },
        );
      },
    );
  }
}
