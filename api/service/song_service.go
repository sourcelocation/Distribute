package service

import (
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/ProjectDistribute/distributor/store"
	"github.com/google/uuid"
	"github.com/mewkiz/flac"
	"github.com/tcolgate/mp3"
)

type FileStorage interface {
	Save(path string, r io.Reader) error
	Exists(path string) bool
	Delete(path string) error
	Move(src, dst string) error
}

type SongService struct {
	Store     *store.SongStore
	Storage   FileStorage
	ArtistSvc *ArtistService
	AlbumSvc  *AlbumService
	SearchSvc *SearchService
}

type SongCreationArtist struct {
	Name       string `json:"name" validate:"required"`
	Identifier string `json:"id" validate:"required"`
}

func (s *SongService) CreateSong(title string, artistsInput []SongCreationArtist, albumTitle string, albumID uuid.UUID) (*model.Song, error) {
	// Resolve all artists
	artists, err := s.resolveArtists(artistsInput)
	if err != nil {
		return nil, err
	}

	if len(artists) == 0 {
		return nil, fmt.Errorf("at least one artist is required")
	}

	var album *model.Album

	if albumID != uuid.Nil {
		album, err = s.AlbumSvc.GetAlbumByID(albumID)
		if err != nil {
			return nil, fmt.Errorf("album not found: %w", err)
		}
	} else {
		// Fallback to title-based lookup/create
		if albumTitle == "" {
			return nil, fmt.Errorf("either album_id or album_title is required")
		}
		album, err = s.AlbumSvc.GetOrCreateAlbum(albumTitle, artists)
		if err != nil {
			return nil, err
		}
	}

	existingSong, err := s.Store.GetSongByTitleAndAlbumID(title, album.ID)
	if err != nil {
		return nil, err
	}
	if existingSong != nil {
		log.Printf("Song %s already exists in album %s\n", title, album.Title)
		return existingSong, fmt.Errorf("song '%s' already exists in album '%s'", title, album.Title)
	}

	song := &model.Song{
		Title:   title,
		AlbumID: album.ID,
		Artists: artists,
	}
	log.Printf("Creating song %s\n", song.Title)
	if err := s.Store.CreateSong(song); err != nil {
		return nil, err
	}

	song.Album = *album

	if err := s.SearchSvc.IndexSong(song); err != nil {
		log.Printf("Error indexing song %s: %v\n", song.ID, err)
	}

	// Re-index album to update its artist name (sub) in search
	if song.AlbumID != uuid.Nil {
		fullAlbum, err := s.AlbumSvc.GetAlbumByID(song.AlbumID)
		if err == nil {
			_ = s.SearchSvc.IndexAlbum(fullAlbum)
		}
	}

	return song, nil
}

func (s *SongService) UpdateSong(songID uuid.UUID, title string, artistsInput []SongCreationArtist, albumTitle string, albumID uuid.UUID) (*model.Song, error) {
	song, err := s.Store.GetSongByID(songID)
	if err != nil {
		return nil, fmt.Errorf("song not found")
	}

	// Update title
	if title != "" {
		song.Title = title
	}

	// Update Artists if provided
	if artistsInput != nil {
		artists, err := s.resolveArtists(artistsInput)
		if err != nil {
			return nil, err
		}
		if len(artists) > 0 {
			if err := s.Store.UpdateSongArtists(song, artists); err != nil {
				return nil, fmt.Errorf("failed to update artists: %v", err)
			}
		}
	}

	// Update Album if provided
	if albumID != uuid.Nil {
		if song.AlbumID != albumID {
			album, err := s.AlbumSvc.GetAlbumByID(albumID)
			if err != nil {
				return nil, fmt.Errorf("album not found: %w", err)
			}
			song.AlbumID = album.ID
			song.Album = *album
		}
	} else if albumTitle != "" && albumTitle != song.Album.Title {
		var currentArtists []model.Artist
		if artistsInput != nil {
			// TODO: Is this needed?
			reloadedSong, _ := s.Store.GetSongByID(song.ID)
			currentArtists = reloadedSong.Artists
		} else {
			currentArtists = song.Artists
		}

		album, err := s.AlbumSvc.GetOrCreateAlbum(albumTitle, currentArtists)
		if err != nil {
			return nil, err
		}
		song.AlbumID = album.ID
		song.Album = *album
	}

	if err := s.Store.UpdateSong(song); err != nil {
		return nil, err
	}

	// TODO: We are indexing only songs. Index albums and artists too.
	if err := s.SearchSvc.IndexSong(song); err != nil {
		log.Printf("Error re-indexing song %s: %v\n", song.ID, err)
	}

	// Re-index album to update its artist name (sub) in search
	if song.AlbumID != uuid.Nil {
		fullAlbum, err := s.AlbumSvc.GetAlbumByID(song.AlbumID)
		if err == nil {
			_ = s.SearchSvc.IndexAlbum(fullAlbum)
		}
	}

	return song, nil
}

