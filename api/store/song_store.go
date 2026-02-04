package store

import (
	"errors"
	"time"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SongStore struct {
	db *gorm.DB
}

func NewSongStore(db *gorm.DB) *SongStore {
	return &SongStore{db: db}
}

func (ss *SongStore) GetSongByID(id uuid.UUID) (*model.Song, error) {
	var song model.Song
	err := ss.db.First(&song, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &song, nil
}

func (ss *SongStore) GetSongByMBID(mbid int, withArtistCredit bool) (*model.Song, error) {
	var song model.Song
	var query = ss.db
	if withArtistCredit {
		query = query.Preload("ArtistCredit")
	}

	if err := query.Where("mb_id = ?", mbid).First(&song).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &song, nil
}

func (ss *SongStore) CreateSongFile(sf *model.SongFile) error {
	return ss.db.Create(sf).Error
}

func (ss *SongStore) DeleteSongFile(id uuid.UUID) error {
	return ss.db.Delete(&model.SongFile{}, id).Error
}

func (ss *SongStore) GetSongFilesBySongID(songID uuid.UUID) ([]model.SongFile, error) {
	var files []model.SongFile
	err := ss.db.Where("song_id = ?", songID).Find(&files).Error
	if err != nil {
		return nil, err
	}
	return files, nil
}

func (ss *SongStore) GetFileByID(fileID uuid.UUID) (*model.SongFile, error) {
	var file model.SongFile
	err := ss.db.First(&file, fileID).Error
	if err != nil {
		return nil, err
	}
	return &file, nil
}

func (ss *SongStore) GetAllSongs() ([]model.Song, error) {
	var songs []model.Song
	err := ss.db.Preload("SongFiles").Preload("Album").Preload("Artists").Find(&songs).Error
	if err != nil {
		return nil, err
	}
	return songs, nil
}

func (ss *SongStore) GetLatestSongs() ([]model.Song, error) {
	var songs []model.Song
	err := ss.db.Preload("SongFiles").Preload("Album").Preload("Artists").Order("created_at desc").Limit(50).Find(&songs).Error
	if err != nil {
		return nil, err
	}
	return songs, nil
}

func (ss *SongStore) CreateSong(song *model.Song) error {
	if err := ss.db.Create(song).Error; err != nil {
		return err
	}
	return nil
}

func (ss *SongStore) UpdateSong(song *model.Song) error {
	return ss.db.Save(song).Error
}

func (ss *SongStore) UpdateSongArtists(song *model.Song, artists []model.Artist) error {
	return ss.db.Model(song).Association("Artists").Replace(artists)
}

func (ss *SongStore) DeleteSong(song *model.Song) error {
	return ss.db.Delete(song).Error
}

func (ss *SongStore) GetSongByTitleAndAlbumID(title string, albumID uuid.UUID) (*model.Song, error) {
	var song model.Song
	err := ss.db.Preload("Album").Preload("Artists").Where("title = ? AND album_id = ?", title, albumID).First(&song).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &song, nil
}

func (ss *SongStore) GetChangedSongs(since time.Time) ([]uuid.UUID, error) {
	var ids []uuid.UUID
	err := ss.db.Model(&model.Song{}).Where("updated_at > ?", since).Pluck("id", &ids).Error
	return ids, err
}

func (ss *SongStore) GetDeletedSongs(since time.Time) ([]uuid.UUID, error) {
	var ids []uuid.UUID
	err := ss.db.Model(&model.Song{}).Unscoped().Where("deleted_at > ?", since).Pluck("id", &ids).Error
	return ids, err
}

func (ss *SongStore) GetSongsByIDs(ids []uuid.UUID) ([]model.Song, error) {
	var songs []model.Song
	err := ss.db.Preload("SongFiles").Preload("Album").Preload("Artists").Where("id IN ?", ids).Find(&songs).Error
	if err != nil {
		return nil, err
	}
	return songs, nil
}

func (ss *SongStore) GetSongsPaginated(page, limit int) ([]model.Song, bool, error) {
	return Paginate[model.Song](ss.db, page, limit, "created_at desc", []string{"SongFiles", "Album", "Artists"})
}

func (ss *SongStore) GetSongsByAlbumID(albumID uuid.UUID) ([]model.Song, error) {
	var songs []model.Song
	err := ss.db.Preload("SongFiles").Preload("Album").Preload("Artists").Where("album_id = ?", albumID).Find(&songs).Error
	if err != nil {
		return nil, err
	}
	return songs, nil
}
