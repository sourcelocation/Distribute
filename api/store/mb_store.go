package store

import (
	"context"
	"time"

	"github.com/ProjectDistribute/distributor/model"
	"gorm.io/gorm"
)

type MBStore struct {
	db *gorm.DB
}

func NewMBStore(db *gorm.DB) *MBStore {
	return &MBStore{db: db}
}

func (mb *MBStore) SearchSongsByTitle(ctx context.Context, title string, limit int) ([]model.MBRecording, error) {
	// Defensive defaults
	if limit <= 0 || limit > 100 {
		limit = 25
	}
	if ctx == nil {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
	}

	var results []model.MBRecording
	if err := mb.db. //WithContext(ctx).
				Where("name ILIKE ?", "%"+title+"%").
				Preload("ArtistCredit").
				Limit(limit).
				Find(&results).Error; err != nil {
		return nil, err
	}
	return results, nil
}

func (mb *MBStore) GetRecordingBySongID(mbSongID int, withArtistCredit bool) (*model.MBRecording, error) {
	var recording model.MBRecording
	var query = mb.db
	if withArtistCredit {
		query = query.Preload("ArtistCredit")
	}
	err := query.Where("id = ?", mbSongID).First(&recording).Error
	if err != nil {
		return nil, err
	}
	return &recording, nil
}
