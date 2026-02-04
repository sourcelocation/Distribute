package router

import (
	"regexp"

	"github.com/go-playground/validator"
)

func NewValidator() *Validator {
	v := validator.New()
	v.RegisterValidation("username_chars", validateUsernameChars)
	return &Validator{
		validator: v,
	}
}

type Validator struct {
	validator *validator.Validate
}

func (v *Validator) Validate(i interface{}) error {
	return v.validator.Struct(i)
}

func validateUsernameChars(fl validator.FieldLevel) bool {
	username := fl.Field().String()
	match, _ := regexp.MatchString("^[a-zA-Z0-9_\\-]+$", username)
	return match
}
