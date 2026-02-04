package task

import (
	"log"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/ProjectDistribute/distributor/service"
	"gorm.io/gorm"
)

// CleanupInvalidSongFiles removes SongFile records where the actual file does not exist on disk.
func CleanupInvalidSongFiles(db *gorm.DB, songSvc service.SongService) (int64, error) {
	var files []model.SongFile
	if err := db.Find(&files).Error; err != nil {
		return 0, err
	}

	var deletedCount int64

	for _, file := range files {
		path := file.FilePath()
		if !songSvc.Storage.Exists(path) {
			log.Printf("Deleting invalid song file record: ID=%s, Path=%s (File missing)", file.ID, path)
			if err := db.Unscoped().Delete(&file).Error; err != nil {
				log.Printf("Error deleting invalid song file record %s: %v", file.ID, err)
				continue
			}
			deletedCount++
		}
	}

	if deletedCount > 0 {
		log.Printf("Cleaned up %d invalid song files", deletedCount)
	}

	return deletedCount, nil
}
