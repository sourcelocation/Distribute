package handler

import (
	"net/http"
	"path/filepath"
	"strconv"

	"github.com/ProjectDistribute/distributor/utils"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

// GetAlbums godoc
// @Summary List albums paginated
// @Description Returns paginated list of albums.
// @Tags albums
// @Produce json
// @Param page query int false "Page number"
// @Param limit query int false "Items per page"
// @Success 200 {object} map[string]any
// @Failure 500 {object} ErrorResponse
// @Router /admin/albums [get]
func (h *Handler) GetAlbums(c echo.Context) error {
	page, _ := strconv.Atoi(c.QueryParam("page"))
	limit, _ := strconv.Atoi(c.QueryParam("limit"))

	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}

	albums, hasNext, err := h.album_svc.Store.GetAlbumsPaginated(page, limit)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve albums")
	}

	dtos := make([]Album, len(albums))
	for i, a := range albums {
		dtos[i] = FromAlbumModel(a)
	}
	return c.JSON(http.StatusOK, map[string]any{
		"data":     dtos,
		"has_next": hasNext,
	})
}

// GetAlbum godoc
// @Summary Get album
// @Description Returns an album by ID.
// @Tags albums
// @Produce json
// @Param id path string true "Album ID (UUID)"
// @Success 200 {object} Album
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /albums/{id} [get]
func (h *Handler) GetAlbum(c echo.Context) error {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid album ID")
	}

	album, err := h.album_svc.GetAlbumByID(id)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve album")
	}
	if album == nil {
		return echo.NewHTTPError(http.StatusNotFound, "Album not found")
	}

	return c.JSON(http.StatusOK, FromAlbumModel(*album))
}

// GetAlbumsBatch godoc
// @Summary Batch get albums
// @Description Returns a list of albums by IDs.
// @Tags albums
// @Accept json
// @Produce json
// @Param request body BatchIDRequest true "Album IDs"
// @Success 200 {array} Album
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /albums/batch [post]
func (h *Handler) GetAlbumsBatch(c echo.Context) error {
	type BatchIDRequest struct {
		IDs []uuid.UUID `json:"ids" validate:"required"`
	}
	var req BatchIDRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}

	albums, err := h.album_svc.Store.GetAlbumsByIDs(req.IDs)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve albums")
	}

	dtos := make([]Album, len(albums))
	for i, a := range albums {
		dtos[i] = FromAlbumModel(a)
	}
	return c.JSON(http.StatusOK, dtos)
}

// AlbumHasCover godoc
// @Summary Check if album cover exists
// @Description Returns whether a JPG cover exists for the album.
// @Tags albums
// @Produce json
// @Param id path string true "Album ID (UUID)"
// @Success 200 {object} AlbumHasCoverResponse
// @Failure 400 {object} ErrorResponse
// @Router /albums/covers/{id} [get]
func (h *Handler) AlbumHasCover(c echo.Context) error {
	albumID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid album ID")
	}

	hasCover := h.album_svc.AlbumHasCover(albumID, "jpg")
	return c.JSON(http.StatusOK, map[string]any{"has_cover": hasCover})
}

// AssignAlbumCover godoc
// @Summary Upload album cover
// @Description Uploads a JPG album cover for the album. Requires an admin JWT.
// @Tags albums
// @Security BearerAuth
// @Accept multipart/form-data
// @Produce json
// @Param id path string true "Album ID (UUID)"
// @Param cover formData file true "JPG cover image"
// @Success 200 {object} AssignAlbumCoverResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /albums/covers/{id} [post]
func (h *Handler) AssignAlbumCover(c echo.Context) error {
	albumID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid album ID")
	}

	fh, err := c.FormFile("cover")
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Form file 'cover' is required")
	}

	src, err := fh.Open()
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to read uploaded cover file")
	}
	defer src.Close()

	fileFormat := utils.GetFileFormat(fh.Filename)
	// TODO: Support other formats
	if fileFormat == nil || *fileFormat != "jpg" {
		return echo.NewHTTPError(http.StatusBadRequest, "Only JPG format is supported for album covers")
	}

	err = h.album_svc.WriteAlbumCover(albumID, src, c.Param("id"), *fileFormat)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to assign cover to album: "+err.Error())
	}
	return c.JSON(http.StatusOK, map[string]any{"status": "Cover assigned to album successfully"})
}

