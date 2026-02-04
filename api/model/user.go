package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type User struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`

	Username     string     `gorm:"uniqueIndex;not null"`
	PasswordHash string     `gorm:"not null" json:"-"`
	IsAdmin      bool       `gorm:"default:false"`
	BannedUntil  *time.Time `gorm:"default:null"`
}

func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
	if u.ID == uuid.Nil {
		u.ID = uuid.New()
	}
	return
}
