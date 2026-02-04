package service

import (
	"errors"
	"slices"
	"strings"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/ProjectDistribute/distributor/store"
	"github.com/google/uuid"
)

type MailService struct {
	Store         *store.MailStore
	SettingsStore *store.SettingsStore
}

func NewMailService(store *store.MailStore, settingsStore *store.SettingsStore) *MailService {
	return &MailService{Store: store, SettingsStore: settingsStore}
}

func (ms *MailService) CreateRequestMail(category, message string, userID uuid.UUID) (*model.RequestMail, error) {
	categories := ms.GetCategories()

	if !slices.Contains(categories, category) {
		return nil, errors.New("invalid category")
	}

	return ms.Store.CreateRequestMail(category, message, userID)

}

func (ms *MailService) GetRequestMails() []model.RequestMail {
	return ms.Store.GetRequestMails()
}

func (ms *MailService) SetStatus(mailID uint, status int) error {
	if status < 0 || status > 3 {
		return errors.New("invalid status")
	}
	err := ms.Store.SetStatus(mailID, status)
	if err != nil {
		return err
	}
	if status == int(model.RequestMailStatusRejected) || status == int(model.RequestMailStatusCompleted) {
		return ms.Store.DeleteRequestMail(mailID)
	} else {
		return nil
	}
}

func (ms *MailService) GetNextRequestMail() (*model.RequestMail, error) {
	return ms.Store.GetNextRequestMail()
}

func (ms *MailService) GetCategories() []string {
	catStr, err := ms.SettingsStore.Get("mail_categories")
	if err != nil || catStr == "" {
		return []string{"song_only", "album", "playlist"}
	}
	return strings.Split(catStr, ",")
}
