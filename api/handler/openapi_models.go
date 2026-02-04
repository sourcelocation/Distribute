package handler

import (
	"time"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/ProjectDistribute/distributor/service"
	"github.com/google/uuid"
)

type Song struct {
	ID        uuid.UUID `json:"id" example:"00000000-0000-0000-0000-000000000000"`
	CreatedAt time.Time `json:"created_at"`
	Title     string    `json:"title" example:"Song Title"`
	AlbumID   uuid.UUID `json:"album_id"`
	Album     Album     `json:"album"`
	Artists   []Artist  `json:"artists"`
}

type SongFile struct {
	ID        uuid.UUID `json:"id"`
	CreatedAt time.Time `json:"created_at"`
	Format    string    `json:"format"`
	Duration  uint      `json:"duration"`
}

type User struct {
	ID           uuid.UUID `json:"id"`
	Username     string    `json:"username"`
	IsAdmin      bool      `json:"is_admin"`
	RootFolderID uuid.UUID `json:"root_folder_id"`
}

type Playlist struct {
	ID            uuid.UUID              `json:"id"`
	Name          string                 `json:"name"`
	FolderID      uuid.UUID              `json:"folder_id"`
	UserID        uuid.UUID              `json:"user_id"`
	PlaylistSongs []PlaylistSongResponse `json:"playlist_songs"`
	// Songs     []Song    `json:"songs"`
	User      *User     `json:"user,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

type PlaylistSongResponse struct {
	SongID uuid.UUID `json:"song_id"`
	Order  string    `json:"order"`
}

type PlaylistFolder struct {
	ID        uuid.UUID         `json:"id"`
	Name      string            `json:"name"`
	UserID    uuid.UUID         `json:"user_id"`
	ParentID  *uuid.UUID        `json:"parent_id"`
	Children  []*PlaylistFolder `json:"children"`
	Playlists []Playlist        `json:"playlists"`
}

type Artist struct {
	ID          uuid.UUID          `json:"id"`
	Name        string             `json:"name"`
	Albums      []Album            `json:"albums"`
	Identifiers []ArtistIdentifier `json:"identifiers"`
	CreatedAt   time.Time          `json:"created_at"`
}

type ArtistIdentifier struct {
	ID         uuid.UUID `json:"id"`
	ArtistID   uuid.UUID `json:"artist_id"`
	Identifier string    `json:"identifier"`
}

type Album struct {
	ID          uuid.UUID `json:"id"`
	Title       string    `json:"title"`
	ReleaseDate time.Time `json:"release_date"`
	ArtistName  string    `json:"artist_name"` // Computed
	Songs       []Song    `json:"songs"`
	CreatedAt   time.Time `json:"created_at"`
}

type RequestMail struct {
	ID       uint      `json:"id"`
	Category string    `json:"category"`
	Message  string    `json:"message"`
	UserID   uuid.UUID `json:"user_id"`
	Status   int       `json:"status"`
}

func FromSongModel(m model.Song) Song {
	s := Song{
		ID:        m.ID,
		CreatedAt: m.CreatedAt,
		Title:     m.Title,
		AlbumID:   m.AlbumID,
		Album:     FromAlbumModel(m.Album),
	}
	if len(m.Artists) > 0 {
		s.Artists = make([]Artist, len(m.Artists))
		for i, a := range m.Artists {
			s.Artists[i] = FromArtistModel(a)
		}
	}
	return s
}

func FromSongFileModels(ms []model.SongFile) []SongFile {
	if ms == nil {
		return nil
	}
	files := make([]SongFile, len(ms))
	for i, m := range ms {
		files[i] = SongFile{
			ID:        m.ID,
			CreatedAt: m.CreatedAt,
			Format:    m.Format,
			Duration:  m.Duration,
		}
	}
	return files
}

func FromAlbumModel(m model.Album) Album {
	return Album{
		ID:          m.ID,
		CreatedAt:   m.CreatedAt,
		Title:       m.Title,
		ReleaseDate: m.ReleaseDate,
		ArtistName:  m.GetArtistName(),
	}
}

func FromArtistModel(m model.Artist) Artist {
	a := Artist{
		ID:        m.ID,
		CreatedAt: m.CreatedAt,
		Name:      m.Name,
	}
	if m.Identifiers != nil {
		a.Identifiers = make([]ArtistIdentifier, len(m.Identifiers))
		for i, id := range m.Identifiers {
			a.Identifiers[i] = ArtistIdentifier{
				ID:         id.ID,
				ArtistID:   id.ArtistID,
				Identifier: id.Identifier,
			}
		}
	}
	return a
}

func FromUserModel(m model.User, rootFolderID uuid.UUID) User {
	return User{
		ID:           m.ID,
		Username:     m.Username,
		IsAdmin:      m.IsAdmin,
		RootFolderID: rootFolderID,
	}
}

func FromPlaylistModel(m model.Playlist) Playlist {
	p := Playlist{
		ID:        m.ID,
		Name:      m.Name,
		FolderID:  m.FolderID,
		UserID:    m.UserID,
		CreatedAt: m.CreatedAt,
	}

	if m.PlaylistFolder != nil && m.PlaylistFolder.User.ID != uuid.Nil {
		u := FromUserModel(m.PlaylistFolder.User, uuid.Nil)
		p.User = &u
	}

	p.PlaylistSongs = make([]PlaylistSongResponse, len(m.PlaylistSongs))
	for i, s := range m.PlaylistSongs {
		p.PlaylistSongs[i] = PlaylistSongResponse{
			SongID: s.SongID,
			Order:  s.Order,
		}
	}
	return p
}

func FromPlaylistFolderModel(m model.PlaylistFolder) PlaylistFolder {
	f := PlaylistFolder{
		ID:       m.ID,
		Name:     m.Name,
		UserID:   m.UserID,
		ParentID: m.ParentID,
	}
	if m.Children != nil {
		f.Children = make([]*PlaylistFolder, len(m.Children))
		for i, c := range m.Children {
			cf := FromPlaylistFolderModel(*c)
			f.Children[i] = &cf
		}
	}
	if m.Playlists != nil {
		f.Playlists = make([]Playlist, len(m.Playlists))
		for i, p := range m.Playlists {
			f.Playlists[i] = FromPlaylistModel(p)
		}
	}
	return f
}

func FromRequestMailModel(m model.RequestMail) RequestMail {
	return RequestMail{
		ID:       m.ID,
		Category: m.Category,
		Message:  m.Message,
		UserID:   m.UserID,
		Status:   int(m.Status),
	}
}

// == Responses ==

type SignupResponse string
type ErrorResponse struct {
	Error string `json:"error" example:"Validation failed"`
}

type StatusResponse struct {
	Status string `json:"status" example:"ok"`
}

type MessageResponse struct {
	Message string `json:"message" example:"Status updated"`
}

type HealthResponse string

type ServerInfoResponse struct {
	Version                 string   `json:"version" example:"s0.0.4"`
	RequestMailAnnouncement string   `json:"request_mail_announcement" example:"Feel free to request more music!"`
	RequestMailCategories   []string `json:"request_mail_categories" example:"pop,rock"`
}

type GetSongsResponse struct {
	Songs []Song `json:"songs"`
}

type AlbumHasCoverResponse struct {
	HasCover bool `json:"has_cover" example:"true"`
}

type AssignAlbumCoverResponse struct {
	Status string `json:"status" example:"Cover assigned to album successfully"`
}

type AssignFileToSongResponse struct {
	Status string   `json:"status" example:"File assigned to song successfully"`
	File   SongFile `json:"file"`
}

type PlaylistResponse struct {
	ID             uuid.UUID `json:"id"`
	Name           string    `json:"name"`
	ParentFolderID uuid.UUID `json:"parent_folder_id"`
}

type FolderResponse struct {
	ID             uuid.UUID  `json:"id"`
	Name           string     `json:"name"`
	ParentFolderID *uuid.UUID `json:"parent_folder_id"`
}

type LibraryResponse struct {
	Folders   []FolderResponse   `json:"folders"`
	Playlists []PlaylistResponse `json:"playlists"`
}

type LoginResponse struct {
	Token    string    `json:"token" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."`
	Username string    `json:"username" example:"alice"`
	ID       uuid.UUID `json:"id" example:"00000000-0000-0000-0000-000000000000"`
}

