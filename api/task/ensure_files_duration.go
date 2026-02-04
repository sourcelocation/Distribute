package task

import (
	"log"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/ProjectDistribute/distributor/service"
	"gorm.io/gorm"
)

func EnsureFilesDuration(db *gorm.DB, songSvc service.SongService) {
	var files []model.SongFile
	if err := db.Find(&files).Error; err != nil {
		log.Printf("Error fetching files: %v", err)
		return
	}
	for _, file := range files {
		if file.Duration > 0 {
			continue
		}

		duration, err := songSvc.ProbeDuration(file.FilePath())
		if err != nil {
			log.Printf("Error probing duration for file %s: %v", file.FilePath(), err)
			continue
		}

		file.Duration = uint(duration * 1000)
		if err := db.Save(&file).Error; err != nil {
			log.Printf("Error updating duration for file %s: %v", file.FilePath(), err)
			continue
		}
		log.Printf("Updated duration for file %s to %d milliseconds", file.FilePath(), file.Duration)
	}
}
