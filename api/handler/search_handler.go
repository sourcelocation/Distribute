package handler

import (
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"
)

// SearchItems godoc
// @Summary Global search
// @Description Searches for songs, artists, and playlists using Meilisearch.
// @Tags search
// @Produce json
// @Param q query string true "Search query"
// @Param limit query int false "Results limit"
// @Success 200 {array} service.SearchResult
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /search [get]
func (h *Handler) SearchItems(c echo.Context) error {
	query := c.QueryParam("q")
	if query == "" {
		return echo.NewHTTPError(http.StatusBadRequest, "Query parameter 'q' is required")
	}

	limit := 20
	if lStr := c.QueryParam("limit"); lStr != "" {
		if l, err := strconv.Atoi(lStr); err == nil {
			limit = l
		}
	}

	filterType := c.QueryParam("type")

	results, err := h.search_svc.Search(query, limit, filterType)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Search failed: "+err.Error())
	}

	return c.JSON(http.StatusOK, results)
}