// AssignAlbumCoverByPath godoc
// @Summary Assign album cover by path
// @Description Moves an album cover file from a shared volume path and associates it to an existing album. Requires an admin JWT.
// @Tags albums
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body AssignAlbumCoverByPathRequest true "Request body"
// @Success 200 {object} AssignAlbumCoverResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /albums/covers-by-path [post]
func (h *Handler) AssignAlbumCoverByPath(c echo.Context) error {
	var req AssignAlbumCoverByPathRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}
	if err := c.Validate(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Validation failed: "+err.Error())
	}

	// Security: Validate source path is within allowed directory
	allowedPrefix := "/app/storage/downloads/"
	cleanPath := filepath.Clean(req.SourcePath)
	if !utils.HasPathPrefix(cleanPath, allowedPrefix) {
		return echo.NewHTTPError(http.StatusBadRequest, "Source path must be within /app/storage/downloads/. Received: "+cleanPath)
	}

	// Check format
	format := utils.GetFileFormat(cleanPath)
	if format == nil || *format != "jpg" {
		return echo.NewHTTPError(http.StatusBadRequest, "Only JPG format is supported for album covers")
	}

	err := h.album_svc.AssignAlbumCoverByPath(req.AlbumID, cleanPath, *format)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to assign cover to album: "+err.Error())
	}
	return c.JSON(http.StatusOK, map[string]any{"status": "Cover assigned to album successfully"})
}

// UpdateAlbum godoc
// @Summary Update album
// @Description Updates album metadata. Requires an admin JWT.
// @Tags albums
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Album ID (UUID)"
// @Param request body UpdateAlbumRequest true "Album metadata"
// @Success 200 {object} Album
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /albums/{id} [put]
func (h *Handler) UpdateAlbum(c echo.Context) error {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid album ID")
	}

	var req UpdateAlbumRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}

	updatedAlbum, err := h.album_svc.UpdateAlbum(id, req.Title, req.ReleaseDate)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update album: "+err.Error())
	}

	return c.JSON(http.StatusOK, FromAlbumModel(*updatedAlbum))
}

// DeleteAlbum godoc
// @Summary Delete album
// @Description Deletes an album by ID. Requires an admin JWT.
// @Tags albums
// @Security BearerAuth
// @Param id path string true "Album ID (UUID)"
// @Success 204 {string} string "No Content"
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /albums/{id} [delete]
func (h *Handler) DeleteAlbum(c echo.Context) error {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid album ID")
	}

	album, err := h.album_svc.GetAlbumByID(id)
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "Album not found")
	}

	err = h.album_svc.DeleteAlbum(album)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to delete album: "+err.Error())
	}
	return c.NoContent(http.StatusNoContent)
}

// CreateAlbum godoc
// @Summary Create album
// @Description Creates a new album. Requires an admin JWT.
// @Tags albums
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body CreateAlbumRequest true "Album metadata"
// @Success 201 {object} Album
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /albums [post]
func (h *Handler) CreateAlbum(c echo.Context) error {
	var req CreateAlbumRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}
	if err := c.Validate(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Validation failed: "+err.Error())
	}

	// Artist Name is computed from songs, so initially it's empty
	album, err := h.album_svc.CreateAlbum(req.Title, req.ReleaseDate, "")
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to create album: "+err.Error())
	}

	return c.JSON(http.StatusCreated, FromAlbumModel(*album))
}

// GetAlbumSongs godoc
// @Summary List songs in album
// @Description Returns all songs in an album.
// @Tags albums
// @Produce json
// @Param id path string true "Album ID (UUID)"
// @Success 200 {object} GetSongsResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /albums/{id}/songs [get]
func (h *Handler) GetAlbumSongs(c echo.Context) error {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid album ID")
	}

	songs, err := h.song_svc.GetSongsByAlbumID(id)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve songs")
	}

	dtos := make([]Song, len(songs))
	for i, s := range songs {
		dtos[i] = FromSongModel(s)
	}
	return c.JSON(http.StatusOK, GetSongsResponse{Songs: dtos})
}
