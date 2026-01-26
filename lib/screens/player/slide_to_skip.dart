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

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _current = widget.current;
    _next = widget.next;
    _previous = widget.previous;
    _pageController = PageController(initialPage: 1);
  }

  @override
  @override
  void didUpdateWidget(SlideToSkipMiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentSongId != oldWidget.currentSongId) {
      setState(() {
        _current = widget.current;
        _next = widget.next;
        _previous = widget.previous;
        _isNavigating = false;
      });
      if (_pageController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(1);
          }
        });
      }
    } else {
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
              if (_pageController.hasClients) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _pageController.hasClients) {
                    _pageController.jumpToPage(1);
                  }
                });
              }
              _isNavigating = false;
              return false;
            }
            if (notification is ScrollUpdateNotification) {
              if (_isNavigating) return false;
              if (notification.dragDetails != null &&
                  _pageController.hasClients) {
                final double instantDelta = notification.dragDetails!.delta.dx;
                final double page = _pageController.page ?? 1.0;

                const double sensitivity = 15.0;

                int targetPage;
                if (instantDelta < -sensitivity) {
                  targetPage = page.ceil();
                } else if (instantDelta > sensitivity) {
                  targetPage = page.floor();
                } else {
                  targetPage = page.round();
                }

                if (targetPage >= 2) {
                  _isNavigating = true;
                  widget.onSkip();
                } else if (targetPage <= 0) {
                  if (widget.onPrevious != null) {
                    _isNavigating = true;
                    widget.onPrevious!();
                  }
                }
              }
            }
            return false;
          },
          child: PageView(
            controller: _pageController,
            physics: const PageScrollPhysics(),
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
