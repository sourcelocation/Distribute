package handler

import (
	"time"

	"github.com/ProjectDistribute/distributor/middleware"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

type SyncManifest struct {
	LatestServerTime time.Time `json:"latest_server_time"`
	Changed          EntityIDs `json:"changed"`
	Removed          EntityIDs `json:"removed"`
}

type EntityIDs struct {
	Playlists []uuid.UUID `json:"playlists"`
	Folders   []uuid.UUID `json:"folders"`
	Songs     []uuid.UUID `json:"songs"`
	Albums    []uuid.UUID `json:"albums"`
	Artists   []uuid.UUID `json:"artists"`
}

// GetSync godoc
// @Summary Sync changes
// @Description Returns a manifest of changed and removed entities since the given timestamp.
// @Tags users
// @Security BearerAuth
// @Produce json
// @Param since query string false "Since timestamp (RFC3339)"
// @Success 200 {object} SyncManifest
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /users/me/sync [get]
func (h *Handler) GetSync(c *middleware.CustomContext) error {
	me := c.Get("user").(*jwt.Token).Claims.(*middleware.JwtCustomClaims)
	userID := me.UUID()

	sinceStr := c.QueryParam("since")
	var since time.Time
	var err error
	if sinceStr != "" {
		since, err = time.Parse(time.RFC3339, sinceStr)
		if err != nil {
			return echo.NewHTTPError(400, "Invalid time format")
		}
	} else {
		since = time.Unix(0, 0)
	}

	manifest := SyncManifest{
		LatestServerTime: time.Now(),
		Changed:          EntityIDs{},
		Removed:          EntityIDs{},
	}

	// Playlists
	changedPlaylists, err := h.playlist_svc.Store.GetChangedPlaylists(userID, since)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}
	manifest.Changed.Playlists = changedPlaylists

	deletedPlaylists, err := h.playlist_svc.Store.GetDeletedPlaylists(userID, since)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}
	manifest.Removed.Playlists = deletedPlaylists

	// Folders
	changedFolders, err := h.playlist_svc.Store.GetChangedFolders(userID, since)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}
	manifest.Changed.Folders = changedFolders

	deletedFolders, err := h.playlist_svc.Store.GetDeletedFolders(userID, since)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}
	manifest.Removed.Folders = deletedFolders

	// Songs (Global)
	changedSongs, err := h.song_svc.Store.GetChangedSongs(since)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}
	manifest.Changed.Songs = changedSongs

	deletedSongs, err := h.song_svc.Store.GetDeletedSongs(since)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}
	manifest.Removed.Songs = deletedSongs

	// Albums (Global)
	changedAlbums, err := h.album_svc.Store.GetChangedAlbums(since)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}
	manifest.Changed.Albums = changedAlbums

	deletedAlbums, err := h.album_svc.Store.GetDeletedAlbums(since)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}
	manifest.Removed.Albums = deletedAlbums

	// Artists (Global)
	changedArtists, err := h.artist_svc.Store.GetChangedArtists(since)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}
	manifest.Changed.Artists = changedArtists

	deletedArtists, err := h.artist_svc.Store.GetDeletedArtists(since)
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}
	manifest.Removed.Artists = deletedArtists

	return c.JSON(200, manifest)
}
