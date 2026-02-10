import 'package:distributeapp/blocs/music/music_player_bloc.dart';
import 'package:distributeapp/repositories/audio/music_player_controller.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MusicPlayerVolumeSlider extends StatelessWidget {
  const MusicPlayerVolumeSlider({super.key, required this.primaryColor});

  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: BlocSelector<MusicPlayerBloc, ControllerState, double>(
        selector: (state) => state.volume,
        builder: (context, volume) {
          return Row(
            children: [
              Icon(AppIcons.volumeOff, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: primaryColor,
                    inactiveTrackColor: primaryColor.withAlpha(77),
                    trackHeight: 6.0,
                    thumbColor: primaryColor,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6.0,
                      elevation: 0.0,
                      pressedElevation: 0.0,
                    ),
                    overlayColor: primaryColor.withAlpha(30),
                  ),
                  child: Slider(
                    min: 0.0,
                    max: 1.0,
                    value: volume,
                    onChanged: (value) {
                      context.read<MusicPlayerBloc>().add(
                        MusicPlayerEvent.setVolume(value),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(AppIcons.volumeUp, color: primaryColor, size: 18),
            ],
          );
        },
      ),
    );
  }
}
