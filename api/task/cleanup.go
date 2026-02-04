package task

import (
	"log"

	"github.com/ProjectDistribute/distributor/model"
	"gorm.io/gorm"
)

// RemoveOrphans removes:
// 1. Songs that have no SongFiles OR no Artists OR have empty/null title
// 2. Albums that have no Songs OR have empty/null title
// 3. Artists that have no Songs OR have empty/null name
// 4. Broken song_artists links (songs or artists that don't exist)
// 5. Broken playlist_songs links (playlists or songs that don't exist)
// Returns the count of deleted entities for each type.
// RemoveOrphans removes:
// 1. Songs that have no SongFiles OR no Artists OR have empty/null title
// 2. Albums that have no Songs OR have empty/null title
// 3. Artists that have no Songs OR have empty/null name
// 4. Broken song_artists links (songs or artists that don't exist)
// 5. Broken playlist_songs links (playlists or songs that don't exist)
// 6. Broken song_files (songs that don't exist)
// 7. Broken identifiers (songs, albums, or artists that don't exist)
// Returns a map of deleted entity counts.
func RemoveOrphans(db *gorm.DB) (map[string]int64, error) {
	results := make(map[string]int64)

	// 1. Delete Songs with no SongFiles OR no Artists OR empty/null title
	res := db.Unscoped().Where("(NOT EXISTS (SELECT 1 FROM song_files WHERE song_files.song_id = songs.id AND song_files.deleted_at IS NULL)) OR (NOT EXISTS (SELECT 1 FROM song_artists WHERE song_artists.song_id = songs.id)) OR title IS NULL OR title = ''").Delete(&model.Song{})
	if res.Error != nil {
		return results, res.Error
	}
	if res.RowsAffected > 0 {
		results["songs_deleted"] = res.RowsAffected
		log.Printf("Cleaned up %d orphan/invalid songs", res.RowsAffected)
	}

	// 2. Delete Albums with no Songs OR empty/null title
	res = db.Unscoped().Where("(NOT EXISTS (SELECT 1 FROM songs WHERE songs.album_id = albums.id AND songs.deleted_at IS NULL)) OR title IS NULL OR title = ''").Delete(&model.Album{})
	if res.Error != nil {
		return results, res.Error
	}
	if res.RowsAffected > 0 {
		results["albums_deleted"] = res.RowsAffected
		log.Printf("Cleaned up %d orphan/invalid albums", res.RowsAffected)
	}

	// 3. Delete Artists with no Songs OR empty/null name
	res = db.Unscoped().Where("(NOT EXISTS (SELECT 1 FROM song_artists INNER JOIN songs ON songs.id = song_artists.song_id WHERE song_artists.artist_id = artists.id AND songs.deleted_at IS NULL)) OR name IS NULL OR name = ''").Delete(&model.Artist{})
	if res.Error != nil {
		return results, res.Error
	}
	if res.RowsAffected > 0 {
		results["artists_deleted"] = res.RowsAffected
		log.Printf("Cleaned up %d orphan/invalid artists", res.RowsAffected)
	}

	// 4. Clean up broken song_artists (links to non-existent songs or artists)
	res = db.Exec("DELETE FROM song_artists WHERE NOT EXISTS (SELECT 1 FROM songs WHERE songs.id = song_artists.song_id) OR NOT EXISTS (SELECT 1 FROM artists WHERE artists.id = song_artists.artist_id)")
	if res.Error != nil {
		return results, res.Error
	}
	if res.RowsAffected > 0 {
		results["song_artists_deleted"] = res.RowsAffected
		log.Printf("Cleaned up %d broken song_artist links", res.RowsAffected)
	}

	// 5. Clean up broken playlist_songs (links to non-existent playlists or songs)
	res = db.Exec("DELETE FROM playlist_songs WHERE NOT EXISTS (SELECT 1 FROM songs WHERE songs.id = playlist_songs.song_id) OR NOT EXISTS (SELECT 1 FROM playlists WHERE playlists.id = playlist_songs.playlist_id)")
	if res.Error != nil {
		return results, res.Error
	}
	if res.RowsAffected > 0 {
		results["playlist_songs_deleted"] = res.RowsAffected
		log.Printf("Cleaned up %d broken playlist_song links", res.RowsAffected)
	}

	// 6. Clean up broken song_files (links to non-existent songs)
	res = db.Unscoped().Where("NOT EXISTS (SELECT 1 FROM songs WHERE songs.id = song_files.song_id)").Delete(&model.SongFile{})
	if res.Error != nil {
		return results, res.Error
	}
	if res.RowsAffected > 0 {
		results["song_files_deleted"] = res.RowsAffected
		log.Printf("Cleaned up %d broken song_files", res.RowsAffected)
	}

	// 7. Clean up broken identifiers
	// SongIdentifiers
	res = db.Unscoped().Where("NOT EXISTS (SELECT 1 FROM songs WHERE songs.id = song_identifiers.song_id)").Delete(&model.SongIdentifier{})
	if res.Error != nil {
		return results, res.Error
	}
	if res.RowsAffected > 0 {
		results["song_identifiers_deleted"] = res.RowsAffected
		log.Printf("Cleaned up %d broken song_identifiers", res.RowsAffected)
	}

	// AlbumIdentifiers
	res = db.Unscoped().Where("NOT EXISTS (SELECT 1 FROM albums WHERE albums.id = album_identifiers.album_id)").Delete(&model.AlbumIdentifier{})
	if res.Error != nil {
		return results, res.Error
	}
	if res.RowsAffected > 0 {
		results["album_identifiers_deleted"] = res.RowsAffected
		log.Printf("Cleaned up %d broken album_identifiers", res.RowsAffected)
	}

	// ArtistIdentifiers
	res = db.Unscoped().Where("NOT EXISTS (SELECT 1 FROM artists WHERE artists.id = artist_identifiers.artist_id)").Delete(&model.ArtistIdentifier{})
	if res.Error != nil {
		return results, res.Error
	}
	if res.RowsAffected > 0 {
		results["artist_identifiers_deleted"] = res.RowsAffected
		log.Printf("Cleaned up %d broken artist_identifiers", res.RowsAffected)
	}

	return results, nil
}
