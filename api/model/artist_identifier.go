package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ArtistIdentifier struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`

	Identifier string    `gorm:"index;not null" `
	ArtistID   uuid.UUID `gorm:"type:uuid;not null"`
	Artist     Artist
}

func (a *ArtistIdentifier) BeforeCreate(tx *gorm.DB) (err error) {
	if a.ID == uuid.Nil {
		a.ID = uuid.New()
	}
	return
}
