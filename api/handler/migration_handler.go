package handler

import (
	"log"
	"net/http"

	"github.com/ProjectDistribute/distributor/middleware"
	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
)

// RebalanceAllPlaylists godoc
// @Summary Rebalance all playlists
// @Description Rebalances the song order keys for all playlists in the system using the new Base62 alphabet. Requires admin privileges.
// @Tags admin
// @Security BearerAuth
// @Produce json
// @Success 200 {string} string "OK"
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /admin/rebalance-playlists [post]
func (h *Handler) RebalanceAllPlaylists(c *middleware.CustomContext) error {
	user := c.Get("user").(*jwt.Token)
	me := user.Claims.(*middleware.JwtCustomClaims)

	if !me.Admin {
		return echo.NewHTTPError(http.StatusForbidden, "Forbidden")
	}

	// 1. Get all playlists
	playlists, err := h.playlist_svc.Store.GetAllPlaylists()
	if err != nil {
		return echo.NewHTTPError(500, err.Error())
	}

	count := 0
	for _, p := range playlists {
		// 2. For each playlist, get songs ordered by current order
		songs, err := h.playlist_svc.Store.GetPlaylistSongs(p.ID)
		if err != nil {
			log.Printf("Failed to get songs for playlist %s: %v", p.ID, err)
			continue
		}

		if len(songs) == 0 {
			continue
		}

		// 3. Generate new keys
		// newKeys := utils.Rebalance(len(songs))

		// 4. Update each song
		// for i, songRel := range songs {
		// 	if songRel.Order != newKeys[i] {
		// 		err := h.playlist_svc.Store.UpdateSongOrder(p.ID, songRel.SongID, newKeys[i])
		// 		if err != nil {
		// 			log.Printf("Failed to update song order for playlist %s song %s: %v", p.ID, songRel.SongID, err)
		// 		}
		// 	}
		// }
		// count++
	}

	return c.JSON(200, map[string]int{"rebalanced_playlists": count})
}