type CategoriesResponse struct {
	Categories []string `json:"categories" example:"general,rock"`
}

// == Requests ==

type CompleteSetupRequest struct {
	Username                string `json:"username" validate:"required"`
	Password                string `json:"password" validate:"required"`
	ServerURL               string `json:"server_url" validate:"required,url"`
	MailCategories          string `json:"mail_categories"` // comma separated
	RequestMailAnnouncement string `json:"request_mail_announcement"`
}
type SignupRequest struct {
	Username string `json:"username" validate:"required" example:"alice"`
	Password string `json:"password" validate:"required" example:"correct horse battery staple"`
}

type LoginRequest struct {
	Username string `json:"username" validate:"required" example:"alice"`
	Password string `json:"password" validate:"required" example:"correct horse battery staple"`
}
type CreateSongRequest struct {
	Title      string                       `json:"title" validate:"required,max=255" example:"Song Title"`
	Artists    []service.SongCreationArtist `json:"artists" validate:"required,min=1"`
	AlbumTitle string                       `json:"album_title" example:"Abbey Road"`
	AlbumID    uuid.UUID                    `json:"album_id" example:"00000000-0000-0000-0000-000000000000"`
}

type CreateAlbumRequest struct {
	Title       string    `json:"title" validate:"required" example:"Dark Side of the Moon"`
	ReleaseDate time.Time `json:"release_date" example:"1973-03-01T00:00:00Z"`
}

