package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AlbumIdentifier struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`

	Identifier string    `gorm:"not null"`
	AlbumID    uuid.UUID `gorm:"type:uuid;not null"`
	Album      Album
}

func (a *AlbumIdentifier) BeforeCreate(tx *gorm.DB) (err error) {
	if a.ID == uuid.Nil {
		a.ID = uuid.New()
	}
	return
}
