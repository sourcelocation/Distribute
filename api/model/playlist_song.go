package model

import (
	"time"

	"github.com/google/uuid"
)

type PlaylistSong struct {
	PlaylistID uuid.UUID `gorm:"type:uuid;primaryKey"`
	SongID     uuid.UUID `gorm:"type:uuid;primaryKey"`

	// Order is a fractional index string for sorting
	Order string `gorm:"type:text;not null;default:''"`

	CreatedAt time.Time

	// Associations
	Playlist Playlist `gorm:"foreignKey:PlaylistID"`
	Song     Song     `gorm:"foreignKey:SongID"`
}
