import 'dart:io';
import 'dart:math' as math;
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:distributeapp/core/preferences/vinyl_style.dart';

class VinylWidget extends StatefulWidget {
  final File coverFile;
  final Color backgroundColor;
  final Color effectColor;
  final bool isPlaying;
  final List<bool> easterEggs;
  final bool isWindowFocused;
  final bool keepSpinningWhenUnfocused;
  final VinylStyle style;

  const VinylWidget({
    super.key,
    required this.coverFile,
    required this.backgroundColor,
    required this.effectColor,
    required this.isPlaying,
    required this.easterEggs,
    required this.isWindowFocused,
    required this.keepSpinningWhenUnfocused,
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
  static const double _coverRatio = 0.88;

  ui.FragmentShader? _vinylEffectFragmentShader;
  bool _shaderReady = false;
  ui.Image? _vinylScratchImage;
  ui.Image? _vinylSpinningImage;
  ui.Image? _vinylStaticImage;
  ui.Image? _coverImage;
  ImageStream? _coverStream;
  ImageStreamListener? _coverListener;
  int? _coverCacheDimension;
  int? _lastCacheDimension;
  String? _coverFilePath;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.isPlaying) {
      _velocity = _targetSpeed;
      _startTicker();
    }
    _loadShaderResources();
    _loadVinylAssets();
  }

  @override
  void didUpdateWidget(covariant VinylWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_ticker.isActive) {
      _startTicker();
    }
    if (oldWidget.coverFile.path != widget.coverFile.path) {
      _coverImage = null;
      _coverCacheDimension = null;
      _coverFilePath = null;
      _disposeCoverStream();
      if (_lastCacheDimension != null) {
        _resolveCoverImage(_lastCacheDimension!);
      }
    }
    if (oldWidget.style != widget.style) {
      _loadVinylAssets();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _rotationNotifier.dispose();
    _vinylEffectFragmentShader?.dispose();
    _vinylScratchImage?.dispose();
    _vinylSpinningImage?.dispose();
    _vinylStaticImage?.dispose();
    _disposeCoverStream();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    final targetSpeed = widget.easterEggs[0] ? 3.0 : _targetSpeed;
    final shouldSpin = widget.isPlaying &&
        (widget.isWindowFocused || widget.keepSpinningWhenUnfocused);

    if (shouldSpin) {
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
    } else {
      _stopTickerIfIdle();
    }
  }

  void _startTicker() {
    if (_ticker.isActive) return;
    _lastElapsed = Duration.zero;
    _ticker.start();
  }

  void _stopTickerIfIdle() {
    if (_ticker.isActive && !widget.isPlaying && _velocity <= 0) {
      _ticker.stop();
      _lastElapsed = Duration.zero;
    }
  }

  void _disposeCoverStream() {
    if (_coverStream != null && _coverListener != null) {
      _coverStream!.removeListener(_coverListener!);
    }
    _coverStream = null;
    _coverListener = null;
  }

