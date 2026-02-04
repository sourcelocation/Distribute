package middleware

import (
	"net/http"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

type CustomContext struct {
	echo.Context
}

func (c *CustomContext) BindAndValidate(i interface{}) error {
	if err := c.Bind(i); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid input")
	}
	if err := c.Validate(i); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Validation failed")
	}
	return nil
}

func (c *CustomContext) GetUUID(param string) (uuid.UUID, error) {
	return uuid.Parse(c.Param(param))
}

func Handle(h func(*CustomContext) error) echo.HandlerFunc {
	return func(c echo.Context) error {
		cc := &CustomContext{c}
		return h(cc)
	}
}
