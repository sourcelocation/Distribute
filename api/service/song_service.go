package service

import (
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/ProjectDistribute/distributor/store"
	"github.com/ProjectDistribute/distributor/utils"
	"github.com/google/uuid"
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
	Transcode *TranscodeService
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

func (s *SongService) AssignFileToSong(songID uuid.UUID, format string, data io.Reader) ([]model.SongFile, error) {
	song, err := s.Store.GetSongByID(songID)
	if err != nil {
		return nil, fmt.Errorf("song not found")
	}

	if err := s.removeAllSongFiles(song.ID); err != nil {
		return nil, fmt.Errorf("failed to remove existing song files: %v", err)
	}

	tmpFile, err := os.CreateTemp("", "upload-*."+format)
	if err != nil {
		return nil, fmt.Errorf("failed to create temp file: %v", err)
	}
	tmpPath := tmpFile.Name()
	defer os.Remove(tmpPath)

	if _, err := io.Copy(tmpFile, data); err != nil {
		tmpFile.Close()
		return nil, fmt.Errorf("failed to buffer upload: %v", err)
	}
	if err := tmpFile.Close(); err != nil {
		return nil, fmt.Errorf("failed to finalize upload buffer: %v", err)
	}

	sourceFile, err := s.storeSourceFile(song.ID, tmpPath, format)
	if err != nil {
		return nil, err
	}
	files, err := s.transcodeFromPath(song.ID, sourceFile.FilePath(), nil)
	if err != nil {
		return nil, err
	}
	return files, nil
}

func (s *SongService) AssignFileToSongByPath(songID uuid.UUID, sourcePath string) ([]model.SongFile, error) {
	song, err := s.Store.GetSongByID(songID)
	if err != nil {
		return nil, fmt.Errorf("song not found")
	}

	if err := s.removeAllSongFiles(song.ID); err != nil {
		return nil, fmt.Errorf("failed to remove existing song files: %v", err)
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

	sourceFile, err := s.storeSourceFile(song.ID, sourcePath, ext)
	if err != nil {
		return nil, err
	}

	files, err := s.transcodeFromPath(song.ID, sourceFile.FilePath(), nil)
	if err != nil {
		return nil, err
	}
	return files, nil
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

func (s *SongService) removeAllSongFiles(songID uuid.UUID) error {
	files, err := s.Store.GetSongFilesBySongID(songID)
	if err != nil {
		return err
	}
	for _, file := range files {
		if err := s.DeleteSongFile(file.ID); err != nil {
			return err
		}
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
	cmd := exec.Command(
		"ffprobe",
		"-v",
		"error",
		"-show_entries",
		"format=duration",
		"-of",
		"default=nw=1:nk=1",
		path,
	)
	output, err := cmd.Output()
	if err != nil {
		return 0, err
	}
	value := strings.TrimSpace(string(output))
	if value == "" {
		return 0, fmt.Errorf("empty duration output")
	}
	return strconv.ParseFloat(value, 64)
}

func (s *SongService) ComputeBitrateKbps(size int64, durationMs uint) int {
	if size <= 0 || durationMs == 0 {
		return 0
	}
	seconds := float64(durationMs) / 1000.0
	if seconds <= 0 {
		return 0
	}
	return int(float64(size*8) / 1000.0 / seconds)
}

func (s *SongService) transcodeFromPath(
	songID uuid.UUID,
	sourcePath string,
	overrideProfiles []TranscodeProfile,
) ([]model.SongFile, error) {
	if s.Transcode == nil {
		return nil, fmt.Errorf("transcode service not configured")
	}
	// Resolve which profiles to build (override or active profiles for the source).
	settings := s.Transcode.GetSettings()
	profiles := overrideProfiles
	if profiles == nil {
		profiles = s.Transcode.ActiveProfiles(settings)
	}
	if len(profiles) == 0 {
		return nil, fmt.Errorf("no transcode profiles enabled")
	}

	// Probe duration once to avoid re-reading the source for each profile.
	duration, err := s.ProbeDuration(sourcePath)
	if err != nil {
		return nil, fmt.Errorf("failed to probe source duration: %v", err)
	}
	durationMs := uint(duration * 1000)
	sourceLossless := IsLosslessSourcePath(sourcePath)
	sourceBitrateKbps := 0
	if info, statErr := os.Stat(sourcePath); statErr == nil {
		sourceBitrateKbps = s.ComputeBitrateKbps(info.Size(), durationMs)
	}

	profiles = s.Transcode.FilterProfilesForSource(profiles, sourceLossless, sourceBitrateKbps)
	if len(profiles) == 0 {
		return []model.SongFile{}, nil
	}

	// Load existing variant records to update-in-place where possible.
	existingFiles, _ := s.Store.GetSongFilesBySongID(songID)
	existingByVariant := map[string]model.SongFile{}
	for _, file := range existingFiles {
		if file.Variant == "" {
			continue
		}
		existingByVariant[file.Variant] = file
	}

	var results []model.SongFile
	for _, profile := range profiles {
		// Build or update the DB record for this variant.
		sf := model.SongFile{
			SongID:   songID,
			Format:   profile.Format,
			Codec:    profile.Codec,
			Variant:  profile.Variant,
			Duration: durationMs,
		}
		if existing, ok := existingByVariant[profile.Variant]; ok {
			sf.ID = existing.ID
			sf.CreatedAt = existing.CreatedAt
			sf.UpdatedAt = time.Now()
		} else {
			sf.ID = uuid.New()
		}
		// Ensure destination exists, then run ffmpeg and persist size/bitrate.
		destPath := sf.FilePath()
		if err := os.MkdirAll(filepath.Dir(destPath), 0o755); err != nil {
			return nil, fmt.Errorf("failed to prepare storage: %v", err)
		}
		if err := s.Transcode.Transcode(sourcePath, destPath, profile); err != nil {
			return nil, fmt.Errorf("failed to transcode %s: %v", profile.Variant, err)
		}

		if info, statErr := os.Stat(destPath); statErr == nil {
			sf.Size = info.Size()
		}
		sf.Bitrate = s.ComputeBitrateKbps(sf.Size, sf.Duration)

		if _, ok := existingByVariant[profile.Variant]; ok {
			if err := s.Store.UpdateSongFile(&sf); err != nil {
				return nil, fmt.Errorf("failed to update song file record: %v", err)
			}
		} else {
			if err := s.Store.CreateSongFile(&sf); err != nil {
				return nil, fmt.Errorf("failed to create song file record: %v", err)
			}
		}

		results = append(results, sf)
	}
	return results, nil
}

func (s *SongService) storeSourceFile(
	songID uuid.UUID,
	sourcePath string,
	format string,
) (model.SongFile, error) {
	if s.Storage == nil {
		return model.SongFile{}, fmt.Errorf("storage not configured")
	}

	duration, err := s.ProbeDuration(sourcePath)
	if err != nil {
		return model.SongFile{}, fmt.Errorf("failed to probe source duration: %v", err)
	}
	durationMs := uint(duration * 1000)

	var size int64
	if info, statErr := os.Stat(sourcePath); statErr == nil {
		size = info.Size()
	}

	existingFiles, _ := s.Store.GetSongFilesBySongID(songID)
	var existing *model.SongFile
	for i, file := range existingFiles {
		if file.Variant == VariantSource {
			existing = &existingFiles[i]
			break
		}
	}

	sf := model.SongFile{
		ID:       uuid.New(),
		SongID:   songID,
		Format:   format,
		Variant:  VariantSource,
		Duration: durationMs,
		Size:     size,
	}
	if existing != nil {
		sf.ID = existing.ID
		sf.CreatedAt = existing.CreatedAt
	}
	sf.Bitrate = s.ComputeBitrateKbps(sf.Size, sf.Duration)

	destPath := sf.FilePath()
	if sourcePath != destPath {
		if moveErr := s.Storage.Move(sourcePath, destPath); moveErr != nil {
			fh, openErr := os.Open(sourcePath)
			if openErr != nil {
				return model.SongFile{}, fmt.Errorf("failed to open source file: %v", openErr)
			}
			defer fh.Close()
			if saveErr := s.Storage.Save(destPath, fh); saveErr != nil {
				return model.SongFile{}, fmt.Errorf("failed to save source file: %v", saveErr)
			}
			if removeErr := os.Remove(sourcePath); removeErr != nil {
				log.Printf("Warning: failed to delete source file after copy: %v\n", removeErr)
			}
		}
	}

	if existing != nil && existing.FilePath() != destPath {
		_ = s.Storage.Delete(existing.FilePath())
	}

	if existing != nil {
		if err := s.Store.UpdateSongFile(&sf); err != nil {
			return model.SongFile{}, fmt.Errorf("failed to update source file record: %v", err)
		}
	} else {
		if err := s.Store.CreateSongFile(&sf); err != nil {
			return model.SongFile{}, fmt.Errorf("failed to create source file record: %v", err)
		}
	}

	return sf, nil
}

func (s *SongService) TranscodeFromPath(
	songID uuid.UUID,
	sourcePath string,
	profiles []TranscodeProfile,
) ([]model.SongFile, error) {
	return s.transcodeFromPath(songID, sourcePath, profiles)
}

func (s *SongService) EnsureStreamableHighestQuality(song model.Song) (int, bool, error) {
	source, sourcePath, ok := s.resolveTranscodeSource(song)
	if !ok {
		return 0, false, nil
	}
	if isStreamableFormat(source.Format) {
		return 0, false, nil
	}

	duration, err := s.ProbeDuration(sourcePath)
	if err != nil {
		return 0, false, err
	}
	durationMs := uint(duration * 1000)
	sourceBitrateKbps := 0
	if info, statErr := os.Stat(sourcePath); statErr == nil {
		sourceBitrateKbps = s.ComputeBitrateKbps(info.Size(), durationMs)
	}

	settings := s.Transcode.GetSettings()
	profile := s.Transcode.HighestQualityProfile(
		settings,
		IsLosslessSourceFile(*source),
		sourceBitrateKbps,
	)
	if profile == nil {
		return 0, false, nil
	}

	files, err := s.TranscodeFromPath(song.ID, sourcePath, []TranscodeProfile{*profile})
	if err != nil {
		return 0, false, err
	}

	return len(files), true, nil
}

func (s *SongService) EnsureMissingTranscodes(song model.Song) (int, bool, error) {
	source, sourcePath, ok := s.resolveTranscodeSource(song)
	if !ok {
		return 0, false, nil
	}

	settings := s.Transcode.GetSettings()

	duration, err := s.ProbeDuration(sourcePath)
	if err != nil {
		return 0, false, err
	}
	durationMs := uint(duration * 1000)
	sourceBitrateKbps := 0
	if info, statErr := os.Stat(sourcePath); statErr == nil {
		sourceBitrateKbps = s.ComputeBitrateKbps(info.Size(), durationMs)
	}

	profiles := s.Transcode.ProfilesForSource(
		settings,
		IsLosslessSourceFile(*source),
		sourceBitrateKbps,
	)
	missing := MissingOrMismatchedProfiles(song.SongFiles, profiles)
	if len(missing) == 0 {
		return 0, false, nil
	}

	if _, err := s.TranscodeFromPath(song.ID, sourcePath, missing); err != nil {
		return 0, false, err
	}
	return len(missing), true, nil
}

func (s *SongService) ResolveSongFilePath(file model.SongFile) (string, bool) {
	path := file.FilePath()
	if s.Storage == nil {
		return resolveLocalSongFilePath(path, file.LegacyFilePath())
	}
	if s.Storage.Exists(path) {
		return path, true
	}
	legacy := file.LegacyFilePath()
	if s.Storage.Exists(legacy) {
		if err := s.Storage.Move(legacy, path); err == nil {
			return path, true
		}
		return legacy, true
	}
	return "", false
}

func (s *SongService) resolveTranscodeSource(song model.Song) (*model.SongFile, string, bool) {
	if len(song.SongFiles) == 0 || s.Transcode == nil {
		return nil, "", false
	}
	source := SelectBestSourceFile(song.SongFiles)
	if source == nil {
		return nil, "", false
	}
	sourcePath, ok := s.ResolveSongFilePath(*source)
	if !ok {
		return nil, "", false
	}
	return source, sourcePath, true
}

func resolveLocalSongFilePath(path, legacy string) (string, bool) {
	if fileExists(path) {
		return path, true
	}
	if fileExists(legacy) {
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err == nil {
			if err := os.Rename(legacy, path); err == nil {
				return path, true
			}
		}
		return legacy, true
	}
	return "", false
}

func isStreamableFormat(format string) bool {
	return utils.AudioContentType(format) != "application/octet-stream"
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
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
