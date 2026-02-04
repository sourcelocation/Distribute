package handler

import (
	"net/http"
	"path/filepath"
	"strconv"

	"github.com/ProjectDistribute/distributor/middleware"
	"github.com/ProjectDistribute/distributor/utils"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

// DownloadFile godoc
// @Summary Download song file
// @Description Downloads a stored song file by its file ID.
// @Tags songs
// @Produce application/octet-stream
// @Param file_id path string true "File ID (UUID)"
// @Success 200 {file} file
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Router /songs/download/{file_id} [get]
func (h *Handler) DownloadFile(c *middleware.CustomContext) error {
	fileId, err := c.GetUUID("file_id")
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Valid file_id is required")
	}

	file, err := h.song_svc.Store.GetFileByID(fileId)
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "File not found")
	}

	filePath := file.FilePath()
	return c.File(filePath)
}

// AssignFileToSong godoc
// @Summary Assign audio file to song
// @Description Uploads an audio file and associates it to an existing song. Requires an admin JWT.
// @Tags songs
// @Security BearerAuth
// @Accept multipart/form-data
// @Produce json
// @Param song_id formData string true "Song ID (UUID)"
// @Param file formData file true "Audio file"
// @Success 200 {object} AssignFileToSongResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /songs/assign-file [post]
func (h *Handler) AssignFileToSong(c echo.Context) error {
	songID, err := uuid.Parse(c.FormValue("song_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Valid song_id is required")
	}

	fh, err := c.FormFile("file")
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Form file 'file' is required")
	}

	filename := fh.Filename
	if filepath.Base(filename) != filename {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid filename")
	}
	format := utils.GetFileFormat(filename)
	if format == nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Could not determine file format")
	}
	allowed := map[string]bool{
		"mp3":  true,
		"flac": true,
		"wav":  true,
		"ogg":  true,
		"m4a":  true,
	}
	if !allowed[*format] {
		return echo.NewHTTPError(http.StatusBadRequest, "Unsupported file format: "+*format)
	}

	src, err := fh.Open()
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to read uploaded file")
	}
	defer src.Close()

	songFile, err := h.song_svc.AssignFileToSong(songID, *format, src)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to assign file to song: "+err.Error())
	}
	return c.JSON(http.StatusOK, AssignFileToSongResponse{
		Status: "File assigned to song successfully",
		File: SongFile{
			ID:        songFile.ID,
			CreatedAt: songFile.CreatedAt,
			Format:    songFile.Format,
			Duration:  songFile.Duration,
		},
	})
}

// AssignFileToSongByPath godoc
// @Summary Assign audio file to song by path
// @Description Moves an audio file from a shared volume path and associates it to an existing song. Requires an admin JWT.
// @Tags songs
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body AssignFileByPathRequest true "Request body"
// @Success 200 {object} AssignFileToSongResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /songs/assign-file-by-path [post]
func (h *Handler) AssignFileToSongByPath(c echo.Context) error {
	var req AssignFileByPathRequest
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

	songFile, err := h.song_svc.AssignFileToSongByPath(req.SongID, cleanPath)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to assign file to song: "+err.Error())
	}
	return c.JSON(http.StatusOK, AssignFileToSongResponse{
		Status: "File assigned to song successfully",
		File: SongFile{
			ID:        songFile.ID,
			CreatedAt: songFile.CreatedAt,
			Format:    songFile.Format,
			Duration:  songFile.Duration,
		},
	})
}

// GetSongs godoc
// @Summary List songs
// @Description Returns the 50 latest songs, or paginated list if page/limit params are provided.
// @Tags songs
// @Produce json
// @Param page query int false "Page number"
// @Param limit query int false "Items per page"
// @Success 200 {object} GetSongsResponse
// @Failure 500 {object} ErrorResponse
// @Router /songs [get]
func (h *Handler) GetSongs(c echo.Context) error {
	pageStr := c.QueryParam("page")
	limitStr := c.QueryParam("limit")

	if pageStr != "" && limitStr != "" {
		page, _ := strconv.Atoi(pageStr)
		limit, _ := strconv.Atoi(limitStr)

		if page < 1 {
			page = 1
		}
		if limit < 1 {
			limit = 10
		}

		songs, hasNext, err := h.song_svc.Store.GetSongsPaginated(page, limit)
		if err != nil {
			return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve songs")
		}

		dtos := make([]Song, len(songs))
		for i, s := range songs {
			dtos[i] = FromSongModel(s)
		}
		return c.JSON(http.StatusOK, map[string]any{
			"data":     dtos,
			"has_next": hasNext,
		})
	}

	songs, err := h.song_svc.Store.GetLatestSongs()
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve songs")
	}

	dtos := make([]Song, len(songs))
	for i, s := range songs {
		dtos[i] = FromSongModel(s)
	}
	return c.JSON(http.StatusOK, GetSongsResponse{Songs: dtos})
}

