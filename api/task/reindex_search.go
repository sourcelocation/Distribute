package task

import (
	"log"

	"github.com/ProjectDistribute/distributor/service"
	"github.com/ProjectDistribute/distributor/store"
	"gorm.io/gorm"
)

func ReindexAll(db *gorm.DB, searchSvc *service.SearchService) {
	songStore := store.NewSongStore(db)
	artistStore := store.NewArtistStore(db)
	playlistStore := store.NewPlaylistStore(db)
	albumStore := store.NewAlbumStore(db)

	log.Println("Starting re-indexing...")

	// 0. Clear index
	if err := searchSvc.DeleteAllDocuments(); err != nil {
		log.Printf("Error clearing index: %v", err)
		return
	}

	// 1. Songs
	songs, err := songStore.GetAllSongs()
	if err == nil && len(songs) > 0 {
		if err := searchSvc.IndexSongs(songs); err != nil {
			log.Printf("Error indexing songs: %v", err)
		} else {
			log.Printf("Indexed %d songs", len(songs))
		}
	}

	// 2. Artists
	artists, err := artistStore.GetAllArtists()
	if err == nil && len(artists) > 0 {
		if err := searchSvc.IndexArtists(artists); err != nil {
			log.Printf("Error indexing artists: %v", err)
		} else {
			log.Printf("Indexed %d artists", len(artists))
		}
	}

	// 3. Playlists
	playlists, err := playlistStore.GetAllPlaylists()
	if err == nil && len(playlists) > 0 {
		if err := searchSvc.IndexPlaylists(playlists); err != nil {
			log.Printf("Error indexing playlists: %v", err)
		} else {
			log.Printf("Indexed %d playlists", len(playlists))
		}
	}

	// 4. Albums
	albums, err := albumStore.GetAllAlbums()
	if err == nil && len(albums) > 0 {
		if err := searchSvc.IndexAlbums(albums); err != nil {
			log.Printf("Error indexing albums: %v", err)
		} else {
			log.Printf("Indexed %d albums", len(albums))
		}
	}

	log.Println("Re-indexing complete.")
}
