package handler

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/ProjectDistribute/distributor/middleware"
	"github.com/ProjectDistribute/distributor/store"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

// CreatePlaylist godoc
// @Summary Create playlist
// @Description Creates a playlist under the given folder for the given user. Requires that the JWT subject matches user_id or that the token has admin privileges.
// @Tags playlists
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body CreatePlaylistRequest true "Playlist payload"
// @Success 201 {object} Playlist
// @Failure 400 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 409 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /playlists [post]
func (h *Handler) CreatePlaylist(c *middleware.CustomContext) error {
	user := c.Get("user").(*jwt.Token)
	me := user.Claims.(*middleware.JwtCustomClaims)
	userID := me.UUID()

	type PlaylistInput struct {
		ID           uuid.UUID   `json:"id" validate:"required"`
		Name         string      `json:"name" validate:"required,max=50"`
		ParentFolder uuid.UUID   `json:"parent_folder_id" validate:"required"`
		SongIDs      []uuid.UUID `json:"song_ids"`
	}

	var input PlaylistInput
	if err := c.Bind(&input); err != nil {
		return echo.NewHTTPError(400, "Invalid input")
	}
	if err := c.Validate(&input); err != nil {
		return echo.NewHTTPError(400, "Validation failed")
	}
	playlist, err := h.playlist_svc.CreatePlaylist(input.ID, userID, input.Name, input.ParentFolder, input.SongIDs)
	if err != nil {
		if errors.Is(err, store.ErrPlaylistExists) {
			return echo.NewHTTPError(http.StatusConflict, "Playlist with this ID already exists")
		}
		return echo.NewHTTPError(500, err.Error())
	}

	return c.JSON(201, FromPlaylistModel(playlist))
}

// GetUserPlaylists godoc
// @Summary List user playlists
// @Description Lists playlists owned by the given user.
// @Tags playlists
// @Security BearerAuth
// @Produce json
// @Param user_id path string true "User ID (UUID)"
// @Success 200 {array} Playlist
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /users/{user_id}/playlists [get]
func (h *Handler) GetUserPlaylists(c *middleware.CustomContext) error {
	userID, err := c.GetUUID("user_id")
	if err != nil {
		return echo.NewHTTPError(400, "Invalid user ID")
	}

	playlists, err := h.playlist_svc.Store.GetUserPlaylists(userID)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}

	dtos := make([]Playlist, len(playlists))
	for i, p := range playlists {
		dtos[i] = FromPlaylistModel(p)
	}

	return c.JSON(200, dtos)
}

// GetLibrary godoc
// @Summary Get library contents
// @Description Returns the user's library contents (folders and playlists).
// @Tags library
// @Security BearerAuth
// @Produce json
// @Param user_id path string true "User ID (UUID)"
// @Success 200 {object} LibraryResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /users/{user_id}/library [get]
func (h *Handler) GetLibrary(c *middleware.CustomContext) error {
	userID, err := c.GetUUID("user_id")
	if err != nil {
		return echo.NewHTTPError(400, "Invalid user ID")
	}

	folders, playlists, err := h.playlist_svc.Store.GetLibrary(userID)
	library := &LibraryResponse{
		Folders:   []FolderResponse{},
		Playlists: []PlaylistResponse{},
	}
	for _, folder := range folders {
		library.Folders = append(library.Folders, FolderResponse{
			ID:             folder.ID,
			Name:           folder.Name,
			ParentFolderID: folder.ParentID,
		})
	}
	for _, playlist := range playlists {
		library.Playlists = append(library.Playlists, PlaylistResponse{
			ID:             playlist.ID,
			Name:           playlist.Name,
			ParentFolderID: playlist.FolderID,
		})
	}
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}

	return c.JSON(200, library)
}

// func (h *Handler) GetRootFolder(c *middleware.CustomContext) error {
// 	userID, err := c.GetUUID("user_id")
// 	if err != nil {
// 		return echo.NewHTTPError(400, "Invalid user ID")
// 	}

// 	folders, err := h.playlist_svc.Store.GetFullTree(userID)
// 	if err != nil {
// 		return echo.NewHTTPError(500, err.Error())
// 	}

