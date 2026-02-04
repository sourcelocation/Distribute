package store

import (
	"time"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AlbumStore struct {
	db *gorm.DB
}

func NewAlbumStore(db *gorm.DB) *AlbumStore {
	return &AlbumStore{db: db}
}

func (as *AlbumStore) CreateAlbum(album *model.Album) (*model.Album, error) {
	if err := as.db.Create(album).Error; err != nil {
		return nil, err
	}
	return album, nil
}

func (as *AlbumStore) UpdateAlbum(album *model.Album) error {
	return as.db.Save(album).Error
}

func (as *AlbumStore) GetAlbumsByTitle(title string) ([]model.Album, error) {
	var albums []model.Album
	if err := as.db.Preload("Songs").Preload("Songs.Artists").Where("title = ?", title).Find(&albums).Error; err != nil {
		return nil, err
	}
	return albums, nil
}

func (as *AlbumStore) GetAlbumByID(uuid uuid.UUID) (*model.Album, error) {
	var album model.Album
	if err := as.db.Preload("Songs").Preload("Songs.Artists").First(&album, "id = ?", uuid).Error; err != nil {
		return nil, err
	}
	return &album, nil
}

func (as *AlbumStore) DeleteAlbum(album *model.Album) error {
	return as.db.Delete(album).Error
}

func (as *AlbumStore) GetChangedAlbums(since time.Time) ([]uuid.UUID, error) {
	var ids []uuid.UUID
	err := as.db.Model(&model.Album{}).Where("updated_at > ?", since).Pluck("id", &ids).Error
	return ids, err
}

func (as *AlbumStore) GetDeletedAlbums(since time.Time) ([]uuid.UUID, error) {
	var ids []uuid.UUID
	err := as.db.Model(&model.Album{}).Unscoped().Where("deleted_at > ?", since).Pluck("id", &ids).Error
	return ids, err
}

func (as *AlbumStore) GetAlbumsByIDs(ids []uuid.UUID) ([]model.Album, error) {
	var albums []model.Album
	err := as.db.Preload("Songs").Preload("Songs.Artists").Where("id IN ?", ids).Find(&albums).Error
	if err != nil {
		return nil, err
	}
	return albums, nil
}

func (as *AlbumStore) GetAlbumsPaginated(page, limit int) ([]model.Album, bool, error) {
	return Paginate[model.Album](as.db, page, limit, "created_at desc", []string{"Songs", "Songs.Artists"})
}

func (as *AlbumStore) GetAllAlbums() ([]model.Album, error) {
	var albums []model.Album
	if err := as.db.Preload("Songs").Preload("Songs.Artists").Find(&albums).Error; err != nil {
		return nil, err
	}
	return albums, nil
}