type UpdateSongRequest struct {
	Title      string                       `json:"title" example:"Song Title"`
	Artists    []service.SongCreationArtist `json:"artists"`
	AlbumTitle string                       `json:"album_title" example:"Abbey Road"`
	AlbumID    uuid.UUID                    `json:"album_id" example:"00000000-0000-0000-0000-000000000000"`
}

type AssignFileToSongRequest struct {
	SongID uuid.UUID `json:"song_id" validate:"required" example:"00000000-0000-0000-0000-000000000000"`
	// File is provided as multipart form-data field `file`.
}

type AssignFileByPathRequest struct {
	SongID     uuid.UUID `json:"song_id" validate:"required" example:"00000000-0000-0000-0000-000000000000"`
	SourcePath string    `json:"source_path" validate:"required" example:"/app/storage/downloads/song.flac"`
}

type AssignAlbumCoverByPathRequest struct {
	AlbumID    uuid.UUID `json:"album_id" validate:"required" example:"00000000-0000-0000-0000-000000000000"`
	SourcePath string    `json:"source_path" validate:"required" example:"/app/storage/downloads/cover.jpg"`
}

type CreateArtistRequest struct {
	Name        string   `json:"name" validate:"required" example:"The Beatles"`
	Identifiers []string `json:"identifiers" validate:"required" example:"beatles,the-beatles"`
}

type AddArtistIdentifierRequest struct {
	ArtistID   int    `json:"artist_id" validate:"required" example:"1"`
	Identifier string `json:"identifier" validate:"required" example:"beatles"`
}

type CreateRequestMailRequest struct {
	Category string `json:"category" validate:"required" example:"general"`
	Message  string `json:"message" validate:"required" example:"Please add more jazz."`
}

type SetMailStatusRequest struct {
	Status int `json:"status" validate:"required" example:"2"`
}

type CreatePlaylistRequest struct {
	ID           uuid.UUID   `json:"id" validate:"required" example:"00000000-0000-0000-0000-000000000000"`
	Name         string      `json:"name" validate:"required" example:"My Playlist"`
	ParentFolder uuid.UUID   `json:"parent_folder_id" validate:"required" example:"00000000-0000-0000-0000-000000000000"`
	SongIDs      []uuid.UUID `json:"song_ids" example:"[\"00000000-0000-0000-0000-000000000000\"]"`
}

type CreatePlaylistFolderRequest struct {
	ID       uuid.UUID `json:"id" validate:"required" example:"00000000-0000-0000-0000-000000000000"`
	Name     string    `json:"name" validate:"required" example:"Favourites"`
	ParentID uuid.UUID `json:"parent_folder_id" validate:"required" example:"00000000-0000-0000-0000-000000000000"`
}

type AddSongToPlaylistRequest struct {
	SongID uuid.UUID `json:"song_id" validate:"required" example:"00000000-0000-0000-0000-000000000000"`
}

type RenamePlaylistRequest struct {
	Name string `json:"name" validate:"required" example:"New Name"`
}

type MovePlaylistRequest struct {
	TargetFolderID uuid.UUID `json:"parent_folder_id" validate:"required" example:"00000000-0000-0000-0000-000000000000"`
}

type RenameFolderRequest struct {
	Name string `json:"name" validate:"required" example:"New Folder Name"`
}

type MoveFolderRequest struct {
	TargetParentID *uuid.UUID `json:"parent_folder_id" validate:"required" example:"00000000-0000-0000-0000-000000000000"`
}

type BatchIDRequest struct {
	IDs []uuid.UUID `json:"ids" validate:"required"`
}

type UpdateAlbumRequest struct {
	Title       string    `json:"title"`
	ReleaseDate time.Time `json:"release_date"`
}

type UpdateArtistRequest struct {
	Name string `json:"name"`
}

type CreatePlaylistWithContentsRequest struct {
	UserID  uuid.UUID   `json:"user_id" validate:"required"`
	Name    string      `json:"name" validate:"required"`
	SongIDs []uuid.UUID `json:"song_ids" validate:"required"`
}