// 	return c.JSON(200, folders)
// }

// CreatePlaylistFolder godoc
// @Summary Create folder
// @Description Creates a playlist folder. Requires that the JWT subject matches user_id or that the token has admin privileges.
// @Tags folders
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param user_id path string true "User ID (UUID)"
// @Param request body CreatePlaylistFolderRequest true "Folder payload"
// @Success 201 {object} PlaylistFolder
// @Failure 400 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /users/{user_id}/folders [post]
func (h *Handler) CreatePlaylistFolder(c *middleware.CustomContext) error {
	userID, err := c.GetUUID("user_id")
	if err != nil {
		return echo.NewHTTPError(400, "Invalid user ID")
	}

	me := c.Get("user").(*jwt.Token).Claims.(*middleware.JwtCustomClaims)
	if me.UUID() != userID && !me.Admin {
		return echo.NewHTTPError(403, "Forbidden")
	}

	type FolderInput struct {
		ID       uuid.UUID `json:"id" validate:"required"`
		Name     string    `json:"name" validate:"required,max=50"`
		ParentID uuid.UUID `json:"parent_folder_id" validate:"required"`
	}

	var input FolderInput
	if err := c.Bind(&input); err != nil {
		return echo.NewHTTPError(400, "Invalid input")
	}
	if err := c.Validate(&input); err != nil {
		return echo.NewHTTPError(400, "Validation failed")
	}

	playlistFolder, err := h.playlist_svc.CreatePlaylistFolder(input.ID, userID, input.Name, &input.ParentID)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}

	return c.JSON(201, FromPlaylistFolderModel(playlistFolder))
}

// DeletePlaylistFolder godoc
// @Summary Delete folder
// @Description Deletes a playlist folder. Admin tokens can delete any folder; non-admin tokens are restricted to their own.
// @Tags folders
// @Security BearerAuth
// @Param user_id path string true "User ID (UUID)"
// @Param folder_id path string true "Folder ID (UUID)"
// @Success 204 {string} string "No Content"
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /users/{user_id}/folders/{folder_id} [delete]
func (h *Handler) DeletePlaylistFolder(c *middleware.CustomContext) error {
	folderID, err := c.GetUUID("folder_id")
	if err != nil {
		return echo.NewHTTPError(400, "Invalid folder ID")
	}
	me := c.Get("user").(*jwt.Token).Claims.(*middleware.JwtCustomClaims)

	err = h.playlist_svc.Store.DeletePlaylistFolder(folderID, me.UUID(), me.Admin)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}

	return c.NoContent(204)
}

// GetPlaylist godoc
// @Summary Get playlist
// @Description Returns a playlist with songs, song files, album and artist preloaded.
// @Tags playlists
// @Security BearerAuth
// @Produce json
// @Param user_id path string true "User ID (UUID)"
// @Param playlist_id path string true "Playlist ID (UUID)"
// @Success 200 {object} Playlist
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /users/{user_id}/playlists/{playlist_id} [get]
func (h *Handler) GetPlaylist(c *middleware.CustomContext) error {
	playlistID, err := c.GetUUID("playlist_id")
	if err != nil {
		return echo.NewHTTPError(400, "Invalid playlist ID")
	}

	playlist, err := h.playlist_svc.Store.GetPlaylistByID(playlistID)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}

	return c.JSON(200, FromPlaylistModel(*playlist))
}

// AddSongToPlaylist godoc
// @Summary Add song to playlist
// @Description Adds a song to a playlist.
// @Tags playlists
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param playlist_id path string true "Playlist ID (UUID)"
// @Param request body AddSongToPlaylistRequest true "Song payload"
// @Success 200 {object} LibraryResponse
// @Failure 400 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /playlists/{playlist_id}/songs [post]
func (h *Handler) AddSongToPlaylist(c *middleware.CustomContext) error {
	playlistID, err := c.GetUUID("playlist_id")
	if err != nil {
		return echo.NewHTTPError(400, "Invalid playlist ID")
	}

	playlist, err := h.playlist_svc.Store.GetPlaylistByID(playlistID)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}
	if playlist == nil {
		return echo.NewHTTPError(404, "Playlist not found")
	}

	me := c.Get("user").(*jwt.Token).Claims.(*middleware.JwtCustomClaims)
	if playlist.UserID != me.UUID() && !me.Admin {
		return echo.NewHTTPError(403, "Forbidden")
	}

	type AddSongInput struct {
		SongID uuid.UUID `json:"song_id" validate:"required"`
	}

	var input AddSongInput
	if err := c.Bind(&input); err != nil {
		return echo.NewHTTPError(400, "Invalid input")
	}
	if err := c.Validate(&input); err != nil {
		return echo.NewHTTPError(400, "Validation failed")
	}

	err = h.playlist_svc.Store.AddSongToPlaylist(playlistID, input.SongID)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}
	return c.JSON(200, nil)
}

