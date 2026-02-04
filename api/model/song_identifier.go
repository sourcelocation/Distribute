package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SongIdentifier struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`

	Identifier string    `gorm:"not null"`
	SongID     uuid.UUID `gorm:"type:uuid;not null"`
	Song       Song
}

func (a *SongIdentifier) BeforeCreate(tx *gorm.DB) (err error) {
	if a.ID == uuid.Nil {
		a.ID = uuid.New()
	}
	return
}
