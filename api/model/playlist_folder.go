package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type PlaylistFolder struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`

	Name      string
	UserID    uuid.UUID  `gorm:"type:uuid;not null;index"`
	User      User       `gorm:"foreignKey:UserID"`
	ParentID  *uuid.UUID `gorm:"type:uuid;index"`
	Parent    *PlaylistFolder
	Children  []*PlaylistFolder `gorm:"foreignKey:ParentID"`
	Playlists []Playlist        `gorm:"foreignKey:FolderID;constraint:OnDelete:CASCADE;"`
}
