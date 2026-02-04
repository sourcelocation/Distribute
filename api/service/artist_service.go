package service

import (
	"fmt"
	"log"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/ProjectDistribute/distributor/store"
	"github.com/google/uuid"
)

type ArtistService struct {
	Store     *store.ArtistStore
	SearchSvc *SearchService
}

func (s *ArtistService) GetArtistByIdentifier(identifier string) (*model.Artist, error) {
	return s.Store.GetArtistByIdentifier(identifier)
}

func (s *ArtistService) CreateArtist(name string, identifiers []string) (*model.Artist, error) {
	artist, err := s.Store.CreateArtist(&model.Artist{Name: name})
	if err != nil {
		return nil, err
	}
	// Create each identifier
	var idModels []model.ArtistIdentifier
	for _, id := range identifiers {
		identifier, err := s.Store.CreateArtistIdentifier(artist, id)
		if err != nil {
			return nil, err
		}
		idModels = append(idModels, *identifier)
	}

	// Index in Meilisearch
	_ = s.SearchSvc.IndexArtist(artist)

	return artist, nil
}

func (s *ArtistService) AddIdentifierToArtist(artistID uuid.UUID, identifier string) error {
	if identifier == "" {
		return fmt.Errorf("identifier is required")
	}
	artist, err := s.Store.GetArtistByID(artistID)
	if err != nil {
		return err
	}
	_, err = s.Store.CreateArtistIdentifier(artist, identifier)
	if err == nil {
		_ = s.SearchSvc.IndexArtist(artist)
	}
	return err
}

func (s *ArtistService) UpdateArtist(id uuid.UUID, name string) (*model.Artist, error) {
	artist, err := s.Store.GetArtistByID(id)
	if err != nil {
		return nil, err
	}
	if name != "" {
		artist.Name = name
	}
	if err := s.Store.UpdateArtist(artist); err != nil {
		return nil, err
	}
	if err := s.SearchSvc.IndexArtist(artist); err != nil {
		log.Printf("Error indexing artist %s: %v\n", artist.ID, err)
	}
	return artist, nil
}

func (s *ArtistService) DeleteArtist(id uuid.UUID) error {
	artist, err := s.Store.GetArtistByID(id)
	if err != nil {
		return err
	}
	if err := s.Store.DeleteArtist(artist); err != nil {
		return err
	}
	if err := s.SearchSvc.DeleteDocument(id); err != nil {
		log.Printf("Error removing artist %s from index: %v\n", id, err)
	}
	return nil
}
