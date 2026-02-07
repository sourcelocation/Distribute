package task

import (
	"log"
	"os"

	"github.com/ProjectDistribute/distributor/model"
	"gorm.io/gorm"
)

func EnsureFilesSize(db *gorm.DB) {
	var files []model.SongFile
	if err := db.Find(&files).Error; err != nil {
		log.Printf("Error fetching files: %v", err)
		return
	}

	for _, file := range files {
		if file.Size > 0 {
			continue
		}

		path := file.FilePath()
		info, err := os.Stat(path)
		if err != nil {
			log.Printf("Error stating file %s: %v", path, err)
			continue
		}

		file.Size = info.Size()
		if err := db.Save(&file).Error; err != nil {
			log.Printf("Error updating size for file %s: %v", path, err)
			continue
		}
		log.Printf("Updated size for file %s to %d bytes", path, file.Size)
	}
}