// RemoveSongFromPlaylist godoc
// @Summary Remove song from playlist
// @Description Removes a song from a playlist.
// @Tags playlists
// @Security BearerAuth
// @Produce json
// @Param playlist_id path string true "Playlist ID (UUID)"
// @Param song_id path string true "Song ID (UUID)"
// @Success 200 {object} LibraryResponse
// @Failure 400 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /playlists/{playlist_id}/songs/{song_id} [delete]
func (h *Handler) RemoveSongFromPlaylist(c *middleware.CustomContext) error {
	playlistID, err := c.GetUUID("playlist_id")
	if err != nil {
		return echo.NewHTTPError(400, "Invalid playlist ID")
	}

	playlist, err := h.playlist_svc.Store.GetPlaylistByID(playlistID)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}
	if playlist == nil {
		return echo.NewHTTPError(404, "Playlist not found")
	}

	me := c.Get("user").(*jwt.Token).Claims.(*middleware.JwtCustomClaims)
	if playlist.UserID != me.UUID() && !me.Admin {
		return echo.NewHTTPError(403, "Forbidden")
	}

	songID, err := c.GetUUID("song_id")
	if err != nil {
		return echo.NewHTTPError(400, "Invalid song ID")
	}

	err = h.playlist_svc.Store.RemoveSongFromPlaylist(playlistID, songID)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}

	return c.JSON(200, nil)
}

// UpdatePlaylistSongOrder godoc
// @Summary Update song order in playlist
// @Description Updates the order of a song in a playlist.
// @Tags playlists
// @Security BearerAuth
// @Produce json
// @Param playlist_id path string true "Playlist ID (UUID)"
// @Param song_id path string true "Song ID (UUID)"
// @Param request body map[string]string true "Order payload"
// @Success 200 {object} nil
// @Failure 400 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /playlists/{playlist_id}/songs/{song_id} [put]
func (h *Handler) UpdatePlaylistSongOrder(c *middleware.CustomContext) error {
	playlistID, err := c.GetUUID("playlist_id")
	if err != nil {
		return echo.NewHTTPError(400, "Invalid playlist ID")
	}

	playlist, err := h.playlist_svc.Store.GetPlaylistByID(playlistID)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}
	if playlist == nil {
		return echo.NewHTTPError(404, "Playlist not found")
	}

	me := c.Get("user").(*jwt.Token).Claims.(*middleware.JwtCustomClaims)
	if playlist.UserID != me.UUID() && !me.Admin {
		return echo.NewHTTPError(403, "Forbidden")
	}

	songID, err := c.GetUUID("song_id")
	if err != nil {
		return echo.NewHTTPError(400, "Invalid song ID")
	}

	type OrderInput struct {
		Order string `json:"order" validate:"required"`
	}
	var input OrderInput
	if err := c.Bind(&input); err != nil {
		return echo.NewHTTPError(400, "Invalid input")
	}

	err = h.playlist_svc.Store.UpdateSongOrder(playlistID, songID, input.Order)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}

	return c.JSON(200, nil)
}

// DeletePlaylist godoc (DEPRECATED: Use DeletePlaylistByID)
func (h *Handler) DeletePlaylist(c *middleware.CustomContext) error {
	return echo.NewHTTPError(http.StatusGone, "This endpoint is deprecated. Use DELETE /playlists/:id instead.")
}

