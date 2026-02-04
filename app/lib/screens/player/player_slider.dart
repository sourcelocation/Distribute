import 'package:distributeapp/blocs/music/music_player_bloc.dart';
import 'package:distributeapp/blocs/music/position_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MusicPlayerSlider extends StatefulWidget {
  const MusicPlayerSlider({super.key, required this.primaryColor});

  final Color primaryColor;

  @override
  MusicPlayerSliderState createState() => MusicPlayerSliderState();
}

class MusicPlayerSliderState extends State<MusicPlayerSlider> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: BlocBuilder<PositionCubit, Duration>(
        buildWhen: (prev, curr) {
          if (_dragValue != null) {
            final dragSeconds = _dragValue!.toInt();
            final currSeconds = curr.inSeconds;
            if (currSeconds < dragSeconds) return false;
          }
          return prev.inSeconds != curr.inSeconds;
        },
        builder: (context, currentPosition) {
          final totalDuration = context.select(
            (MusicPlayerBloc b) => b.state.duration,
          );
          // Once the bloc position catches up, clear the local override
          if (_dragValue != null &&
              currentPosition.inSeconds >= _dragValue!.toInt()) {
            _dragValue = null;
          }
          final displayPosition =
              _dragValue ?? currentPosition.inSeconds.toDouble();
          return Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: widget.primaryColor,
                  inactiveTrackColor: widget.primaryColor.withAlpha(77),
                  trackHeight: 8.0,
                  thumbColor: Colors.transparent,
                  thumbShape: const RoundSliderThumbShape(
                    disabledThumbRadius: 0.0,
                    enabledThumbRadius: 0.0,
                    elevation: 0.0,
                    pressedElevation: 0.0,
                  ),
                  overlayColor: Colors.transparent,
                  trackShape: CustomTrackShape(),
                ),
                child: Slider(
                  min: 0.0,
                  max: totalDuration.inSeconds.toDouble(),
                  value: displayPosition,
                  onChanged: (value) {
                    setState(() {
                      _dragValue = value;
                    });
                  },
                  onChangeEnd: (value) {
                    context.read<MusicPlayerBloc>().add(
                      MusicPlayerEvent.seek(Duration(seconds: value.toInt())),
                    );
                  },
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -10),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(
                        Duration(seconds: displayPosition.toInt()),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      _formatDuration(totalDuration),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight!) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
