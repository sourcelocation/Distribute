package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Artist struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`

	Name        string
	Identifiers []ArtistIdentifier `gorm:"constraint:OnDelete:CASCADE;"`
}

func (s *Artist) BeforeCreate(tx *gorm.DB) (err error) {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return
}
