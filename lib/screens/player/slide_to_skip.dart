import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SlideToSkipMiniPlayer extends StatefulWidget {
  final Widget current;
  final Widget? next;
  final Widget? previous;
  final VoidCallback onSkip;
  final VoidCallback? onPrevious;
  final VoidCallback? onTap;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;
  final String? currentSongId;

  const SlideToSkipMiniPlayer({
    super.key,
    required this.current,
    this.next,
    this.previous,
    required this.onSkip,
    this.onPrevious,
    this.onTap,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.currentSongId,
  });

  @override
  State<SlideToSkipMiniPlayer> createState() => _SlideToSkipMiniPlayerState();
}

class _SlideToSkipMiniPlayerState extends State<SlideToSkipMiniPlayer> {
  late PageController _pageController;
  late Widget _current;
  Widget? _next;
  Widget? _previous;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _current = widget.current;
    _next = widget.next;
    _previous = widget.previous;
    _pageController = PageController(initialPage: 1);
  }

  @override
  void didUpdateWidget(SlideToSkipMiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the song changed externally, update our buffered items and jump
    if (widget.currentSongId != oldWidget.currentSongId) {
      if (!_isTransitioning) {
        setState(() {
          _current = widget.current;
          _next = widget.next;
          _previous = widget.previous;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(1);
          }
        });
      }
    } else if (!_isTransitioning) {
      // Keep neighbor items updated if we aren't mid-swipe
      if (widget.next != oldWidget.next ||
          widget.previous != oldWidget.previous ||
          widget.current != oldWidget.current) {
        setState(() {
          _current = widget.current;
          _next = widget.next;
          _previous = widget.previous;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageChanged(int index) {
    if (_isTransitioning) return;

    if (index == 2 && widget.next != null) {
      _isTransitioning = true;
      widget.onSkip();
    } else if (index == 0 && widget.previous != null) {
      _isTransitioning = true;
      widget.onPrevious?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        VerticalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(),
              (VerticalDragGestureRecognizer instance) {
                instance
                  ..onUpdate = widget.onVerticalDragUpdate
                  ..onEnd = widget.onVerticalDragEnd;
              },
            ),
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(),
              (TapGestureRecognizer instance) {
                instance.onTap = widget.onTap;
              },
            ),
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification) {
              if (_isTransitioning) {
                setState(() {
                  _isTransitioning = false;
                  _current = widget.current;
                  _next = widget.next;
                  _previous = widget.previous;
                });
                _pageController.jumpToPage(1);
              }
            }
            return false;
          },
          child: PageView(
            controller: _pageController,
            onPageChanged: _handlePageChanged,
            physics: const BouncingScrollPhysics(),
            children: [
              _previous != null
                  ? Container(color: Colors.transparent, child: _previous)
                  : const SizedBox(),
              Container(color: Colors.transparent, child: _current),
              _next != null
                  ? Container(color: Colors.transparent, child: _next)
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
