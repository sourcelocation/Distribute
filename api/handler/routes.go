package handler

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"log"
	"os"

	"github.com/ProjectDistribute/distributor/middleware"
	"github.com/golang-jwt/jwt/v5"
	echojwt "github.com/labstack/echo-jwt/v4"
	"github.com/labstack/echo/v4"
)

func (h *Handler) Register(public *echo.Group) {
	Handle := middleware.Handle
	AdminMiddleware := middleware.AdminMiddleware

	secret := h.user_svc.JWTSecret

	config := echojwt.Config{
		NewClaimsFunc: func(c echo.Context) jwt.Claims {
			return new(middleware.JwtCustomClaims)
		},
		SigningKey: []byte(secret),
	}
	jwt := echojwt.WithConfig(config)

	// Setup
	public.GET("/setup/status", h.SetupStatus)
	public.POST("/setup/complete", h.CompleteSetup)

	info := public.Group("/info")
	info.GET("/health", h.HealthCheckHandler)
	info.GET("", h.GetServerInfo)

	users := public.Group("/users")
	users.GET("/me", h.GetMe, jwt)
	users.POST("/signup", h.CreateUser)
	users.POST("/login", h.LoginUser)
	user := users.Group("/:user_id", jwt)
	user.DELETE("", Handle(h.DeleteUser))

	library := user.Group("/library")
	library.GET("", Handle(h.GetLibrary))
	user.PUT("/password", h.ChangePassword)
	user.GET("/sync", Handle(h.GetSync))
	folders := user.Group("/folders")
	folders.POST("", Handle(h.CreatePlaylistFolder))
	folders.DELETE("/:folder_id", Handle(h.DeletePlaylistFolder))
	folders.PATCH("/:folder_id/rename", Handle(h.RenamePlaylistFolder))
	folders.PATCH("/:folder_id/move", Handle(h.MoveFolderToFolder))
	folders.POST("/batch", Handle(h.GetFoldersBatch))

	playlists := user.Group("/playlists")
	playlists.GET("", Handle(h.GetUserPlaylists))
	playlists.POST("", Handle(h.CreatePlaylist))
	playlists.POST("/batch", Handle(h.GetPlaylistsBatch))

	playlist := playlists.Group("/:playlist_id")
	playlist.GET("", Handle(h.GetPlaylist))
	playlist.DELETE("", Handle(h.DeletePlaylist))
	playlist.PATCH("/rename", Handle(h.RenamePlaylist))
	playlist.PATCH("/move", Handle(h.MovePlaylistToFolder))
	playlist.POST("/songs", Handle(h.AddSongToPlaylist))
	playlist.POST("/create-with-contents", Handle(h.CreatePlaylistWithContents))
	playlist.DELETE("/songs/:song_id", Handle(h.RemoveSongFromPlaylist))
	playlist.PUT("/songs/:song_id", Handle(h.UpdatePlaylistSongOrder))

	songs := public.Group("/songs")
	songs.GET("", h.GetSongs)
	songs.POST("/batch", h.GetSongsBatch)
	songs.POST("", h.CreateSong, jwt, AdminMiddleware)
	songs.DELETE("/:id", h.DeleteSong, jwt, AdminMiddleware)
	songs.PUT("/:id", h.UpdateSong, jwt, AdminMiddleware)
	songs.GET("/:id/files", h.GetSongFiles)
	songs.DELETE("/files/:id", h.DeleteSongFile, jwt, AdminMiddleware)
	songs.GET("/download/:file_id", Handle(h.DownloadFile))
	songs.POST("/assign-file", h.AssignFileToSong, jwt, AdminMiddleware)
	songs.POST("/assign-file-by-path", h.AssignFileToSongByPath, jwt, AdminMiddleware)
	songs.GET("/:id", h.GetSong)

	public.GET("/search", h.SearchItems)

	artist := public.Group("/artists")
	artist.POST("/batch", h.GetArtistsBatch)
	artist.POST("", h.CreateArtist, jwt, AdminMiddleware)
	artist.POST("/aliases", h.AddArtistIdentifier, jwt, AdminMiddleware)
	artist.PUT("/:id", h.UpdateArtist, jwt, AdminMiddleware)
	artist.DELETE("/:id", h.DeleteArtist, jwt, AdminMiddleware)
	artist.GET("/:id", h.GetArtist)

	album := public.Group("/albums")
	album.POST("/batch", h.GetAlbumsBatch)
	album.POST("", h.CreateAlbum, jwt, AdminMiddleware)
	album.POST("/covers-by-path", h.AssignAlbumCoverByPath, jwt, AdminMiddleware)
	album.POST("/covers/:id", h.AssignAlbumCover, jwt, AdminMiddleware)
	album.GET("/covers/:id", h.AlbumHasCover)
	album.PUT("/:id", h.UpdateAlbum, jwt, AdminMiddleware)
	album.DELETE("/:id", h.DeleteAlbum, jwt, AdminMiddleware)
	album.GET("/:id", h.GetAlbum)
	album.GET("/:id/songs", h.GetAlbumSongs)

	mail := public.Group("/mails")
	mail.POST("", h.CreateRequestMail, jwt)
	mail.GET("/categories", h.GetCategories)

	mail_private := mail.Group("", jwt, AdminMiddleware)
	mail_private.GET("", h.GetRequestMails)
	mail_private.PUT("/:id/status", h.SetMailStatus)
	mail_private.GET("/next", h.GetNextRequestMail)

	images := public.Group("/images")
	images.GET("/covers/:id/:res", h.ServeAlbumCover)

	public.POST("/doctor", h.RunDoctor, jwt, AdminMiddleware)
	public.POST("/search/reindex", h.ReindexSearch, jwt, AdminMiddleware)

	// Global Playlist Endpoints
	globalPlaylists := public.Group("/playlists", jwt)
	globalPlaylists.GET("/:playlist_id", h.GetPlaylistByID)
	globalPlaylists.PUT("/:playlist_id", h.UpdatePlaylistByID)
	globalPlaylists.DELETE("/:playlist_id", h.DeletePlaylistByID)
	globalPlaylists.POST("/:playlist_id/songs", Handle(h.AddSongToPlaylist))
	globalPlaylists.DELETE("/:playlist_id/songs/:song_id", Handle(h.RemoveSongFromPlaylist))
	globalPlaylists.PUT("/:playlist_id/songs/:song_id", Handle(h.UpdatePlaylistSongOrder))
	globalPlaylists.PUT("/:playlist_id/move", Handle(h.MovePlaylistToFolder))

	admin := public.Group("/admin", jwt, AdminMiddleware)
	admin.GET("/stats", h.GetStats)
	admin.GET("/logs", h.GetServerLogs)
	admin.GET("/bandwidth", h.GetBandwidth)
	admin.GET("/users", h.GetUsers)
	admin.GET("/playlists", h.GetPlaylists)
	admin.GET("/artists", h.GetArtists)
	admin.GET("/albums", h.GetAlbums)
	admin.DELETE("/orphans", h.RemoveOrphans)
	admin.DELETE("/files/cleanup", h.CleanSongFiles)
	admin.GET("/settings", h.GetSettings)
	admin.PUT("/settings", h.UpdateSettings)
	// admin.POST("/rebalance-playlists", Handle(h.RebalanceAllPlaylists))
}

func getJWTSecret() string {
	secretPath := "data/db/jwt_secret"
	content, err := os.ReadFile(secretPath)
	if err == nil {
		return string(content)
	} else {
		// Generate new random secret
		bytes := make([]byte, 32)
		if _, err := rand.Read(bytes); err != nil {
			panic("failed to generate random secret: " + err.Error())
		}
		secret := hex.EncodeToString(bytes)
		if err := os.WriteFile(secretPath, []byte(secret), 0600); err != nil {
			log.Printf("Warning: Failed to persist JWT secret to %s: %v. Check permissions.\n", secretPath, err)
		} else {
			fmt.Println("Generated and persisted new JWT secret to data/db/jwt_secret")
		}
		return secret
	}
}
