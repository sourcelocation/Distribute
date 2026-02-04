package handler

import (
	"github.com/labstack/echo/v4"
)

// GetSettings godoc
// @Summary Get system settings
// @Description Returns all system settings. Requires admin JWT.
// @Tags admin
// @Security BearerAuth
// @Produce json
// @Success 200 {object} map[string]string
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /admin/settings [get]
func (h *Handler) GetSettings(c echo.Context) error {
	settings, err := h.settings_svc.GetAll()
	if err != nil {
		return c.JSON(500, map[string]string{"error": "Failed to retrieve settings"})
	}
	return c.JSON(200, settings)
}

// UpdateSettings godoc
// @Summary Update system settings
// @Description Updates system settings (partial update). Requires admin JWT.
// @Tags admin
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body map[string]string true "Settings kv pairs"
// @Success 200 {object} map[string]string
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /admin/settings [put]
func (h *Handler) UpdateSettings(c echo.Context) error {
	var input map[string]string
	if err := c.Bind(&input); err != nil {
		return c.JSON(400, map[string]string{"error": "Invalid input"})
	}

	// Allowed keys to update
	allowedKeys := map[string]bool{
		"server_url":                true,
		"mail_categories":           true,
		"request_mail_announcement": true,
	}

	for key, value := range input {
		if !allowedKeys[key] {
			continue // skip unknown/protected keys
		}
		if err := h.settings_svc.Set(key, value); err != nil {
			return c.JSON(500, map[string]string{"error": "Failed to update " + key})
		}
	}

	// Return fresh settings
	settings, err := h.settings_svc.GetAll()
	if err != nil {
		return c.JSON(500, map[string]string{"error": "Failed to retrieve settings"})
	}
	return c.JSON(200, settings)
}