// RenamePlaylist godoc (DEPRECATED: Use UpdatePlaylistByID)
func (h *Handler) RenamePlaylist(c *middleware.CustomContext) error {
	return echo.NewHTTPError(http.StatusGone, "This endpoint is deprecated. Use PUT /playlists/:id instead.")
}

// MovePlaylistToFolder godoc
// @Summary Move playlist to folder
// @Description Moves a playlist to a different folder.
// @Tags playlists
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param playlist_id path string true "Playlist ID (UUID)"
// @Param request body MovePlaylistRequest true "Move payload"
// @Success 200 {object} LibraryResponse
// @Failure 400 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /playlists/{playlist_id}/move [put]
func (h *Handler) MovePlaylistToFolder(c *middleware.CustomContext) error {
	playlistID, err := c.GetUUID("playlist_id")
	if err != nil {
		return echo.NewHTTPError(400, "Invalid playlist ID")
	}

	playlist, err := h.playlist_svc.Store.GetPlaylistByID(playlistID)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}
	if playlist == nil {
		return echo.NewHTTPError(404, "Playlist not found")
	}

	me := c.Get("user").(*jwt.Token).Claims.(*middleware.JwtCustomClaims)
	if playlist.UserID != me.UUID() && !me.Admin {
		return echo.NewHTTPError(403, "Forbidden")
	}

	type MoveInput struct {
		TargetFolderID uuid.UUID `json:"parent_folder_id" validate:"required"`
	}

	var input MoveInput
	if err := c.Bind(&input); err != nil {
		return echo.NewHTTPError(400, "Invalid input")
	}
	if err := c.Validate(&input); err != nil {
		return echo.NewHTTPError(400, "Validation failed")
	}

	err = h.playlist_svc.Store.MovePlaylistToFolder(playlistID, input.TargetFolderID, playlist.UserID, me.Admin)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}

	return c.JSON(200, nil)
}

// RenamePlaylistFolder godoc
// @Summary Rename folder
// @Description Renames a playlist folder and returns the updated library. Requires that the JWT subject matches user_id or that the token has admin privileges.
// @Tags folders
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param user_id path string true "User ID (UUID)"
// @Param folder_id path string true "Folder ID (UUID)"
// @Param request body RenameFolderRequest true "Rename payload"
// @Success 200 {object} LibraryResponse
// @Failure 400 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /users/{user_id}/folders/{folder_id}/rename [put]
func (h *Handler) RenamePlaylistFolder(c *middleware.CustomContext) error {
	userID, err := c.GetUUID("user_id")
	if err != nil {
		return echo.NewHTTPError(400, "Invalid user ID")
	}
	me := c.Get("user").(*jwt.Token).Claims.(*middleware.JwtCustomClaims)
	if me.UUID() != userID && !me.Admin {
		return echo.NewHTTPError(403, "Forbidden")
	}

	folderID, err := c.GetUUID("folder_id")
	if err != nil {
		return echo.NewHTTPError(400, "Invalid folder ID")
	}

	type RenameInput struct {
		Name string `json:"name" validate:"required,max=50"`
	}

	var input RenameInput
	if err := c.Bind(&input); err != nil {
		return echo.NewHTTPError(400, "Invalid input")
	}
	if err := c.Validate(&input); err != nil {
		return echo.NewHTTPError(400, "Validation failed")
	}

	err = h.playlist_svc.Store.RenamePlaylistFolder(folderID, userID, input.Name, me.Admin)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}

	return c.JSON(200, nil)
}

