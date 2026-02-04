package handler

import (
	"log"

	"github.com/ProjectDistribute/distributor/service"
	"github.com/ProjectDistribute/distributor/store"
	"gorm.io/gorm"
)

type Handler struct {
	version      string
	db           *gorm.DB
	song_svc     *service.SongService
	mail_svc     *service.MailService
	artist_svc   *service.ArtistService
	album_svc    *service.AlbumService
	user_svc     *service.UserService
	playlist_svc *service.PlaylistService
	search_svc   *service.SearchService
	stats_svc    *service.StatsService
	settings_svc *store.SettingsStore
}

func NewHandler(
	version string,
	db *gorm.DB,
	song_svc *service.SongService,
	mail_svc *service.MailService,
	artist_svc *service.ArtistService,
	album_svc *service.AlbumService,
	user_svc *service.UserService,
	playlist_svc *service.PlaylistService,
	search_svc *service.SearchService,
	stats_svc *service.StatsService,
	settings_svc *store.SettingsStore,
) *Handler {
	return &Handler{
		version:      version,
		db:           db,
		song_svc:     song_svc,
		mail_svc:     mail_svc,
		artist_svc:   artist_svc,
		album_svc:    album_svc,
		user_svc:     user_svc,
		playlist_svc: playlist_svc,
		search_svc:   search_svc,
		stats_svc:    stats_svc,
		settings_svc: settings_svc,
	}
}

func GigaHandler(d *gorm.DB, storage service.FileStorage, version string) *Handler {
	// Stores
	song_store := store.NewSongStore(d)
	mail_store := store.NewMailStore(d)
	artist_store := store.NewArtistStore(d)
	album_store := store.NewAlbumStore(d)
	user_store := store.NewUserStore(d)
	playlist_store := store.NewPlaylistStore(d)
	settings_store := store.NewSettingsStore(d)

	// One-time backfill for playlist ordering
	if err := playlist_store.BackfillPlaylistOrder(); err != nil {
		log.Printf("Failed to backfill playlist order: %v\n", err)
	}

	// Services
	search_svc, _ := service.NewSearchService()
	mail_svc := service.NewMailService(mail_store, settings_store)
	artist_svc := &service.ArtistService{Store: artist_store, SearchSvc: search_svc}
	album_svc := &service.AlbumService{Store: album_store, Storage: storage, SearchSvc: search_svc}
	song_svc := &service.SongService{Store: song_store, Storage: storage, ArtistSvc: artist_svc, AlbumSvc: album_svc, SearchSvc: search_svc}
	playlist_svc := &service.PlaylistService{Store: playlist_store, SearchSvc: search_svc}
	stats_svc := service.NewStatsService()

	secret := getJWTSecret()
	user_svc := &service.UserService{Store: user_store, PlaylistService: playlist_svc, JWTSecret: secret}

	// // Handlers
	h := NewHandler(version, d, song_svc, mail_svc, artist_svc, album_svc, user_svc, playlist_svc, search_svc, stats_svc, settings_store)
	return h
}
