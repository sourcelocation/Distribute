package handler

import (
	"github.com/labstack/echo/v4"
)

// SetupStatus godoc
// @Summary Check setup status
// @Description Returns whether the server setup has been completed.
// @Tags setup
// @Produce json
// @Success 200 {object} map[string]bool
// @Router /setup/status [get]
func (h *Handler) SetupStatus(c echo.Context) error {
	isComplete := h.settings_svc.IsSetupComplete()

	// Double check: if any admin exists, we consider it setup to avoid lockout
	// This covers cases where migration happens on existing instance
	if !isComplete {
		// We don't have a direct "IsAnyAdmin" method exposed easily here without digging into store,
		// but let's trust the settings flag for the wizard flow.
		// Actually, let's just stick to the flag for now as it maps to the "fresh install" requirement.
	}

	return c.JSON(200, map[string]bool{"setup_complete": isComplete})
}

// CompleteSetup godoc
// @Summary Complete initial setup
// @Description Sets up the admin user and initial configuration. available only if not setup.
// @Tags setup
// @Accept json
// @Produce json
// @Param request body CompleteSetupRequest true "Setup payload"
// @Success 200 {string} string "Success"
// @Failure 400 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Router /setup/complete [post]
func (h *Handler) CompleteSetup(c echo.Context) error {
	if h.settings_svc.IsSetupComplete() {
		return c.JSON(403, map[string]string{"error": "Setup already completed"})
	}

	var input CompleteSetupRequest
	if err := c.Bind(&input); err != nil {
		return c.JSON(400, map[string]string{"error": "Invalid input"})
	}
	if err := c.Validate(&input); err != nil {
		return c.JSON(400, map[string]string{"error": "Validation failed"})
	}

	// 1. Create Admin User
	user, err := h.user_svc.CreateUser(input.Username, input.Password)
	if err != nil {
		return c.JSON(500, map[string]string{"error": "Failed to create user: " + err.Error()})
	}
	if err := h.user_svc.Store.SetAdminStatus(user, true); err != nil {
		return c.JSON(500, map[string]string{"error": "Failed to set admin status"})
	}

	// 2. Save Settings
	if err := h.settings_svc.Set("server_url", input.ServerURL); err != nil {
		return c.JSON(500, map[string]string{"error": "Failed to save server_url"})
	}

	// Use default if empty
	categories := input.MailCategories
	if categories == "" {
		categories = "song_only,album,playlist"
	}
	if err := h.settings_svc.Set("mail_categories", categories); err != nil {
		return c.JSON(500, map[string]string{"error": "Failed to save mail_categories"})
	}

	announcement := input.RequestMailAnnouncement
	if announcement == "" {
		announcement = "Feel free to request more music!"
	}
	if err := h.settings_svc.Set("request_mail_announcement", announcement); err != nil {
		return c.JSON(500, map[string]string{"error": "Failed to save announcement"})
	}

	// 3. Mark Complete
	if err := h.settings_svc.Set("setup_complete", "true"); err != nil {
		return c.JSON(500, map[string]string{"error": "Failed to mark setup complete"})
	}

	return c.JSON(200, "Setup completed successfully")
}