// MoveFolderToFolder godoc
// @Summary Move folder to another folder
// @Description Moves a folder to a different parent folder and returns the updated library. Requires that the JWT subject matches user_id or that the token has admin privileges.
// @Tags folders
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param user_id path string true "User ID (UUID)"
// @Param folder_id path string true "Folder ID (UUID)"
// @Param request body MoveFolderRequest true "Move payload"
// @Success 200 {object} LibraryResponse
// @Failure 400 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /users/{user_id}/folders/{folder_id}/move [put]
func (h *Handler) MoveFolderToFolder(c *middleware.CustomContext) error {
	userID, err := c.GetUUID("user_id")
	if err != nil {
		return echo.NewHTTPError(400, "Invalid user ID")
	}
	me := c.Get("user").(*jwt.Token).Claims.(*middleware.JwtCustomClaims)
	if me.UUID() != userID && !me.Admin {
		return echo.NewHTTPError(403, "Forbidden")
	}

	folderID, err := c.GetUUID("folder_id")
	if err != nil {
		return echo.NewHTTPError(400, "Invalid folder ID")
	}

	type MoveInput struct {
		TargetParentID *uuid.UUID `json:"parent_folder_id"`
	}

	var input MoveInput
	if err := c.Bind(&input); err != nil {
		return echo.NewHTTPError(400, "Invalid input")
	}

	err = h.playlist_svc.Store.MoveFolderToFolder(folderID, input.TargetParentID, userID, me.Admin)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}

	return c.JSON(200, nil)
}

// GetPlaylistsBatch godoc
// @Summary Batch get playlists
// @Description Returns a list of playlists by IDs.
// @Tags playlists
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param user_id path string true "User ID (UUID)"
// @Param request body BatchIDRequest true "Playlist IDs"
// @Success 200 {array} Playlist
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /users/{user_id}/playlists/batch [post]
func (h *Handler) GetPlaylistsBatch(c *middleware.CustomContext) error {
	type BatchIDRequest struct {
		IDs []uuid.UUID `json:"ids" validate:"required"`
	}
	var req BatchIDRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}

	playlists, err := h.playlist_svc.Store.GetPlaylistsByIDs(req.IDs)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve playlists")
	}

	dtos := make([]Playlist, len(playlists))
	for i, p := range playlists {
		dtos[i] = FromPlaylistModel(p)
	}
	return c.JSON(200, dtos)
}

// GetFoldersBatch godoc
// @Summary Batch get folders
// @Description Returns a list of folders by IDs.
// @Tags folders
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param user_id path string true "User ID (UUID)"
// @Param request body BatchIDRequest true "Folder IDs"
// @Success 200 {array} FolderResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /users/{user_id}/folders/batch [post]
func (h *Handler) GetFoldersBatch(c *middleware.CustomContext) error {
	type BatchIDRequest struct {
		IDs []uuid.UUID `json:"ids" validate:"required"`
	}
	var req BatchIDRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}

	folders, err := h.playlist_svc.Store.GetFoldersByIDs(req.IDs)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve folders")
	}

	dtos := make([]FolderResponse, len(folders))
	for i, f := range folders {
		dtos[i] = FolderResponse{
			ID:             f.ID,
			Name:           f.Name,
			ParentFolderID: f.ParentID,
		}
	}
	return c.JSON(200, dtos)
}

// CreatePlaylistWithContents godoc
// @Summary Create playlist with contents
// @Description Creates a new playlist for the given user in their root folder with the given songs. Requires admin privileges.
// @Tags admin
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body CreatePlaylistWithContentsRequest true "Create playlist with contents payload"
// @Success 201 {object} Playlist
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /admin/fulfill-request [post]
func (h *Handler) CreatePlaylistWithContents(c *middleware.CustomContext) error {
	var input CreatePlaylistWithContentsRequest
	if err := c.Bind(&input); err != nil {
		return echo.NewHTTPError(400, "Invalid input")
	}
	if err := c.Validate(&input); err != nil {
		return echo.NewHTTPError(400, "Validation failed")
	}

	playlist, err := h.playlist_svc.CreatePlaylistWithContents(input.UserID, input.Name, input.SongIDs)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}

	return c.JSON(201, FromPlaylistModel(playlist))
}

// GetPlaylists godoc
// @Summary List playlists paginated
// @Description Returns paginated list of playlists.
// @Tags playlists
// @Produce json
// @Param page query int false "Page number"
// @Param limit query int false "Items per page"
// @Success 200 {object} map[string]any
// @Failure 500 {object} ErrorResponse
// @Router /playlists [get]
func (h *Handler) GetPlaylists(c echo.Context) error {
	page, _ := strconv.Atoi(c.QueryParam("page"))
	limit, _ := strconv.Atoi(c.QueryParam("limit"))

	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}

	playlists, hasNext, err := h.playlist_svc.Store.GetPlaylistsPaginated(page, limit)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve playlists")
	}

	dtos := make([]Playlist, len(playlists))
	for i, p := range playlists {
		dtos[i] = FromPlaylistModel(p)
	}
	return c.JSON(http.StatusOK, map[string]any{
		"data":     dtos,
		"has_next": hasNext,
	})
}

