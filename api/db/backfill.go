package db

import (
	"fmt"
	"log"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/ProjectDistribute/distributor/utils"
	"gorm.io/gorm"
)

func BackfillOrdering(db *gorm.DB) error {
	var playlistIDs []string
	err := db.Model(&model.PlaylistSong{}).
		Where("`order` = '' OR `order` IS NULL").
		Distinct("playlist_id").
		Pluck("playlist_id", &playlistIDs).Error
	if err != nil {
		return fmt.Errorf("failed to fetch playlists for backfill: %w", err)
	}

	if len(playlistIDs) == 0 {
		return nil
	}

	log.Printf("Backfilling order for %d playlists...\n", len(playlistIDs))

	for _, pid := range playlistIDs {
		var songs []model.PlaylistSong
		err := db.Where("playlist_id = ?", pid).
			Order("created_at ASC").
			Find(&songs).Error
		if err != nil {
			log.Printf("Error fetching songs for playlist %s: %v\n", pid, err)
			continue
		}

		currentKey := ""
		for _, song := range songs {
			newKey := utils.GenerateNextKey(currentKey)

			if song.Order != newKey {
				err := db.Model(&model.PlaylistSong{}).
					Where("playlist_id = ? AND song_id = ?", song.PlaylistID, song.SongID).
					Update("order", newKey).Error

				if err != nil {
					log.Printf("Failed to update order for song %s in playlist %s: %v\n", song.SongID, song.PlaylistID, err)
				}
			}
			currentKey = newKey
		}
	}

	return nil
}
