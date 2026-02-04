import 'package:distributeapp/model/song.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:distributeapp/components/hoverable_icon_button.dart';

class MiniPlayerContent extends StatelessWidget {
  final Song? currentSong;
  final bool isPlaying;
  final VoidCallback onPlayPressed;
  final Color borderColor;

  const MiniPlayerContent({
    super.key,
    required this.currentSong,
    required this.isPlaying,
    required this.onPlayPressed,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    type: MaterialType.transparency,
                    child: Text(
                      currentSong?.title ?? 'Unknown Title',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Material(
                    type: MaterialType.transparency,
                    child: Text(
                      currentSong?.artist ?? 'Unknown Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            HoverableIconButton(
              onPressed: onPlayPressed,
              icon: Icon(
                isPlaying ? AppIcons.pause : AppIcons.play,
                color: Colors.white,
                size: 32,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