// GetPlaylist (Global) godoc
// @Summary Get playlist (Global)
// @Description Returns a playlist by ID. Requires admin JWT or ownership.
// @Tags playlists
// @Security BearerAuth
// @Produce json
// @Param id path string true "Playlist ID (UUID)"
// @Success 200 {object} Playlist
// @Failure 400 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /playlists/{id} [get]
func (h *Handler) GetPlaylistByID(c echo.Context) error {
	playlistID, err := uuid.Parse(c.Param("playlist_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid playlist ID")
	}

	playlist, err := h.playlist_svc.Store.GetPlaylistByID(playlistID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve playlist")
	}

	// Check permissions if not already handled by middleware or if specific check needed
	user := c.Get("user").(*jwt.Token)
	me := user.Claims.(*middleware.JwtCustomClaims)

	// Assuming playlist has UserID.
	// If playlist.UserID != me.UUID && !me.Admin -> 403
	// However, if playlist is "public" (not implemented yet), it might be allowed.
	// For now, strict ownership or admin.
	if playlist.UserID != me.UUID() && !me.Admin {
		return echo.NewHTTPError(http.StatusForbidden, "Forbidden")
	}

	return c.JSON(http.StatusOK, FromPlaylistModel(*playlist))
}

// UpdatePlaylist (Global) godoc
// @Summary Update playlist (Global)
// @Description Renames a playlist. Requires admin JWT or ownership.
// @Tags playlists
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Playlist ID (UUID)"
// @Param request body RenamePlaylistRequest true "Rename payload"
// @Success 200 {object} Playlist
// @Failure 400 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /playlists/{id} [put]
func (h *Handler) UpdatePlaylistByID(c echo.Context) error {
	playlistID, err := uuid.Parse(c.Param("playlist_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid playlist ID")
	}

	type RenameInput struct {
		Name string `json:"name" validate:"required,max=50"`
	}
	var input RenameInput
	if err := c.Bind(&input); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid input")
	}

	playlist, err := h.playlist_svc.Store.GetPlaylistByID(playlistID)
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "Playlist not found")
	}

	user := c.Get("user").(*jwt.Token)
	me := user.Claims.(*middleware.JwtCustomClaims)

	if playlist.UserID != me.UUID() && !me.Admin {
		return echo.NewHTTPError(http.StatusForbidden, "Forbidden")
	}

	err = h.playlist_svc.Store.RenamePlaylist(playlistID, playlist.UserID, input.Name, me.Admin)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	// Refetch to return updated
	updated, err := h.playlist_svc.Store.GetPlaylistByID(playlistID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve updated playlist")
	}

	return c.JSON(http.StatusOK, FromPlaylistModel(*updated))
}

// DeletePlaylist (Global) godoc
// @Summary Delete playlist (Global)
// @Description Deletes a playlist by ID. Requires admin JWT or ownership.
// @Tags playlists
// @Security BearerAuth
// @Param id path string true "Playlist ID (UUID)"
// @Success 204 {string} string "No Content"
// @Failure 400 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /playlists/{id} [delete]
func (h *Handler) DeletePlaylistByID(c echo.Context) error {
	playlistID, err := uuid.Parse(c.Param("playlist_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid playlist ID")
	}

	playlist, err := h.playlist_svc.Store.GetPlaylistByID(playlistID)
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "Playlist not found")
	}

	user := c.Get("user").(*jwt.Token)
	me := user.Claims.(*middleware.JwtCustomClaims)

	if playlist.UserID != me.UUID() && !me.Admin {
		return echo.NewHTTPError(http.StatusForbidden, "Forbidden")
	}

	err = h.playlist_svc.Store.DeletePlaylist(playlistID, playlist.UserID, me.Admin)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.NoContent(http.StatusNoContent)
}
