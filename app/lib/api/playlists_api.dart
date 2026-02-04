import 'package:dio/dio.dart';
import 'package:distributeapp/model/playlist_folder.dart';
import 'package:distributeapp/model/dto/server_song.dart';
import 'package:distributeapp/model/dto/server_folder.dart';
import 'package:distributeapp/model/dto/server_playlist.dart';
import 'package:distributeapp/model/dto/server_album.dart';
import 'package:distributeapp/model/dto/server_artist.dart';
import 'package:distributeapp/model/dto/sync_manifest.dart';
import 'package:distributeapp/repositories/auth_repository.dart';

class PlaylistsApi {
  final Dio client;
  final AuthRepository authRepo;

  PlaylistsApi({required this.client, required this.authRepo});

  Future<PlaylistFolder> getRootPlaylistFolder(String userId) async {
    try {
      final response = await client.get('/api/users/$userId/folders');
      return PlaylistFolder.fromJson(response.data);
    } catch (e) {
      throw Exception('Error parsing: $e');
    }
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final user = authRepo.loggedInUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    try {
      final response = await client.post(
        '/api/playlists/$playlistId/songs',
        data: {'song_id': songId},
      );
      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to add song: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding song to playlist: $e');
    }
  }

  Future<void> createPlaylist(
    String id,
    String name,
    String parentFolderId,
  ) async {
    final user = authRepo.loggedInUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final myUserId = user.id;
    try {
      final response = await client.post(
        '/api/users/$myUserId/playlists',
        data: {'name': name, 'id': id, 'parent_folder_id': parentFolderId},
      );
      if (response.statusCode == 201) {
        return;
      } else {
        throw Exception('Failed to create playlist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating playlist: $e');
    }
  }

  Future<void> createPlaylistFolder(
    String id,
    String name,
    String parentFolderId,
  ) async {
    final user = authRepo.loggedInUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final myUserId = user.id;
    try {
      final response = await client.post(
        '/api/users/$myUserId/folders',
        data: {'name': name, 'id': id, 'parent_folder_id': parentFolderId},
      );
      if (response.statusCode == 201) {
        return;
      } else {
        throw Exception(
          'Failed to create playlist folder: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error creating playlist folder: $e');
    }
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final user = authRepo.loggedInUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    try {
      final response = await client.put(
        '/api/playlists/$playlistId',
        data: {'name': newName},
      );
      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to rename playlist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error renaming playlist: $e');
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final user = authRepo.loggedInUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    try {
      final response = await client.delete('/api/playlists/$playlistId');
      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to delete playlist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting playlist: $e');
    }
  }

  Future<void> movePlaylist(String playlistId, String newParentFolderId) async {
    final user = authRepo.loggedInUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    try {
      final response = await client.put(
        '/api/playlists/$playlistId/move',
        data: {'parent_folder_id': newParentFolderId},
      );
      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to move playlist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error moving playlist: $e');
    }
  }

  Future<void> renameFolder(String folderId, String newName) async {
    final user = authRepo.loggedInUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final myUserId = user.id;
    try {
      final response = await client.patch(
        '/api/users/$myUserId/folders/$folderId/rename',
        data: {'name': newName},
      );
      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to rename folder: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error renaming folder: $e');
    }
  }

  Future<void> deleteFolder(String folderId) async {
    final user = authRepo.loggedInUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final myUserId = user.id;
    try {
      final response = await client.delete(
        '/api/users/$myUserId/folders/$folderId',
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to delete folder: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting folder: $e');
    }
  }

  Future<void> moveFolder(String folderId, String newParentFolderId) async {
    final user = authRepo.loggedInUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final myUserId = user.id;
    try {
      final response = await client.patch(
        '/api/users/$myUserId/folders/$folderId/move',
        data: {'parent_folder_id': newParentFolderId},
      );
      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to move folder: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error moving folder: $e');
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final user = authRepo.loggedInUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    try {
      final response = await client.delete(
        '/api/playlists/$playlistId/songs/$songId',
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to remove song: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error removing song from playlist: $e');
    }
  }

  Future<void> moveSong(
    String playlistId,
    String songId,
    String newOrder,
  ) async {
    final user = authRepo.loggedInUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    try {
      final response = await client.put(
        '/api/playlists/$playlistId/songs/$songId',
        data: {'order': newOrder},
      );
      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to move song: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error moving song in playlist: $e');
    }
  }

  Future<SyncManifest> getSyncChanges(DateTime? since) async {
    try {
      final query = {'since': since != null ? since.toIso8601String() : ""};
      final response = await client.get(
        '/api/users/me/sync',
        queryParameters: query,
      );
      return SyncManifest.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 502) {
          throw Exception('Server offline');
        }
      }
      rethrow;
    }
  }

  Future<List<ServerSong>> getSongsBatch(List<String> ids) async {
    try {
      final response = await client.post(
        '/api/songs/batch',
        data: {'ids': ids},
      );
      return (response.data as List)
          .map((e) => ServerSong.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error getting songs batch: $e');
    }
  }

  Future<List<ServerFolder>> getFoldersBatch(List<String> ids) async {
    final user = authRepo.loggedInUser;
    if (user == null) throw Exception('User not logged in');
    try {
      final response = await client.post(
        '/api/users/${user.id}/folders/batch',
        data: {'ids': ids},
      );

      return (response.data as List)
          .map((e) => ServerFolder.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error getting folders batch: $e');
    }
  }

  Future<List<ServerPlaylist>> getPlaylistsBatch(List<String> ids) async {
    final user = authRepo.loggedInUser;
    if (user == null) throw Exception('User not logged in');
    try {
      final response = await client.post(
        '/api/users/${user.id}/playlists/batch',
        data: {'ids': ids},
      );
      return (response.data as List)
          .map((e) => ServerPlaylist.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error getting playlists batch: $e');
    }
  }

  Future<List<ServerAlbum>> getAlbumsBatch(List<String> ids) async {
    try {
      final response = await client.post(
        '/api/albums/batch',
        data: {'ids': ids},
      );
      return (response.data as List)
          .map((e) => ServerAlbum.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error getting albums batch: $e');
    }
  }

  Future<List<ServerArtist>> getArtistsBatch(List<String> ids) async {
    try {
      final response = await client.post(
        '/api/artists/batch',
        data: {'ids': ids},
      );
      return (response.data as List)
          .map((e) => ServerArtist.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error getting artists batch: $e');
    }
  }
}
