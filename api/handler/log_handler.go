package handler

import (
	"net/http"
	"os"

	"github.com/ProjectDistribute/distributor/utils"
	"github.com/labstack/echo/v4"
)

// GetServerLogs godoc
// @Summary Get server logs
// @Description Returns the last 100 lines of the server log file.
// @Tags admin
// @Security BearerAuth
// @Produce json
// @Success 200 {array} string
// @Failure 500 {object} ErrorResponse
// @Router /admin/logs [get]
func (h *Handler) GetServerLogs(c echo.Context) error {
	lines, err := utils.ReadLastNLines("data/db/server_events.log", 100)
	if err != nil {
		if os.IsNotExist(err) {
			return c.JSON(http.StatusOK, []string{})
		}
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to read log file"})
	}

	return c.JSON(http.StatusOK, lines)
}
