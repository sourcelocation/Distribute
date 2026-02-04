package service

import (
	"time"

	"github.com/ProjectDistribute/distributor/middleware"
	"github.com/ProjectDistribute/distributor/model"
	"github.com/ProjectDistribute/distributor/store"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type UserService struct {
	Store           *store.UserStore
	PlaylistService *PlaylistService
	JWTSecret       string
}

func (s *UserService) CreateUser(username, password string) (*model.User, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	user := &model.User{
		Username:     username,
		PasswordHash: string(hash),
	}
	err = s.Store.CreateUser(user)
	if err != nil {
		return nil, err
	}

	_, err = s.PlaylistService.CreatePlaylistFolder(uuid.New(), user.ID, "Root", nil)
	if err != nil {
		return nil, err
	}

	return user, nil
}

func (s *UserService) DeleteUser(user *model.User) error {
	return s.Store.DeleteUser(user)
}

func (s *UserService) GetUserByUsername(username string) (*model.User, error) {
	return s.Store.GetUserByUsername(username)
}

func (s *UserService) CheckPassword(user *model.User, password string) error {
	return bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password))
}

func (s *UserService) UpdatePassword(user *model.User, newPassword string) error {
	hash, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	user.PasswordHash = string(hash)
	_, err = s.Store.UpdateUser(user)
	return err
}

func (s *UserService) GenerateToken(user *model.User) (string, error) {
	claims := &middleware.JwtCustomClaims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   user.ID.String(),
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour * 24 * 30)),
		},
		Admin: user.IsAdmin,
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	t, err := token.SignedString([]byte(s.JWTSecret))
	return t, err
}
