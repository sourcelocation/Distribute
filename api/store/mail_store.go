package store

import (
	"github.com/ProjectDistribute/distributor/model"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type MailStore struct {
	db *gorm.DB
}

func NewMailStore(db *gorm.DB) *MailStore {
	return &MailStore{db: db}
}

func (ms *MailStore) CreateRequestMail(category, message string, userID uuid.UUID) (*model.RequestMail, error) {
	mail := &model.RequestMail{
		Category: category,
		Message:  message,
		UserID:   userID,
		Status:   model.RequestMailStatusPending,
	}
	if err := ms.db.Create(mail).Error; err != nil {
		return nil, err
	}
	return mail, nil
}

func (ms *MailStore) SetStatus(mailID uint, status int) error {
	return ms.db. //WithContext(ctx).
			Model(&model.RequestMail{}).Where("id = ?", mailID).
			Update("status", status).
			Error
}

func (ms *MailStore) DeleteRequestMail(mailID uint) error {
	return ms.db.Delete(&model.RequestMail{}, mailID).Error
}

func (ms *MailStore) GetRequestMails() []model.RequestMail {
	var mails []model.RequestMail
	if err := ms.db.Find(&mails).Error; err != nil {
		return []model.RequestMail{}
	}
	return mails
}

func (ms *MailStore) GetNextRequestMail() (*model.RequestMail, error) {
	var mail model.RequestMail

	result := ms.db.
		Order("created_at asc").
		Where("status = ?", model.RequestMailStatusPending).
		Limit(1).
		Find(&mail)

	if result.Error != nil {
		return nil, result.Error
	}

	if result.RowsAffected == 0 {
		return nil, nil
	}

	return &mail, nil
}
