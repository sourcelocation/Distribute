package middleware

import (
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

type JwtCustomClaims struct {
	jwt.RegisteredClaims

	Admin bool `json:"admin"`
}

func (j *JwtCustomClaims) UUID() uuid.UUID {
	res, err := uuid.Parse(j.RegisteredClaims.Subject)
	if err != nil {
		return uuid.Nil
	}
	return res
}
