package store

import (
	"time"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ArtistStore struct {
	db *gorm.DB
}

func NewArtistStore(db *gorm.DB) *ArtistStore {
	return &ArtistStore{db: db}
}

func (as *ArtistStore) CreateArtist(artist *model.Artist) (*model.Artist, error) {
	if err := as.db.Create(artist).Error; err != nil {
		return nil, err
	}
	return artist, nil
}

// func (as *ArtistStore) UpdateExternalIDForArtist(artistID uint, newExternalID string) {
// 	panic("not implemented")
// }

func (as *ArtistStore) GetArtistByIdentifier(identifier string) (*model.Artist, error) {
	var id model.ArtistIdentifier
	err := as.db.Preload("Artist").Where("identifier = ?", identifier).First(&id).Error
	if err != nil {
		return nil, err
	}
	return &id.Artist, nil
}

func (as *ArtistStore) CreateArtistIdentifier(artist *model.Artist, identifier string) (*model.ArtistIdentifier, error) {
	artistIdentifier := &model.ArtistIdentifier{
		Identifier: identifier,
		ArtistID:   artist.ID,
	}
	if err := as.db.Create(artistIdentifier).Error; err != nil {
		return nil, err
	}
	return artistIdentifier, nil
}

func (as *ArtistStore) GetArtistByID(artistID uuid.UUID) (*model.Artist, error) {
	var artist model.Artist
	// TODO: Figure out if there's a performance impact by doing preloads on Artists and on Songs (added preload for albums there)
	if err := as.db.Preload("Identifiers").First(&artist, "id = ?", artistID).Error; err != nil {
		return nil, err
	}
	return &artist, nil
}

func (as *ArtistStore) UpdateArtist(artist *model.Artist) error {
	return as.db.Save(artist).Error
}

func (as *ArtistStore) DeleteArtist(artist *model.Artist) error {
	return as.db.Delete(artist).Error
}
func (as *ArtistStore) GetAllArtists() ([]model.Artist, error) {
	var artists []model.Artist
	if err := as.db.Find(&artists).Error; err != nil {
		return nil, err
	}
	return artists, nil
}

func (as *ArtistStore) GetChangedArtists(since time.Time) ([]uuid.UUID, error) {
	var ids []uuid.UUID
	err := as.db.Model(&model.Artist{}).Where("updated_at > ?", since).Pluck("id", &ids).Error
	return ids, err
}

func (as *ArtistStore) GetDeletedArtists(since time.Time) ([]uuid.UUID, error) {
	var ids []uuid.UUID
	err := as.db.Model(&model.Artist{}).Unscoped().Where("deleted_at > ?", since).Pluck("id", &ids).Error
	return ids, err
}

func (as *ArtistStore) GetArtistsByIDs(ids []uuid.UUID) ([]model.Artist, error) {
	var artists []model.Artist
	err := as.db.Where("id IN ?", ids).Find(&artists).Error
	if err != nil {
		return nil, err
	}
	return artists, nil
}

func (as *ArtistStore) GetAlbumsForArtist(artistID uuid.UUID) ([]model.Album, error) {
	var albums []model.Album
	// Join songs -> song_artists to find albums for this artist
	err := as.db.
		Joins("JOIN songs ON songs.album_id = albums.id").
		Joins("JOIN song_artists ON song_artists.song_id = songs.id").
		Where("song_artists.artist_id = ?", artistID).
		Distinct().
		Find(&albums).Error
	if err != nil {
		return nil, err
	}
	return albums, nil
}

func (as *ArtistStore) GetArtistsPaginated(page, limit int) ([]model.Artist, bool, error) {
	return Paginate[model.Artist](as.db, page, limit, "name asc", nil)
}