// GetSong godoc
// @Summary Get song
// @Description Returns a song by ID.
// @Tags songs
// @Produce json
// @Param id path string true "Song ID (UUID)"
// @Success 200 {object} Song
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /songs/{id} [get]
func (h *Handler) GetSong(c echo.Context) error {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid song ID")
	}

	song, err := h.song_svc.Store.GetSongByID(id)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve song")
	}
	if song == nil {
		return echo.NewHTTPError(http.StatusNotFound, "Song not found")
	}

	return c.JSON(http.StatusOK, FromSongModel(*song))
}

// GetSongFiles godoc
// @Summary List files for a song
// @Description Returns all files associated with a song.
// @Tags songs
// @Produce json
// @Param id path string true "Song ID (UUID)"
// @Success 200 {array} model.SongFile
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /songs/{id}/files [get]
func (h *Handler) GetSongFiles(c echo.Context) error {
	songID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid song ID")
	}

	files, err := h.song_svc.GetSongFiles(songID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve song files")
	}
	return c.JSON(http.StatusOK, FromSongFileModels(files))
}

// ADMIN STUFF
// CreateSong godoc
// @Summary Create song metadata
// @Description Creates a new song and (if needed) its artist and album. Requires an admin JWT.
// @Tags songs
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body CreateSongRequest true "Song metadata"

// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /songs [post]
func (h *Handler) CreateSong(c echo.Context) error {
	var req CreateSongRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}
	if err := c.Validate(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Validation failed: "+err.Error())
	}

	newSong, err := h.song_svc.CreateSong(req.Title, req.Artists, req.AlbumTitle, req.AlbumID)
	if err != nil {
		if newSong != nil {
			return echo.NewHTTPError(http.StatusConflict,
				map[string]any{
					"song":  FromSongModel(*newSong),
					"album": FromAlbumModel(newSong.Album),
				})
		}
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to create song: "+err.Error())
	}
	songResponse := FromSongModel(*newSong)
	albumResponse := FromAlbumModel(newSong.Album)

	artistsResponse := make([]Artist, len(newSong.Artists))
	for i, a := range newSong.Artists {
		artistsResponse[i] = FromArtistModel(a)
	}

	return c.JSON(http.StatusCreated, map[string]any{
		"song":    songResponse,
		"album":   albumResponse,
		"artists": artistsResponse,
	})
}

// DeleteSong godoc
// @Summary Delete song
// @Description Deletes a song by ID. Requires an admin JWT.
// @Tags songs
// @Security BearerAuth
// @Param id path string true "Song ID (UUID)"
// @Success 204 {string} string "No Content"
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /songs/{id} [delete]
func (h *Handler) DeleteSong(c echo.Context) error {
	songID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid song ID")
	}

	err = h.song_svc.DeleteSong(songID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to delete song: "+err.Error())
	}
	return c.NoContent(http.StatusNoContent)
}

// UpdateSong godoc
// @Summary Update song
// @Description Updates song metadata. Requires an admin JWT.
// @Tags songs
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Song ID (UUID)"
// @Param request body UpdateSongRequest true "Song metadata"
// @Success 200 {object} Song
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /songs/{id} [put]
func (h *Handler) UpdateSong(c echo.Context) error {
	songID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid song ID")
	}

	var req UpdateSongRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}

	updatedSong, err := h.song_svc.UpdateSong(songID, req.Title, req.Artists, req.AlbumTitle, req.AlbumID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update song: "+err.Error())
	}

	return c.JSON(http.StatusOK, FromSongModel(*updatedSong))
}

// GetSongsBatch godoc
// @Summary Batch get songs
// @Description Returns a list of songs by IDs.
// @Tags songs
// @Accept json
// @Produce json
// @Param request body BatchIDRequest true "Song IDs"
// @Success 200 {array} Song
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /songs/batch [post]
func (h *Handler) GetSongsBatch(c echo.Context) error {
	type BatchIDRequest struct {
		IDs []uuid.UUID `json:"ids" validate:"required"`
	}
	var req BatchIDRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}

	songs, err := h.song_svc.Store.GetSongsByIDs(req.IDs)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve songs")
	}

	dtos := make([]Song, len(songs))
	for i, s := range songs {
		dtos[i] = FromSongModel(s)
	}
	return c.JSON(http.StatusOK, dtos)
}

// DeleteSongFile godoc
// @Summary Delete song file
// @Description Deletes a song file by ID. Requires an admin JWT.
// @Tags songs
// @Security BearerAuth
// @Param id path string true "File ID (UUID)"
// @Success 204 {string} string "No Content"
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /songs/files/{id} [delete]
func (h *Handler) DeleteSongFile(c echo.Context) error {
	fileID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid file ID")
	}

	err = h.song_svc.DeleteSongFile(fileID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to delete song file: "+err.Error())
	}
	return c.NoContent(http.StatusNoContent)
}
