package db

import (
	"testing"
	"time"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/ProjectDistribute/distributor/utils"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestMigration_PlaylistSong_Order(t *testing.T) {
	dbName := "file::memory:?cache=shared"

	type PlaylistSongV1 struct {
		PlaylistID uuid.UUID `gorm:"type:uuid;primaryKey"`
		SongID     uuid.UUID `gorm:"type:uuid;primaryKey"`
		CreatedAt  time.Time
	}

	db, err := gorm.Open(sqlite.Open(dbName), &gorm.Config{})
	assert.NoError(t, err)

	err = db.Table("playlist_songs").AutoMigrate(&PlaylistSongV1{})
	assert.NoError(t, err)

	testPlaylistID := uuid.New()
	song1ID := uuid.New()
	song2ID := uuid.New()

	v1Data1 := PlaylistSongV1{
		PlaylistID: testPlaylistID,
		SongID:     song1ID,
		CreatedAt:  time.Now().Add(-1 * time.Hour),
	}
	v1Data2 := PlaylistSongV1{
		PlaylistID: testPlaylistID,
		SongID:     song2ID,
		CreatedAt:  time.Now(),
	}

	err = db.Table("playlist_songs").Create(&v1Data1).Error
	assert.NoError(t, err)
	err = db.Table("playlist_songs").Create(&v1Data2).Error
	assert.NoError(t, err)

	err = AutoMigrate(db)
	assert.NoError(t, err)

	hasColumn := db.Migrator().HasColumn(&model.PlaylistSong{}, "Order")
	assert.True(t, hasColumn, "Order column should exist after migration")

	var result1, result2 model.PlaylistSong
	err = db.First(&result1, "playlist_id = ? AND song_id = ?", testPlaylistID, song1ID).Error
	assert.NoError(t, err)
	err = db.First(&result2, "playlist_id = ? AND song_id = ?", testPlaylistID, song2ID).Error
	assert.NoError(t, err)

	assert.Equal(t, "01", result1.Order, "First song (older) should be 01")
	assert.Equal(t, "02", result2.Order, "Second song (newer) should be 02")

	newSongID := uuid.New()
	newEntry := model.PlaylistSong{
		PlaylistID: testPlaylistID,
		SongID:     newSongID,
		Order:      utils.GenerateNextKey(result2.Order),
		CreatedAt:  time.Now(),
	}
	err = db.Create(&newEntry).Error
	assert.NoError(t, err)

	var checkNew model.PlaylistSong
	err = db.First(&checkNew, "song_id = ?", newSongID).Error
	assert.NoError(t, err)
	assert.Equal(t, "03", checkNew.Order)
}
