package handler

import (
	"net/http"

	"github.com/ProjectDistribute/distributor/utils"
	"github.com/labstack/echo/v4"
)

func (h *Handler) AddServerRedirect(c echo.Context) error {
	serverURL := utils.Getenv("SERVER_URL", "")
	if serverURL == "" {
		return c.String(http.StatusBadRequest, "SERVER_URL environment variable is not configured")
	}
	return c.Redirect(http.StatusTemporaryRedirect, "distribute://add-server/"+serverURL)
}
