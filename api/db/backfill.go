package db

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/ProjectDistribute/distributor/utils"
	"github.com/google/uuid"
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

func BackfillSongFilePaths(db *gorm.DB) error {
	const batchSize = 200
	var lastCreatedAt time.Time
	var lastID uuid.UUID
	for {
		var files []model.SongFile
		query := db
		if !lastCreatedAt.IsZero() || lastID != uuid.Nil {
			query = query.Where(
				"(created_at > ?) OR (created_at = ? AND id > ?)",
				lastCreatedAt,
				lastCreatedAt,
				lastID,
			)
		}
		if err := query.Order("created_at asc, id asc").Limit(batchSize).Find(&files).Error; err != nil {
			return fmt.Errorf("failed to fetch song files: %w", err)
		}
		if len(files) == 0 {
			return nil
		}

		for _, file := range files {
			if file.ID == uuid.Nil {
				file.ID = uuid.New()
				if err := db.Save(&file).Error; err != nil {
					log.Printf("Failed to assign ID to song file (song %s): %v\n", file.SongID, err)
					continue
				}
			}

			newPath := file.FilePath()
			if fileExists(newPath) {
				lastCreatedAt = file.CreatedAt
				lastID = file.ID
				continue
			}

			oldPath := file.LegacyFilePath()
			if !fileExists(oldPath) {
				lastCreatedAt = file.CreatedAt
				lastID = file.ID
				continue
			}

			if err := os.MkdirAll(filepath.Dir(newPath), 0o755); err != nil {
				log.Printf("Failed to create song storage dir: %v\n", err)
				lastCreatedAt = file.CreatedAt
				lastID = file.ID
				continue
			}

			if err := os.Rename(oldPath, newPath); err != nil {
				log.Printf("Failed to move song file from %s to %s: %v\n", oldPath, newPath, err)
			}
			lastCreatedAt = file.CreatedAt
			lastID = file.ID
		}
	}
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}
