package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SongFile struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`

	SongID   uuid.UUID `gorm:"type:uuid"`
	Format   string
	Duration uint
}

func (s *SongFile) BeforeCreate(tx *gorm.DB) (err error) {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return
}

func (s *SongFile) FilePath() string {
	return "storage/songs/" + s.SongID.String() + "." + s.Format
}
