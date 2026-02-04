package service

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"image"
	"image/jpeg"
	"image/png"
	"io"
	"log"
	"os"
	"strings"
	"time"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/ProjectDistribute/distributor/store"

	"github.com/google/uuid"

	"github.com/disintegration/imaging"
)

type AlbumService struct {
	Store     *store.AlbumStore
	Storage   FileStorage
	SearchSvc *SearchService
}

func (s *AlbumService) createAlbumFromModel(album *model.Album) error {
	if _, err := s.Store.CreateAlbum(album); err != nil {
		return err
	}
	_ = s.SearchSvc.IndexAlbum(album)
	return nil
}

func (s *AlbumService) UpdateAlbum(id uuid.UUID, title string, releaseDate time.Time) (*model.Album, error) {
	album, err := s.Store.GetAlbumByID(id)
	if err != nil {
		return nil, err
	}
	if title != "" {
		album.Title = title
	}
	if !releaseDate.IsZero() {
		album.ReleaseDate = releaseDate
	}
	if err := s.Store.UpdateAlbum(album); err != nil {
		return nil, err
	}
	_ = s.SearchSvc.IndexAlbum(album)
	return album, nil
}

func (s *AlbumService) CreateAlbum(title string, releaseDate time.Time, artistName string) (*model.Album, error) {
	album := &model.Album{
		Title:       title,
		ReleaseDate: releaseDate,
	}

	createdAlbum, err := s.Store.CreateAlbum(album)
	if err != nil {
		return nil, err
	}

	if err := s.SearchSvc.IndexAlbum(createdAlbum); err != nil {
		log.Printf("Error indexing album %s: %v\n", createdAlbum.ID, err)
	}

	return createdAlbum, nil
}

func (s *AlbumService) GetOrCreateAlbum(title string, artists []model.Artist) (*model.Album, error) {
	albums, err := s.Store.GetAlbumsByTitle(title)
	if err != nil {
		return nil, err
	}

	for _, album := range albums {
		if len(album.Songs) == 0 {
			return &album, nil
		}
		for _, song := range album.Songs {
			for _, songArtist := range song.Artists {
				for _, artist := range artists {
					if songArtist.ID == artist.ID {
						log.Printf("Album %s found, using existing album\n", album.Title)
						return &album, nil
					}
				}
			}
		}
	}

	log.Printf("Album %s not found, creating new album\n", title)
	newAlbum := &model.Album{Title: title}
	if err := s.createAlbumFromModel(newAlbum); err != nil {
		return nil, err
	}
	return newAlbum, nil
}

func (s *AlbumService) GetAlbumByID(uuid uuid.UUID) (*model.Album, error) {
	return s.Store.GetAlbumByID(uuid)
}

func (s *AlbumService) DeleteAlbum(album *model.Album) error {
	if err := s.Store.DeleteAlbum(album); err != nil {
		return err
	}
	_ = s.SearchSvc.DeleteDocument(album.ID)
	return nil
}

func (s *AlbumService) WriteAlbumCover(albumID uuid.UUID, data io.Reader, id string, format string) error {
	buf := &bytes.Buffer{}
	if _, err := io.Copy(buf, data); err != nil {
		return err
	}

	pathMax := s.GetAlbumCoverPath(albumID, format, "hq")
	if err := s.Storage.Save(pathMax, bytes.NewReader(buf.Bytes())); err != nil {
		return err
	}

	pathLQ := s.GetAlbumCoverPath(albumID, format, "lq")
	return s.saveResizedCover(buf.Bytes(), pathLQ, format, 128, 128)
}

func (s *AlbumService) AssignAlbumCoverByPath(albumID uuid.UUID, sourcePath string, format string) error {
	pathMax := s.GetAlbumCoverPath(albumID, format, "hq")

	if err := s.Storage.Move(sourcePath, pathMax); err != nil {
		return err
	}

	// Read the file data for resizing
	data, err := os.ReadFile(pathMax)
	if err != nil {
		return fmt.Errorf("failed to read moved cover file: %w", err)
	}

	pathLQ := s.GetAlbumCoverPath(albumID, format, "lq")
	return s.saveResizedCover(data, pathLQ, format, 128, 128)
}

func (s *AlbumService) AlbumHasCover(albumID uuid.UUID, format string) bool {
	path := s.GetAlbumCoverPath(albumID, format, "hq")
	return s.Storage.Exists(path)
}

func (s *AlbumService) GetAlbumCoverPath(id uuid.UUID, format string, res string) string {
	sum := sha256.Sum256([]byte(id.String()))
	hexDigest := hex.EncodeToString(sum[:])
	path := fmt.Sprintf(
		"storage/album_covers/album_covers_%s/%s/%s/%s.%s",
		res,
		hexDigest[0:2],
		hexDigest[2:4],
		id,
		format,
	)
	return path
}

func (s *AlbumService) saveResizedCover(src []byte, path string, format string, width, height int) error {
	img, _, err := image.Decode(bytes.NewReader(src))
	if err != nil {
		return err
	}

	resized := imaging.Fill(img, width, height, imaging.Center, imaging.Lanczos)

	out := &bytes.Buffer{}
	switch strings.ToLower(format) {
	case "png":
		err = png.Encode(out, resized)
	default:
		err = jpeg.Encode(out, resized, &jpeg.Options{Quality: 85})
	}
	if err != nil {
		return err
	}

	return s.Storage.Save(path, bytes.NewReader(out.Bytes()))
}
