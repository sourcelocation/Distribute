package store

import (
	"github.com/ProjectDistribute/distributor/model"
	"gorm.io/gorm"
)

type SettingsStore struct {
	db *gorm.DB
}

func NewSettingsStore(db *gorm.DB) *SettingsStore {
	return &SettingsStore{db: db}
}

func (s *SettingsStore) Get(key string) (string, error) {
	var setting model.Setting
	if err := s.db.First(&setting, "key = ?", key).Error; err != nil {
		return "", err
	}
	return setting.Value, nil
}

func (s *SettingsStore) Set(key, value string) error {
	setting := model.Setting{Key: key, Value: value}
	return s.db.Save(&setting).Error
}

func (s *SettingsStore) GetAll() (map[string]string, error) {
	var settings []model.Setting
	if err := s.db.Find(&settings).Error; err != nil {
		return nil, err
	}

	result := make(map[string]string)
	for _, setting := range settings {
		result[setting.Key] = setting.Value
	}
	return result, nil
}

func (s *SettingsStore) IsSetupComplete() bool {
	val, err := s.Get("setup_complete")
	return err == nil && val == "true"
}
