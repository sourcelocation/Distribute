package handler

import (
	"net/http"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

// ServeAlbumCover godoc
// @Summary Serve album cover image
// @Description Serves a JPG album cover. The `res` parameter selects low or high quality.
// @Tags images
// @Produce image/jpeg
// @Param id path string true "Album ID (UUID)"
// @Param res path string true "Resolution (lq|hq)" Enums(lq,hq)
// @Success 200 {file} file
// @Failure 400 {string} string "Invalid parameters"
// @Router /images/covers/{id}/{res} [get]
func (h *Handler) ServeAlbumCover(c echo.Context) error {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return c.String(http.StatusBadRequest, "Invalid album ID")
	}
	res := c.Param("res")
	if res != "lq" && res != "hq" {
		return c.String(http.StatusBadRequest, "Invalid resolution parameter. Use 'lq' or 'hq'")
	}
	format := "jpg"
	filePath := h.album_svc.GetAlbumCoverPath(id, format, res)
	return c.File(filePath)
}
