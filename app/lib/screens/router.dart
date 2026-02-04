import 'dart:async';
import 'package:distributeapp/blocs/file_system_bloc.dart';
import 'package:distributeapp/blocs/playlist_bloc.dart';
import 'package:distributeapp/blocs/download_cubit.dart';
import 'package:distributeapp/core/helpers/playlist_helper.dart';
import 'package:distributeapp/blocs/search_bloc.dart';
import 'package:distributeapp/model/server_search_result.dart';
import 'package:distributeapp/repositories/folder_repository.dart';
import 'package:distributeapp/repositories/search_repository.dart';
import 'package:distributeapp/screens/library/library.dart';
import 'package:distributeapp/screens/player/music_player.dart';
import 'package:distributeapp/screens/playlist/playlist.dart';
import 'package:distributeapp/screens/request.dart';
import 'package:distributeapp/screens/search/search.dart';
import 'package:distributeapp/screens/settings/settings.dart';
import 'package:distributeapp/screens/settings/storage_settings.dart';
import 'package:distributeapp/screens/settings/server_url_settings_screen.dart';
import 'package:distributeapp/screens/settings/customization_settings.dart';
import 'package:distributeapp/core/preferences/settings_repository.dart';
import 'package:distributeapp/core/preferences/settings_cubit.dart';
import 'package:distributeapp/repositories/playlist_repository.dart';
import 'package:distributeapp/model/local_search_result.dart';
import 'package:distributeapp/core/service_locator.dart';
import 'package:distributeapp/core/services/navigation_service.dart';
import 'package:distributeapp/repositories/audio/music_player_controller.dart';
import 'package:distributeapp/core/ui/dimensions.dart';
import 'package:distributeapp/components/blurry_app_bar.dart';
import 'package:distributeapp/theme/app_icons.dart';

import 'package:distributeapp/screens/welcome/onboarding_scaffold.dart';
import 'package:distributeapp/screens/welcome/welcome_page.dart';

import 'package:distributeapp/screens/welcome/eula.dart';
import 'package:distributeapp/screens/welcome/login_page.dart';
import 'package:distributeapp/screens/welcome/signup_page.dart';

