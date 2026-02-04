package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Song struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`

	AlbumID     uuid.UUID `gorm:"type:uuid"`
	Album       Album
	Title       string           `gorm:"index"`
	Artists     []Artist         `gorm:"many2many:song_artists;constraint:OnDelete:CASCADE;"`
	SongFiles   []SongFile       `gorm:"constraint:OnDelete:CASCADE;"`
	Identifiers []SongIdentifier `gorm:"constraint:OnDelete:CASCADE;"`
}

func (s *Song) BeforeCreate(tx *gorm.DB) (err error) {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return
}
