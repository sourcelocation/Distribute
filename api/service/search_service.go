package service

import (
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/google/uuid"
	"github.com/meilisearch/meilisearch-go"
)

type SearchService struct {
	client meilisearch.ServiceManager
	index  meilisearch.IndexManager
}

type SearchArtist struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
}

type SearchResult struct {
	ID    uuid.UUID `json:"id"`
	Type  string    `json:"type"` // "song", "artist", "album", "playlist"
	Title string    `json:"title"`
	Sub   *string   `json:"sub,omitempty"` // Artist name for songs

	// For songs
	Artists    []SearchArtist `json:"artists,omitempty"`
	AlbumID    *uuid.UUID     `json:"album_id,omitempty"`
	AlbumTitle *string        `json:"album_title,omitempty"`
}

func NewSearchService() (*SearchService, error) {
	url := os.Getenv("MEILI_URL")
	if url == "" {
		url = "http://localhost:7700"
	}
	key := os.Getenv("MEILI_MASTER_KEY")
	if key == "" {
		key = "masterKey"
	}

	client := meilisearch.New(url, meilisearch.WithAPIKey(key))
	index := client.Index("music")

	go func() {
		// Retry connection to Meilisearch
		var healthErr error
		for i := 0; i < 60; i++ {
			_, healthErr = client.Health()
			if healthErr == nil {
				break
			}
			if i%60 == 0 {
				log.Printf("Waiting for Meilisearch... (%d/60)\n", i+1)
			}
			time.Sleep(1 * time.Second)
		}
		if healthErr != nil {
			fmt.Println("[!!!] COULD NOT CONNECT TO MEILISEARCH [!!!]")
			return
		}

		searchIndexResult, err := client.GetIndex("music")
		if err != nil || searchIndexResult == nil {
			_, err = client.CreateIndex(&meilisearch.IndexConfig{
				Uid:        "music",
				PrimaryKey: "id",
			})
			if err != nil {
				log.Printf("Failed to create index: %v\n", err)
			}
		}
		rankingRules := []string{
			"words",
			"typo",
			"proximity",
			"attribute",
			"sort",
			"exactness",
			"weight:desc",
		}
		// Prioritize "title" (Artist Name) over "sub" (Artist Name on Song)
		searchableAttributes := []string{"title", "sub", "type"}
		filterableAttributes := []string{"type"}
		sortableAttributes := []string{"weight"}

		_, err = index.UpdateSettings(&meilisearch.Settings{
			RankingRules:         rankingRules,
			SearchableAttributes: searchableAttributes,
			FilterableAttributes: filterableAttributes,
			SortableAttributes:   sortableAttributes,
		})
		if err != nil {
			log.Printf("Failed to update Meilisearch settings: %v\n", err)
		}
		fmt.Println("Meilisearch connected and configured.")
	}()

	return &SearchService{
		client: client,
		index:  index,
	}, nil
}

func (s *SearchService) songToDoc(song *model.Song) map[string]interface{} {
	doc := map[string]interface{}{
		"id":     song.ID,
		"type":   "song",
		"title":  song.Title,
		"weight": 4,
	}
	if len(song.Artists) > 0 {
		var artistNames []string
		var searchArtists []map[string]interface{}
		for _, a := range song.Artists {
			artistNames = append(artistNames, a.Name)
			searchArtists = append(searchArtists, map[string]interface{}{
				"id":   a.ID,
				"name": a.Name,
			})
		}
		doc["sub"] = strings.Join(artistNames, ", ")
		doc["artists"] = searchArtists
	}
	if song.Album.Title != "" {
		doc["album_title"] = song.Album.Title
	}
	if song.Album.ID != uuid.Nil {
		doc["album_id"] = song.Album.ID
	}
	return doc
}

func (s *SearchService) artistToDoc(artist *model.Artist) map[string]interface{} {
	doc := map[string]interface{}{
		"id":     artist.ID,
		"type":   "artist",
		"title":  artist.Name,
		"weight": 3,
	}
	if len(artist.Identifiers) > 0 {
		var ids []string
		for _, id := range artist.Identifiers {
			ids = append(ids, id.Identifier)
		}
		doc["sub"] = strings.Join(ids, ", ")
	}
	return doc
}