import 'package:distributeapp/repositories/auth_repository.dart';
import 'package:distributeapp/blocs/auth_cubit.dart';
import 'package:distributeapp/blocs/music/music_player_bloc.dart';
import 'package:distributeapp/blocs/sync_cubit.dart';
import 'package:distributeapp/screens/sync_status_banner.dart';
import 'package:distributeapp/screens/not_found_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_discord_rpc/flutter_discord_rpc.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  navigatorKey: sl<NavigationService>().navigatorKey,
  initialLocation: '/library',
  errorBuilder: (context, state) => NotFoundScreen(state: state),
  redirect: (context, state) {
    final settingsRepo = sl<SettingsRepository>();

    // Migration for existing users
    if (!settingsRepo.onboardingCompleted &&
        settingsRepo.serverURL.isNotEmpty) {
      settingsRepo.setOnboardingCompleted(true);
      return null;
    }

    // Check if onboarding is completed
    if (!settingsRepo.onboardingCompleted) {
      if (!state.uri.toString().startsWith('/welcome')) {
        return '/welcome';
      }
    }
    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/welcome',
      redirect: (context, state) {
        if (state.fullPath == '/welcome') {
          return '/welcome/start';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: 'start',
          pageBuilder: (context, state) => NoTransitionPage(
            child: OnboardingScaffold(
              child: WelcomePage(onNext: () => context.push('/welcome/server')),
            ),
          ),
        ),
        GoRoute(
          path: 'server',
          builder: (context, state) => ServerUrlSettingsScreen(
            onNext: () => context.push('/welcome/eula'),
            onBack: () => context.pop(),
          ),
        ),
        GoRoute(
          path: 'eula',
          builder: (context, state) => OnboardingScaffold(
            child: EulaScreen(
              isOnboarding: true,
              onAccepted: () => context.push('/welcome/login'),
              onBack: () => context.pop(),
            ),
          ),
        ),
        GoRoute(
          path: 'login',
          builder: (context, state) => OnboardingScaffold(
            child: LoginPage(
              onNext: () {
                context.read<SettingsCubit>().setOnboardingCompleted(true);
                context.go('/library');
              },
              onBack: () => context.pop(),
            ),
          ),
        ),
        GoRoute(
          path: 'signup',
          builder: (context, state) =>
              const OnboardingScaffold(child: SignupPage()),
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return BlocProvider(
          create: (context) => sl<SyncCubit>(),
          child: ScaffoldWithNavBar(navigationShell: navigationShell),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/library',
              builder: (context, state) {
                return BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final rootId = context.read<AuthRepository>().rootFolderId;
                    if (rootId == null) {
                      return const Scaffold(
                        body: Center(child: Text("Please login via settings.")),
                      );
                    } else {
                      return BlocProvider(
                        create: (context) => FileSystemBloc(
                          folderRepo: context.read<FolderRepository>(),
                          playlistRepo: context.read<PlaylistRepository>(),
                          authRepo: context.read<AuthRepository>(),
                          initialFolderId: rootId,
                        )..add(FileSystemEvent.loadFolder(rootId)),
                        child: LibraryScreen(folderId: rootId),
                      );
                    }
                  },
                );
              },
              routes: [
                GoRoute(
                  path: 'playlist/:playlistId',
                  builder: (context, state) {
                    final playlistId = state.pathParameters['playlistId'] ?? "";
                    return BlocProvider(
                      create: (context) => PlaylistBloc(
                        downloadCubit: context.read<DownloadCubit>(),
                        repo: context.read<PlaylistRepository>(),
                        playlistId: playlistId,
                      )..add(const PlaylistEvent.load()),
                      child: PlaylistScreen(playlistId: playlistId),
                    );
                  },
                ),
                GoRoute(
                  path: ':folderId',
                  builder: (context, state) {
                    final folderId = state.pathParameters['folderId'];
                    if (folderId == null) {
                      return const Scaffold(
                        body: Center(child: Text("Invalid link.")),
                      );
                    }

                    final bloc = FileSystemBloc(
                      folderRepo: context.read<FolderRepository>(),
                      playlistRepo: context.read<PlaylistRepository>(),
                      authRepo: context.read<AuthRepository>(),
                      initialFolderId: folderId,
                    )..add(FileSystemEvent.loadFolder(folderId));
                    return BlocProvider(
                      create: (context) => bloc,
                      child: LibraryScreen(folderId: folderId),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/search',
              builder: (context, state) => BlocProvider(
                create: (context) =>
                    SearchBloc(repo: context.read<SearchRepository>()),
                child: const SearchScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'eula',
                  builder: (context, state) =>
                      EulaScreen(onAccepted: () => context.pop()),
                ),
                GoRoute(
                  path: 'login',
                  builder: (context, state) => Scaffold(
                    extendBodyBehindAppBar: true,
                    appBar: BlurryAppBar(
                      center: Text(
                        "Log In",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    body: LoginPage(
                      onNext: () => context.pop(),
                      onBack: () => context.pop(),
                      canSkip: false,
                    ),
                  ),
                ),
                GoRoute(
                  path: 'signup',
                  builder: (context, state) => Scaffold(
                    extendBodyBehindAppBar: true,
                    appBar: BlurryAppBar(
                      center: Text(
                        "Sign Up",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    body: const SignupPage(),
                  ),
                ),
                GoRoute(
                  path: 'storage',
                  builder: (context, state) => const StorageSettingsScreen(),
                ),
                GoRoute(
                  path: 'server',
                  builder: (context, state) => const ServerUrlSettingsScreen(),
                ),
                GoRoute(
                  path: 'customization',
                  builder: (context, state) =>
                      const CustomizationSettingsScreen(),
                ),
                GoRoute(
                  path: 'requests',
                  builder: (context, state) => const RequestsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/picker',
      pageBuilder: (context, state) {
        final songId = state.uri.queryParameters['songId'];
        return _buildPickerPage(
          context: context,
          itemId: songId,
          onPlaylistSelected: (context, playlistId) {
            if (playlistId != null) {
              _handleSongSelection(context, state.extra, songId!, playlistId);
            }
          },
        );
      },
      routes: [
        GoRoute(
          path: ':folderId',
          pageBuilder: (context, state) {
            final songId = state.uri.queryParameters['songId'];
            final folderId = state.pathParameters['folderId'];
            return _buildPickerPage(
              context: context,
              folderId: folderId,
              itemId: songId,
              onPlaylistSelected: (context, playlistId) {
                if (playlistId != null) {
                  _handleSongSelection(
                    context,
                    state.extra,
                    songId!,
                    playlistId,
                  );
                }
              },
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/folder-picker',
      pageBuilder: (context, state) {
        final itemId =
            state.uri.queryParameters['itemId'] ??
            state.uri.queryParameters['playlistId'];
        final isFolder = state.uri.queryParameters['isFolder'] == 'true';

        return _buildPickerPage(
          context: context,
          itemId: itemId,
          onFolderSelected: (context, folderId) {
            final repo = context.read<PlaylistRepository>();
            if (isFolder) {
              repo.moveFolder(itemId!, folderId);
            } else {
              repo.movePlaylist(itemId!, folderId);
            }
            Navigator.of(
              context,
            ).popUntil((route) => route.settings.name != 'picker_flow');
          },
        );
      },
      routes: [
        GoRoute(
          path: ':folderId',
          pageBuilder: (context, state) {
            final itemId =
                state.uri.queryParameters['itemId'] ??
                state.uri.queryParameters['playlistId'];
            final isFolder = state.uri.queryParameters['isFolder'] == 'true';
            final folderId = state.pathParameters['folderId'];

            return _buildPickerPage(
              context: context,
              folderId: folderId,
              itemId: itemId,
              onFolderSelected: (context, targetFolderId) {
                final repo = context.read<PlaylistRepository>();
                if (isFolder) {
                  repo.moveFolder(itemId!, targetFolderId);
                } else {
                  repo.movePlaylist(itemId!, targetFolderId);
                }
                Navigator.of(
                  context,
                ).popUntil((route) => route.settings.name != 'picker_flow');
              },
            );
          },
        ),
      ],
    ),
  ],
);

Page<dynamic> _buildPickerPage({
  required BuildContext context,
  required String? itemId,
  String? folderId,
  void Function(BuildContext, String?)? onPlaylistSelected,
  void Function(BuildContext, String?)? onFolderSelected,
}) {
  if (itemId == null) {
    return const MaterialPage(child: Scaffold(body: Text("No ID")));
  }

  return MaterialPage(
    name: 'picker_flow',
    fullscreenDialog: true,
    child: Builder(
      builder: (context) {
        final user = context.read<AuthRepository>().loggedInUser;
        final rootId = user?.rootFolderId;
        final effectiveFolderId = folderId ?? rootId;

        if (effectiveFolderId == null) {
          return const Scaffold(body: Center(child: Text("No root folder.")));
        }
        return BlocProvider(
          create: (context) => FileSystemBloc(
            folderRepo: context.read<FolderRepository>(),
            playlistRepo: context.read<PlaylistRepository>(),
            authRepo: context.read<AuthRepository>(),
            initialFolderId: effectiveFolderId,
          )..add(FileSystemEvent.loadFolder(effectiveFolderId)),
          child: LibraryScreen(
            folderId: effectiveFolderId,
            onPlaylistSelected: onPlaylistSelected,
            onFolderSelected: onFolderSelected,
          ),
        );
      },
    ),
  );
}

void _handleSongSelection(
  BuildContext context,
  Object? song,
  String songId,
  String playlistId,
) {
  if (song is LocalSearchResult) {
    context.read<PlaylistRepository>().addSongToPlaylist(playlistId, songId);
  } else if (song is ServerSearchResultSong) {
    final playlistRepo = context.read<PlaylistRepository>();
    PlaylistHelper.addRemoteSongAndPrepareDownload(
      playlistRepo,
      playlistId,
      song,
    ).then((s) {
      if (s != null && s.fileId != null && context.mounted) {
        context.read<DownloadCubit>().downloadSong(s);
      }
    });
  }
  Navigator.of(
    context,
  ).popUntil((route) => route.settings.name != 'picker_flow');
}

class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  @override
  void initState() {
    super.initState();
    _initDiscord();
  }

  bool _shouldResetLibrary = false;

  Future<void> _initDiscord() async {
    try {
      await FlutterDiscordRPC.instance.connect();
    } catch (e) {
      debugPrint("Discord RPC connection failed: $e");
    }
  }

  @override
  void dispose() {
    try {
      FlutterDiscordRPC.instance.disconnect();
      FlutterDiscordRPC.instance.dispose();
    } catch (_) {}
    super.dispose();
  }

  final appScreens = const [LibraryScreen(), SearchScreen(), SettingsScreen()];
  final navigationDestinations = [
    NavigationDestination(icon: Icon(AppIcons.libraryMusic), label: 'Library'),
    NavigationDestination(icon: Icon(AppIcons.search), label: 'Search'),
    NavigationDestination(icon: Icon(AppIcons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        state.whenOrNull(
          authenticated: (user) {
            if (widget.navigationShell.currentIndex == 0) {
              if (mounted) context.go('/library');
            } else {
              _shouldResetLibrary = true;
            }
          },
          unauthenticated: () {
            // Handle explicit logout if needed, e.g. navigate to home or reset state
            if (widget.navigationShell.currentIndex == 0) {
              if (mounted) context.go('/library');
            } else {
              _shouldResetLibrary = true;
            }
          },
          initial: () {
            // Handle initial state if it implies logout (often synonymous with unauthenticated in this flow)
            if (widget.navigationShell.currentIndex == 0) {
              if (mounted) context.go('/library');
            } else {
              _shouldResetLibrary = true;
            }
          },
        );
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (context.canPop()) {
              context.pop();
            }
          },
        },
        child: Stack(
          children: [
            Scaffold(
              body: BlocBuilder<MusicPlayerBloc, ControllerState>(
                buildWhen: (previous, current) =>
                    previous.currentSong != current.currentSong,
                builder: (context, state) {
                  final bottomPadding = state.currentSong != null
                      ? Dimensions.kMiniPlayerHeight
                      : 0.0;

                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      padding: MediaQuery.of(context).padding.copyWith(
                        bottom:
                            MediaQuery.of(context).padding.bottom +
                            bottomPadding,
                      ),
                    ),
                    child: Stack(
                      children: [
                        widget.navigationShell,
                        const Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: SyncStatusBanner(),
                        ),
                      ],
                    ),
                  );
                },
              ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: TooltipVisibility(
                  visible: false,
                  child: NavigationBar(
                    destinations: navigationDestinations,
                    selectedIndex: widget.navigationShell.currentIndex,
                    onDestinationSelected: (int index) =>
                        _onTap(context, index),
                  ),
                ),
              ),
            ),
            const MusicPlayer(),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    var initialLocation = index == widget.navigationShell.currentIndex;
    if (index == 0 && _shouldResetLibrary) {
      initialLocation = true;
      _shouldResetLibrary = false;
    }
    widget.navigationShell.goBranch(index, initialLocation: initialLocation);
  }
}
