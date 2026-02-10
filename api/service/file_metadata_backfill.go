package service

import (
	"log"
	"os"
	"time"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

func EnsureFilesDuration(db *gorm.DB, songSvc SongService) {
	const batchSize = 200
	var lastCreatedAt time.Time
	var lastID uuid.UUID
	for {
		var files []model.SongFile
		query := db.Where("duration = 0")
		if !lastCreatedAt.IsZero() || lastID != uuid.Nil {
			query = query.Where(
				"(created_at > ?) OR (created_at = ? AND id > ?)",
				lastCreatedAt,
				lastCreatedAt,
				lastID,
			)
		}
		if err := query.Order("created_at asc, id asc").Limit(batchSize).Find(&files).Error; err != nil {
			log.Printf("Error fetching files: %v", err)
			return
		}
		if len(files) == 0 {
			return
		}

		for _, file := range files {
			duration, err := songSvc.ProbeDuration(file.FilePath())
			if err != nil {
				log.Printf("Error probing duration for file %s: %v", file.FilePath(), err)
				continue
			}

			file.Duration = uint(duration * 1000)
			if file.Size > 0 {
				file.Bitrate = songSvc.ComputeBitrateKbps(file.Size, file.Duration)
			}
			if err := db.Save(&file).Error; err != nil {
				log.Printf("Error updating duration for file %s: %v", file.FilePath(), err)
				continue
			}
			log.Printf("Updated duration for file %s to %d milliseconds", file.FilePath(), file.Duration)
			lastCreatedAt = file.CreatedAt
			lastID = file.ID
		}
	}
}

func EnsureFilesSize(db *gorm.DB) {
	const batchSize = 200
	var lastCreatedAt time.Time
	var lastID uuid.UUID
	for {
		var files []model.SongFile
		query := db.Where("size = 0")
		if !lastCreatedAt.IsZero() || lastID != uuid.Nil {
			query = query.Where(
				"(created_at > ?) OR (created_at = ? AND id > ?)",
				lastCreatedAt,
				lastCreatedAt,
				lastID,
			)
		}
		if err := query.Order("created_at asc, id asc").Limit(batchSize).Find(&files).Error; err != nil {
			log.Printf("Error fetching files: %v", err)
			return
		}
		if len(files) == 0 {
			return
		}

		for _, file := range files {
			path := file.FilePath()
			info, err := os.Stat(path)
			if err != nil {
				log.Printf("Error stating file %s: %v", path, err)
				continue
			}

			file.Size = info.Size()
			if file.Duration > 0 {
				file.Bitrate = int(float64(file.Size*8) / 1000.0 / (float64(file.Duration) / 1000.0))
			}
			if err := db.Save(&file).Error; err != nil {
				log.Printf("Error updating size for file %s: %v", path, err)
				continue
			}
			log.Printf("Updated size for file %s to %d bytes", path, file.Size)
			lastCreatedAt = file.CreatedAt
			lastID = file.ID
		}
	}
}
