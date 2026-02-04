package db

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/ProjectDistribute/distributor/model"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func New() (*gorm.DB, error) {
	// Check database directory permissions
	if err := os.WriteFile("data/db/.test", []byte(""), 0644); err != nil {
		log.Printf("FATAL: Cannot write to data/db: %v\n", err)
		fmt.Println("This is likely a permission issue. If running in Docker on Linux, ensure the host directory is writable by the container user.")
		panic(err)
	}
	os.Remove("data/db/.test")

	newLogger := logger.New(
		log.New(os.Stdout, "\r\n", log.LstdFlags),
		logger.Config{
			SlowThreshold:             time.Millisecond * 100,
			LogLevel:                  logger.Error,
			IgnoreRecordNotFoundError: true,
			Colorful:                  true,
		},
	)

	return gorm.Open(sqlite.Open("data/db/distributor.db"), &gorm.Config{
		Logger: newLogger,
	})
}

// TODO: err check
func AutoMigrate(db *gorm.DB) error {
	if db == nil {
		return fmt.Errorf("db is nil")
	}
	if err := db.AutoMigrate(
		&model.Song{},
		&model.SongFile{},
		&model.RequestMail{},
		&model.Artist{},
		&model.ArtistIdentifier{},
		&model.AlbumIdentifier{},
		&model.SongIdentifier{},
		&model.Album{},
		&model.User{},
		&model.Playlist{},
		&model.PlaylistFolder{},
		&model.PlaylistSong{},
		&model.Setting{},
	); err != nil {
		return err
	}

	if err := BackfillOrdering(db); err != nil {
		log.Printf("WARNING: Backfill failed: %v\n", err)
		return err
	}
	return nil
}
