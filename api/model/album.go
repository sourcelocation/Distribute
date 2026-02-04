package model

import (
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Album struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`

	Title       string
	ReleaseDate time.Time
	Songs       []Song            `gorm:"constraint:OnDelete:CASCADE;"`
	Identifiers []AlbumIdentifier `gorm:"constraint:OnDelete:CASCADE;"`
}

func (a *Album) GetArtistName() string {
	artists := make(map[string]bool)
	var names []string
	for _, song := range a.Songs {
		for _, artist := range song.Artists {
			if !artists[artist.Name] {
				artists[artist.Name] = true
				names = append(names, artist.Name)
			}
		}
	}
	return strings.Join(names, ", ")
}

func (s *Album) BeforeCreate(tx *gorm.DB) (err error) {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return
}
