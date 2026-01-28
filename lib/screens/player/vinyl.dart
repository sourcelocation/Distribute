import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:distributeapp/core/preferences/vinyl_style.dart';

class VinylWidget extends StatefulWidget {
  final File coverFile;
  final Color backgroundColor;
  final Color effectColor;
  final bool isPlaying;
  final List<bool> easterEggs;
  final VinylStyle style;

  const VinylWidget({
    super.key,
    required this.coverFile,
    required this.backgroundColor,
    required this.effectColor,
    required this.isPlaying,
    required this.easterEggs,
    required this.style,
  });

  @override
  State<VinylWidget> createState() => _VinylWidgetState();
}

class _VinylWidgetState extends State<VinylWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _rotationNotifier = ValueNotifier(0.0);

  double _velocity = 0.0;
  Duration _lastElapsed = Duration.zero;

  static const double _targetSpeed = 1.0 / 8.0;
  static const double _acceleration = 0.3;
  static const double _friction = 0.2;

  static const int _cacheWidth = 2048;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    if (widget.isPlaying) {
      _velocity = _targetSpeed;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _rotationNotifier.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    final targetSpeed = widget.easterEggs[0] ? 3.0 : _targetSpeed;

    if (widget.isPlaying) {
      if (_velocity < targetSpeed) {
        _velocity += _acceleration * dt;
        if (_velocity > targetSpeed) _velocity = targetSpeed;
      }
    } else {
      if (_velocity > 0) {
        _velocity -= _friction * dt;
        if (_velocity < 0) _velocity = 0;
      }
    }

    if (_velocity > 0) {
      double newRotation = _rotationNotifier.value + (_velocity * dt);
      _rotationNotifier.value = newRotation % 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    const double coverRatio = 0.88;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        final coverSize = size * coverRatio;

        final Widget coverImage = ClipOval(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Image.file(
              widget.coverFile,
              key: ValueKey(widget.coverFile.path),
              cacheWidth: _cacheWidth,
              width: coverSize,
              height: coverSize,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
        );

        final Widget vinylBg = Image.asset(
          widget.style == VinylStyle.transparent
              ? 'assets/vinyl/vinyl-spinning-alt.png'
              : 'assets/vinyl/vinyl-spinning.png',
          cacheWidth: _cacheWidth,
          width: size,
          height: size,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        );

        final Widget vinylStatic = Image.asset(
          'assets/vinyl/vinyl-static.png',
          cacheWidth: _cacheWidth,
          width: size,
          height: size,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        );

        final Widget vinylEffect = Image.asset(
          'assets/vinyl/vinyl-effect.png',
          cacheWidth: _cacheWidth,
          width: size,
          height: size,
          fit: BoxFit.contain,
          color: widget.easterEggs[1] ? Colors.amber : widget.effectColor,
          gaplessPlayback: true,
        );

        final gradientColors = [
          widget.effectColor.withValues(alpha: 0.2),
          widget.effectColor.withValues(alpha: 0.2),
          widget.effectColor.withValues(alpha: 1.0),
          widget.effectColor.withValues(alpha: 0.2),
          widget.effectColor.withValues(alpha: 0.2),
        ];

        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: _rotationNotifier,
            builder: (context, _) {
              final double angle = _rotationNotifier.value * 2 * math.pi;

              return SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: angle,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          coverImage,
                          // Circle Blur in the middle
                          Center(
                            child: Container(
                              width: size * 0.33,
                              height: size * 0.33,
                              decoration: BoxDecoration(shape: BoxShape.circle),
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 5,
                                    sigmaY: 5,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          vinylBg,
                        ],
                      ),
                    ),

                    vinylStatic,

                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: gradientColors,
                          stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Transform.rotate(angle: angle, child: vinylEffect),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
