package store

import (
	"github.com/ProjectDistribute/distributor/model"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type UserStore struct {
	db *gorm.DB
}

func NewUserStore(db *gorm.DB) *UserStore {
	return &UserStore{db: db}
}

func (us *UserStore) CreateUser(user *model.User) error {
	if err := us.db.Create(user).Error; err != nil {
		return err
	}
	return nil
}

func (us *UserStore) PromoteUserToAdmin(user *model.User) error {
	user.IsAdmin = true
	return us.db.Save(user).Error
}

func (us *UserStore) GetUserByID(uuid uuid.UUID) (*model.User, error) {
	var user model.User
	if err := us.db.First(&user, "id = ?", uuid).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

func (us *UserStore) GetUserByUsername(username string) (*model.User, error) {
	var user model.User
	if err := us.db.First(&user, "username = ?", username).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

func (us *UserStore) DeleteUser(user *model.User) error {
	return us.db.Delete(user).Error
}

func (us *UserStore) UpdateUser(user *model.User) (*model.User, error) {
	if err := us.db.Save(user).Error; err != nil {
		return nil, err
	}
	return user, nil
}

func (us *UserStore) SetAdminStatus(user *model.User, isAdmin bool) error {
	user.IsAdmin = isAdmin
	return us.db.Save(user).Error
}
