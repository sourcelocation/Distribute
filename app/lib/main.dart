import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:distributeapp/blocs/auth_cubit.dart';
import 'package:distributeapp/blocs/download_cubit.dart';
import 'package:distributeapp/repositories/audio/app_audio_handler.dart';
import 'package:distributeapp/repositories/audio/music_player_controller.dart';
import 'package:distributeapp/blocs/music/music_player_bloc.dart';
import 'package:distributeapp/blocs/music/position_cubit.dart';
import 'package:distributeapp/blocs/requests_cubit.dart';
import 'package:distributeapp/blocs/server_status_cubit.dart';
import 'package:distributeapp/core/artwork/artwork_repository.dart';
import 'package:distributeapp/core/preferences/settings_cubit.dart';
import 'package:distributeapp/core/preferences/settings_repository.dart';
import 'package:distributeapp/core/service_locator.dart';
import 'package:distributeapp/core/services/app_links_service.dart';
import 'package:distributeapp/repositories/auth_repository.dart';
import 'package:distributeapp/repositories/folder_repository.dart';
import 'package:distributeapp/repositories/playlist_repository.dart';
import 'package:distributeapp/repositories/search_repository.dart';
import 'package:distributeapp/screens/router.dart';
import 'package:distributeapp/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:package_info_plus/package_info_plus.dart';

String version = "";
late final AppAudioHandler audioHandler;

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final packageInfo = await PackageInfo.fromPlatform();
      version = packageInfo.version;

      await initDependencies();

      audioHandler = await AudioService.init(
        builder: () => AppAudioHandler(controller: sl<MusicPlayerController>()),
        config: const AudioServiceConfig(
          androidNotificationChannelId:
              'net.sourceloc.distributeapp.channel.audio',
          androidNotificationChannelName: 'Music playback',
        ),
      );

      runApp(const DistributeApp());
    },
    (error, stack) {
      debugPrint("Global Error: $error");
      debugPrint(stack.toString());
    },
  );
}

class DistributeApp extends StatefulWidget {
  const DistributeApp({super.key});

  @override
  State<DistributeApp> createState() => _DistributeAppState();
}

class _DistributeAppState extends State<DistributeApp> {
  @override
  void initState() {
    super.initState();
    sl<AppLinksService>().init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: sl<SettingsRepository>()),
        RepositoryProvider.value(value: sl<FolderRepository>()),
        RepositoryProvider.value(value: sl<PlaylistRepository>()),
        RepositoryProvider.value(value: sl<ArtworkRepository>()),
        RepositoryProvider.value(value: sl<SearchRepository>()),
        RepositoryProvider.value(value: sl<AuthRepository>()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: sl<SettingsCubit>()),
          BlocProvider(create: (_) => sl<AuthCubit>()),
          BlocProvider(
            create: (_) {
              final cubit = sl<ServerStatusCubit>();
              if (sl<SettingsRepository>().onboardingCompleted) {
                cubit.loadStatus();
              }
              return cubit;
            },
          ),
          BlocProvider(create: (_) => sl<RequestsCubit>()),
          BlocProvider(create: (_) => sl<MusicPlayerBloc>()),
          BlocProvider(create: (_) => sl<PositionCubit>()),
          BlocProvider(create: (_) => sl<DownloadCubit>()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          title: 'Distribute',
          theme: createLightTheme(),
          darkTheme: createDarkTheme(),
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
          themeAnimationCurve: Curves.easeInOutCirc,
          themeAnimationStyle: AnimationStyle.noAnimation,
        ),
      ),
    );
  }
}