func (s *SongService) AssignFileToSong(songID uuid.UUID, format string, data io.Reader) (*model.SongFile, error) {
	song, err := s.Store.GetSongByID(songID)
	if err != nil {
		return nil, fmt.Errorf("song not found")
	}

	sf := model.SongFile{SongID: song.ID, Format: format}

	if err := s.Storage.Save(sf.FilePath(), data); err != nil {
		return nil, fmt.Errorf("failed to save song file")
	}

	duration, err := s.ProbeDuration(sf.FilePath())
	if err != nil {
		_ = s.Storage.Delete(sf.FilePath())
		return nil, fmt.Errorf("failed to probe song file duration: %v", err)
	}
	sf.Duration = uint(duration * 1000)

	if err := s.Store.CreateSongFile(&sf); err != nil {
		return nil, fmt.Errorf("failed to create song file record")
	}

	return &sf, nil
}

func (s *SongService) AssignFileToSongByPath(songID uuid.UUID, sourcePath string) (*model.SongFile, error) {
	song, err := s.Store.GetSongByID(songID)
	if err != nil {
		return nil, fmt.Errorf("song not found")
	}

	ext := strings.TrimPrefix(filepath.Ext(sourcePath), ".")
	if ext == "" {
		return nil, fmt.Errorf("could not determine file format from path")
	}
	allowed := map[string]bool{
		"mp3":  true,
		"flac": true,
		"wav":  true,
		"ogg":  true,
		"m4a":  true,
	}
	if !allowed[ext] {
		return nil, fmt.Errorf("unsupported file format: %s", ext)
	}

	sf := model.SongFile{SongID: song.ID, Format: ext}
	destPath := sf.FilePath()

	if err := s.Storage.Move(sourcePath, destPath); err != nil {
		return nil, fmt.Errorf("failed to move song file: %v", err)
	}

	duration, err := s.ProbeDuration(destPath)
	if err != nil {
		_ = s.Storage.Delete(destPath)
		return nil, fmt.Errorf("failed to probe song file duration: %v", err)
	}
	sf.Duration = uint(duration * 1000)

	if err := s.Store.CreateSongFile(&sf); err != nil {
		return nil, fmt.Errorf("failed to create song file record")
	}

	return &sf, nil
}

func (s *SongService) DeleteSong(songID uuid.UUID) error {
	song, err := s.Store.GetSongByID(songID)
	if err != nil {
		return fmt.Errorf("song not found")
	}

	_ = s.Store.DeleteSong(song)
	// Auto-delete logic removed to allow empty albums in admin panel

	if err := s.SearchSvc.DeleteDocument(songID); err != nil {
		log.Printf("Error removing song %s from index: %v\n", songID, err)
	}

	return nil
}

func (s *SongService) DeleteSongFile(fileID uuid.UUID) error {
	file, err := s.Store.GetFileByID(fileID)
	if err != nil {
		return fmt.Errorf("file not found")
	}

	// Delete from storage
	path := file.FilePath()
	if err := s.Storage.Delete(path); err != nil {
		log.Printf("Warning: failed to delete file from storage %s: %v\n", path, err)
		// We continue to delete from DB even if storage delete fails (maybe file missing)
	}

	// Delete from DB
	if err := s.Store.DeleteSongFile(fileID); err != nil {
		return fmt.Errorf("failed to delete song file record: %v", err)
	}

	return nil
}

func (s *SongService) GetSongFiles(songID uuid.UUID) ([]model.SongFile, error) {
	return s.Store.GetSongFilesBySongID(songID)
}

func (s *SongService) GetSongsByAlbumID(albumID uuid.UUID) ([]model.Song, error) {
	return s.Store.GetSongsByAlbumID(albumID)
}

func (s *SongService) ProbeDuration(path string) (float64, error) {
	f, err := os.Open(path)
	if err != nil {
		return 0, err
	}
	defer f.Close()

	ext := strings.ToLower(filepath.Ext(path))
	switch ext {
	case ".mp3":
		d := mp3.NewDecoder(f)
		var duration float64
		var frame mp3.Frame
		var skipped int
		for {
			if err := d.Decode(&frame, &skipped); err != nil {
				if err == io.EOF {
					break
				}
				break
			}
			duration += frame.Duration().Seconds()
		}
		return duration, nil

	case ".flac":
		stream, err := flac.Parse(f)
		if err != nil {
			return 0, err
		}
		if stream.Info.SampleRate == 0 {
			return 0, nil
		}
		return float64(stream.Info.NSamples) / float64(stream.Info.SampleRate), nil

	default:
		// Unsupported format for duration probing
		log.Printf("Warning: Duration probing not supported for %s\n", ext)
		return 0, nil
	}
}

func (s *SongService) resolveArtists(artistsInput []SongCreationArtist) ([]model.Artist, error) {
	var artists []model.Artist
	for _, a := range artistsInput {
		var artist *model.Artist
		var err error

		// Try to parse as UUID first
		if id, uuidErr := uuid.Parse(a.Identifier); uuidErr == nil {
			artist, err = s.ArtistSvc.Store.GetArtistByID(id)
			if err == nil {
				log.Printf("Artist %s found by ID, using existing artist\n", a.Name)
			} else {
				artist = nil
			}
		}

		if artist == nil {
			artist, err = s.ArtistSvc.GetArtistByIdentifier(a.Identifier)
			if err != nil {
				log.Printf("Artist %s not found, creating new artist\n", a.Name)
				artist, err = s.ArtistSvc.CreateArtist(a.Name, []string{a.Identifier})
				if err != nil {
					return nil, err
				}
			} else {
				log.Printf("Artist %s found, using existing artist\n", a.Name)
			}
		}
		artists = append(artists, *artist)
	}
	return artists, nil
}
