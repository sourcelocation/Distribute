package model

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type RequestMailStatus int

const (
	RequestMailStatusPending    RequestMailStatus = iota // 0
	RequestMailStatusProcessing                          // 1
	RequestMailStatusCompleted                           // 2
	RequestMailStatusRejected                            // 3
)

type RequestMail struct {
	gorm.Model
	Category string
	Message  string
	UserID   uuid.UUID
	Status   RequestMailStatus
}