func (s *SearchService) albumToDoc(album *model.Album) map[string]interface{} {
	doc := map[string]interface{}{
		"id":     album.ID,
		"type":   "album",
		"title":  album.Title,
		"weight": 2,
	}
	// Use computed artist name for search
	if album.GetArtistName() != "" {
		doc["sub"] = album.GetArtistName()
	}
	return doc
}

func (s *SearchService) playlistToDoc(playlist *model.Playlist) map[string]interface{} {
	return map[string]interface{}{
		"id":     playlist.ID,
		"type":   "playlist",
		"title":  playlist.Name,
		"weight": 1,
	}
}

func (s *SearchService) IndexSong(song *model.Song) error {
	_, err := s.index.AddDocuments(s.songToDoc(song), nil)
	return err
}

func (s *SearchService) IndexArtist(artist *model.Artist) error {
	_, err := s.index.AddDocuments(s.artistToDoc(artist), nil)
	return err
}

func (s *SearchService) IndexAlbum(album *model.Album) error {
	_, err := s.index.AddDocuments(s.albumToDoc(album), nil)
	return err
}

func (s *SearchService) IndexPlaylist(playlist *model.Playlist) error {
	_, err := s.index.AddDocuments(s.playlistToDoc(playlist), nil)
	return err
}

func (s *SearchService) DeleteDocument(id uuid.UUID) error {
	_, err := s.index.DeleteDocument(id.String(), nil)
	return err
}

func (s *SearchService) DeleteAllDocuments() error {
	_, err := s.index.DeleteAllDocuments(nil)
	return err
}

func (s *SearchService) IndexSongs(songs []model.Song) error {
	docs := make([]map[string]interface{}, len(songs))
	for i, song := range songs {
		docs[i] = s.songToDoc(&song)
	}
	_, err := s.index.AddDocuments(docs, nil)
	return err
}

func (s *SearchService) IndexArtists(artists []model.Artist) error {
	docs := make([]map[string]interface{}, len(artists))
	for i, artist := range artists {
		docs[i] = s.artistToDoc(&artist)
	}
	_, err := s.index.AddDocuments(docs, nil)
	return err
}

func (s *SearchService) IndexAlbums(albums []model.Album) error {
	docs := make([]map[string]interface{}, len(albums))
	for i, album := range albums {
		docs[i] = s.albumToDoc(&album)
	}
	_, err := s.index.AddDocuments(docs, nil)
	return err
}

func (s *SearchService) IndexPlaylists(playlists []model.Playlist) error {
	docs := make([]map[string]interface{}, len(playlists))
	for i, playlist := range playlists {
		docs[i] = s.playlistToDoc(&playlist)
	}
	_, err := s.index.AddDocuments(docs, nil)
	return err
}

func (s *SearchService) Search(query string, limit int, filterType string) ([]SearchResult, error) {
	req := &meilisearch.SearchRequest{
		Limit: int64(limit),
	}
	if filterType != "" {
		req.Filter = fmt.Sprintf("type = \"%s\"", filterType)
	}

	resp, err := s.index.Search(query, req)
	if err != nil {
		return nil, err
	}

	results := make([]SearchResult, 0, len(resp.Hits))
	for _, hit := range resp.Hits {
		var res struct {
			ID         uuid.UUID      `json:"id"`
			Type       string         `json:"type"`
			Title      string         `json:"title"`
			Sub        *string        `json:"sub"`
			Artists    []SearchArtist `json:"artists"`
			AlbumID    *uuid.UUID     `json:"album_id"`
			AlbumTitle *string        `json:"album_title"`
		}
		if err := hit.DecodeInto(&res); err != nil {
			continue
		}

		results = append(results, SearchResult{
			ID:         res.ID,
			Type:       res.Type,
			Title:      res.Title,
			Sub:        res.Sub,
			Artists:    res.Artists,
			AlbumID:    res.AlbumID,
			AlbumTitle: res.AlbumTitle,
		})
	}

	return results, nil
}
