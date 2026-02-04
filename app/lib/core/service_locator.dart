import 'dart:io';
import 'package:dio/dio.dart';
import 'package:distributeapp/api/search_api.dart';
import 'package:distributeapp/blocs/download_cubit.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:variable_blur/variable_blur.dart';
import 'package:flutter_discord_rpc/flutter_discord_rpc.dart';

import 'package:distributeapp/api/auth_api.dart';
import 'package:distributeapp/api/requests_api.dart';
import 'package:distributeapp/api/status_api.dart';
import 'package:distributeapp/api/songs_api.dart';
import 'package:distributeapp/api/playlists_api.dart';
import 'package:distributeapp/api/download_api.dart';
import 'package:distributeapp/blocs/auth_cubit.dart';
import 'package:distributeapp/blocs/requests_cubit.dart';
import 'package:distributeapp/blocs/server_status_cubit.dart';
import 'package:distributeapp/repositories/audio/music_player_controller.dart';
import 'package:distributeapp/blocs/music/music_player_bloc.dart';
import 'package:distributeapp/blocs/music/position_cubit.dart';
import 'package:distributeapp/core/database/database.dart';
import 'package:distributeapp/core/sync_manager.dart';
import 'package:distributeapp/core/preferences/settings_repository.dart';
import 'package:distributeapp/core/preferences/settings_cubit.dart';
import 'package:distributeapp/blocs/sync_cubit.dart';
import 'package:distributeapp/core/artwork/artwork_repository.dart';
import 'package:distributeapp/core/services/navigation_service.dart';
import 'package:distributeapp/core/services/app_links_service.dart';
import 'package:distributeapp/repositories/auth_repository.dart';
import 'package:distributeapp/repositories/folder_repository.dart';
import 'package:distributeapp/repositories/download/song_download_service.dart';
import 'package:distributeapp/repositories/playlist_repository.dart';
import 'package:distributeapp/repositories/search_repository.dart';
import 'package:distributeapp/repositories/storage_repository.dart';
import 'package:distributeapp/blocs/storage/storage_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final results = await Future.wait([
    getApplicationDocumentsDirectory(),
    SharedPreferences.getInstance(),
    VariableBlur.precacheShaders(),
    FlutterDiscordRPC.initialize("1439666298807255184"),
  ]);

  final appDocDir = results[0] as Directory;
  final prefs = results[1] as SharedPreferences;
  final appDataPath = '${appDocDir.path}/Distribute';

  await Directory(appDataPath).create(recursive: true);

  // Core Registration
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerSingleton<AppDatabase>(AppDatabase());
  sl.registerSingleton<Dio>(Dio());
  // early because baseurl is needed
  sl.registerSingleton<SettingsRepository>(
    SettingsRepository(sl(), appDataPath),
  );

  final dio = sl<Dio>();
  final settingsRepo = sl<SettingsRepository>();

  try {
    dio.options.baseUrl = settingsRepo.serverURL;
  } catch (e) {
    debugPrint('Failed to set base URL: $e');
  }

  // We need to resolve AuthRepository lazily inside the interceptor to avoid circular deps during init
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.baseUrl = sl<SettingsRepository>().serverURL;
        // Check if registered to prevent errors during very early requests
        if (sl.isRegistered<AuthRepository>()) {
          final authRepo = sl<AuthRepository>();
          if (authRepo.isLoggedIn) {
            options.headers['Authorization'] =
                'Bearer ${authRepo.loggedInUser!.token}';
          }
        }
        return handler.next(options);
      },
    ),
  );

  sl.registerLazySingleton(() => AuthAPI(sl()));
  sl.registerLazySingleton(() => ServerStatusApi(sl()));
  sl.registerLazySingleton(() => RequestsApi(client: sl()));
  sl.registerLazySingleton(() => AuthRepository(api: sl(), prefs: sl()));
  sl.registerLazySingleton(() => SearchApi(sl()));
  sl.registerLazySingleton(() => SongsApi(sl()));
  sl.registerLazySingleton(() => PlaylistsApi(client: sl(), authRepo: sl()));
  sl.registerLazySingleton(() => DownloadApi(client: sl(), settings: sl()));

  final syncManager = SyncManager(
    sl<AuthRepository>(),
    sl<AppDatabase>().syncDao,
    sl<PlaylistsApi>(),
  );
  syncManager.initialize();
  sl.registerSingleton<SyncManager>(syncManager);

  sl.registerLazySingleton(
    () => FolderRepository(sl<AppDatabase>().foldersDao),
  );
  sl.registerLazySingleton(
    () => PlaylistRepository(sl<AppDatabase>().playlistsDao, sl<SongsApi>()),
  );
  sl.registerLazySingleton(
    () => SearchRepository(sl<AppDatabase>().searchDao, sl<SearchApi>()),
  );
  sl.registerLazySingleton(() => ArtworkRepository(sl(), settings: sl()));
  sl.registerLazySingleton(
    () => SongDownloadService(
      sl<DownloadApi>(),
      sl<ArtworkRepository>(),
      sl<PlaylistRepository>(),
    ),
  );

  final musicController = MusicPlayerController(
    artworkRepository: sl<ArtworkRepository>(),
    settingsRepository: sl<SettingsRepository>(),
    playlistRepository: sl<PlaylistRepository>(),
    downloadApi: sl<DownloadApi>(),
  );
  await musicController.init();

  sl.registerSingleton<MusicPlayerController>(musicController);

  // Services
  sl.registerLazySingleton(() => NavigationService());
  sl.registerLazySingleton(
    () => AppLinksService(navigationService: sl(), settingsCubit: sl()),
  );

  sl.registerLazySingleton(() => SettingsCubit(sl()));
  sl.registerFactory(() => AuthCubit(sl(), sl(), sl())..checkAuthStatus());
  sl.registerFactory(() => ServerStatusCubit(sl()));
  sl.registerFactory(() => RequestsCubit(sl()));
  sl.registerFactory(() => MusicPlayerBloc(controller: sl()));
  sl.registerFactory(() => PositionCubit(controller: sl(), musicCubit: sl()));
  sl.registerFactory(
    () => DownloadCubit(
      sl<SongDownloadService>(),
      sl<PlaylistRepository>(),
    ),
  );
  sl.registerFactory(() => SyncCubit(sl()));

  sl.registerLazySingleton(() => StorageRepository());
  sl.registerFactory(
    () => StorageCubit(
      storageRepository: sl(),
      settingsCubit: sl(),
      artworkRepository: sl(),
      musicPlayerController: sl(),
    ),
  );
}
