import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class VinylWidget extends StatefulWidget {
  final File coverFile;
  final Color backgroundColor;
  final Color effectColor;
  final bool isPlaying;
  final List<bool> easterEggs;

  const VinylWidget({
    super.key,
    required this.coverFile,
    required this.backgroundColor,
    required this.effectColor,
    required this.isPlaying,
    required this.easterEggs,
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

  late ImageProvider _resizedCoverProvider;
  late ImageProvider _resizedBgProvider;
  late ImageProvider _resizedStaticProvider;
  late ImageProvider _resizedEffectProvider;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    if (widget.isPlaying) {
      _velocity = _targetSpeed;
    }
    _initializeResources();
  }

  @override
  void didUpdateWidget(VinylWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coverFile.path != oldWidget.coverFile.path ||
        widget.effectColor != oldWidget.effectColor) {
      _initializeResources();
    }
  }

  void _initializeResources() {
    const int cacheWidth = 2048;

    _resizedCoverProvider = ResizeImage(
      FileImage(widget.coverFile),
      width: cacheWidth,
    );

    _resizedBgProvider = ResizeImage(
      const AssetImage('assets/vinyl/vinyl-spinning.png'),
      width: cacheWidth,
    );

    _resizedStaticProvider = ResizeImage(
      const AssetImage('assets/vinyl/vinyl-static.png'),
      width: cacheWidth,
    );

    _resizedEffectProvider = ResizeImage(
      const AssetImage('assets/vinyl/vinyl-effect.png'),
      width: cacheWidth,
    );
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
          child: Image(
            image: _resizedCoverProvider,
            width: coverSize,
            height: coverSize,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        );

        final Widget vinylBg = Image(
          image: _resizedBgProvider,
          width: size,
          height: size,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        );

        final Widget vinylStatic = Image(
          image: _resizedStaticProvider,
          width: size,
          height: size,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        );

        final Widget vinylEffect = Image(
          image: _resizedEffectProvider,
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
                        children: [coverImage, vinylBg],
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
