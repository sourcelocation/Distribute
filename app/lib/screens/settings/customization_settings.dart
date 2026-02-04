import 'package:distributeapp/components/blurry_app_bar.dart';
import 'package:distributeapp/components/hoverable_list_tile.dart';
import 'package:distributeapp/components/settings_icon.dart';
import 'package:distributeapp/core/preferences/settings_cubit.dart';
import 'package:distributeapp/core/preferences/settings_state.dart';
import 'package:distributeapp/core/preferences/vinyl_style.dart';
import 'package:distributeapp/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomizationSettingsScreen extends StatelessWidget {
  const CustomizationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: BlurryAppBar(
        center: Text("Settings", style: theme.textTheme.titleMedium),
        automaticallyImplyLeading: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          kToolbarHeight + MediaQuery.of(context).padding.top + 12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          Card(
            child: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                return HoverableListTile(
                  leading: SettingsIcon(AppIcons.album),
                  title: const Text(
                    "Vinyl style",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: DropdownButton<VinylStyle>(
                    value: state.vinylStyle,
                    underline: const SizedBox(),
                    items: VinylStyle.values.map((style) {
                      return DropdownMenuItem(
                        value: style,
                        child: Text(style.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<SettingsCubit>().setVinylStyle(value);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Card(
            child: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                return HoverableListTile(
                  leading: SettingsIcon(AppIcons.equalizer),
                  title: const Text(
                    "Vinyl spins in background",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Switch(
                    value: state.keepVinylSpinningWhenUnfocused,
                    onChanged: (value) {
                      context
                          .read<SettingsCubit>()
                          .setKeepVinylSpinningWhenUnfocused(value);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