  void _resolveCoverImage(int cacheDimension) {
    final String path = widget.coverFile.path;
    if (_coverCacheDimension == cacheDimension &&
        _coverFilePath == path &&
        _coverImage != null) {
      return;
    }

    _coverCacheDimension = cacheDimension;
    _coverFilePath = path;
    _coverImage = null;
    _disposeCoverStream();

    final ImageProvider provider = ResizeImage(
      FileImage(widget.coverFile),
      width: cacheDimension,
      height: cacheDimension,
    );
    final ImageStream stream = provider.resolve(const ImageConfiguration());
    _coverStream = stream;
    _coverListener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (!mounted) {
          return;
        }
        setState(() {
          _coverImage = info.image;
        });
      },
      onError: (Object error, StackTrace? stackTrace) {
        debugPrint('Failed to load vinyl cover image: $error');
      },
    );
    stream.addListener(_coverListener!);
  }

  Future<void> _loadShaderResources() async {
    try {
      final ui.FragmentProgram program = await ui.FragmentProgram.fromAsset(
        'shaders/vinyl_effect.frag',
      );
      final ui.FragmentShader fragmentShader = program.fragmentShader();
      if (!mounted) {
        fragmentShader.dispose();
        return;
      }

      setState(() {
        _vinylEffectFragmentShader = fragmentShader;
        _shaderReady = true;
      });
    } catch (error, stack) {
      debugPrint('Failed to load vinyl shader: $error\n$stack');
    }
  }

  Future<ui.Image> _loadAssetImage(String assetPath) async {
    final ByteData bytes = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(),
    );
    final ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _loadVinylAssets() async {
    try {
      final String spinningPath = widget.style == VinylStyle.transparent
          ? 'assets/vinyl/vinyl-spinning-alt.png'
          : 'assets/vinyl/vinyl-spinning.png';

      final results = await Future.wait([
        _loadAssetImage('assets/vinyl/vinyl-effect.png'),
        _loadAssetImage(spinningPath),
        _loadAssetImage('assets/vinyl/vinyl-static.png'),
      ]);

      if (!mounted) {
        for (final image in results) {
          image.dispose();
        }
        return;
      }

      setState(() {
        _vinylScratchImage?.dispose();
        _vinylSpinningImage?.dispose();
        _vinylStaticImage?.dispose();
        _vinylScratchImage = results[0];
        _vinylSpinningImage = results[1];
        _vinylStaticImage = results[2];
      });
    } catch (error, stack) {
      debugPrint('Failed to load vinyl assets: $error\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest.shortestSide;
          final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
          final cacheDimension = _resolveCacheDimension(size, devicePixelRatio);
          _lastCacheDimension = cacheDimension;
          _resolveCoverImage(cacheDimension);

          final Color effectTint = widget.easterEggs[1]
              ? Colors.amber
              : widget.effectColor;

          final bool shaderLayerReady =
              _shaderReady &&
              _vinylEffectFragmentShader != null &&
              _vinylScratchImage != null &&
              _vinylSpinningImage != null &&
              _vinylStaticImage != null &&
              _coverImage != null;

          final Widget vinyl = shaderLayerReady
              ? SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: _VinylShaderPainter(
                      rotation: _rotationNotifier,
                      shader: _vinylEffectFragmentShader!,
                      coverImage: _coverImage!,
                      spinningImage: _vinylSpinningImage!,
                      staticImage: _vinylStaticImage!,
                      scratchImage: _vinylScratchImage!,
                      effectColor: effectTint,
                      baseColor: widget.backgroundColor,
                      coverRadius: _coverRatio / 1.0,
                      style: widget.style,
                      coverScale: 1.00,
                    ),
                  ),
                )
              : Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.backgroundColor,
                  ),
                );

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: RepaintBoundary(
              child: ClipRect(
                child: SizedBox(width: size, height: size, child: vinyl),
              ),
            ),
          );
        },
      ),
    );
  }

  int _resolveCacheDimension(double size, double devicePixelRatio) {
    final int requested = math.max(1, (size * devicePixelRatio).ceil());
    return math.min(_cacheWidth, requested);
  }
}

class _VinylShaderPainter extends CustomPainter {
  _VinylShaderPainter({
    required this.rotation,
    required this.shader,
    required this.coverImage,
    required this.spinningImage,
    required this.staticImage,
    required this.scratchImage,
    required this.effectColor,
    required this.baseColor,
    required this.coverRadius,
    required this.style,
    required this.coverScale,
  }) : super(repaint: rotation);

  final ValueListenable<double> rotation;
  final ui.FragmentShader shader;
  final ui.Image coverImage;
  final ui.Image spinningImage;
  final ui.Image staticImage;
  final ui.Image scratchImage;
  final Color effectColor;
  final Color baseColor;
  final double coverRadius;
  final VinylStyle style;
  final double coverScale;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final double angle = -rotation.value * 2 * math.pi;
    final double effectAlpha = effectColor.a;
    final double baseAlpha = baseColor.a;

    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, angle)
      ..setFloat(3, effectColor.r * effectAlpha)
      ..setFloat(4, effectColor.g * effectAlpha)
      ..setFloat(5, effectColor.b * effectAlpha)
      ..setFloat(6, effectAlpha)
      ..setFloat(7, baseColor.r * baseAlpha)
      ..setFloat(8, baseColor.g * baseAlpha)
      ..setFloat(9, baseColor.b * baseAlpha)
      ..setFloat(10, baseAlpha)
      ..setFloat(11, coverRadius)
      ..setFloat(12, style == VinylStyle.transparent ? 1.0 : 0.0)
      ..setFloat(13, coverScale);
    shader.setImageSampler(0, coverImage);
    shader.setImageSampler(1, spinningImage);
    shader.setImageSampler(2, staticImage);
    shader.setImageSampler(3, scratchImage);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _VinylShaderPainter oldDelegate) {
    return oldDelegate.shader != shader ||
        oldDelegate.effectColor != effectColor ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.coverRadius != coverRadius ||
        oldDelegate.style != style ||
        oldDelegate.coverImage != coverImage ||
        oldDelegate.spinningImage != spinningImage ||
        oldDelegate.staticImage != staticImage ||
        oldDelegate.scratchImage != scratchImage ||
        oldDelegate.rotation != rotation;
  }
}
