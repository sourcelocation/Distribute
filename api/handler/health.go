package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

// HealthCheckHandler godoc
// @Summary Health check
// @Description Basic liveness endpoint.
// @Tags info
// @Produce plain
// @Success 200 {string} string "Service is running"
// @Router /info/health [get]
func (h *Handler) HealthCheckHandler(c echo.Context) error {
	return c.String(http.StatusOK, "Service is running")
}

// GetServerInfo godoc
// @Summary Get server info
// @Description Returns server version and request-mail related configuration.
// @Tags info
// @Produce json
// @Success 200 {object} ServerInfoResponse
// @Router /info [get]
func (h *Handler) GetServerInfo(c echo.Context) error {
	announcement, _ := h.settings_svc.Get("request_mail_announcement")
	if announcement == "" {
		announcement = "Feel free to request more music!"
	}

	version := map[string]any{
		"version":                   h.version,
		"request_mail_announcement": announcement,
		"request_mail_categories":   h.mail_svc.GetCategories(),
	}
	return c.JSON(http.StatusOK, version)
}
