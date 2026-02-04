package service

import (
	"errors"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/ProjectDistribute/distributor/store"
	"github.com/google/uuid"
)

type PlaylistService struct {
	Store     *store.PlaylistStore
	SearchSvc *SearchService
}

func NewPlaylistService(store *store.PlaylistStore) *PlaylistService {
	return &PlaylistService{Store: store}
}

func (ps *PlaylistService) CreatePlaylist(playlistID uuid.UUID, userID uuid.UUID, name string, parentFolder uuid.UUID, songIDs []uuid.UUID) (model.Playlist, error) {
	if !ps.Store.IsFolderOwnedByUser(parentFolder, userID) {
		return model.Playlist{}, errors.New("parent folder does not belong to user")
	}
	playlist := &model.Playlist{
		ID:       playlistID,
		UserID:   userID,
		Name:     name,
		FolderID: parentFolder,
	}
	playlistRes, err := ps.Store.CreatePlaylist(playlist)
	if err == nil {
		if len(songIDs) > 0 {
			for _, songID := range songIDs {
				_ = ps.Store.AddSongToPlaylist(playlistRes.ID, songID)
			}
			// TODO: This is not efficient
			fullPlaylist, err := ps.Store.GetPlaylistByID(playlistRes.ID)
			if err == nil {
				playlistRes = *fullPlaylist
			}
		}
		_ = ps.SearchSvc.IndexPlaylist(&playlistRes)
	}
	return playlistRes, err
}

func (ps *PlaylistService) CreatePlaylistFolder(folderID uuid.UUID, userID uuid.UUID, name string, parentFolder *uuid.UUID) (model.PlaylistFolder, error) {
	if parentFolder != nil {
		if !ps.Store.IsFolderOwnedByUser(*parentFolder, userID) {
			return model.PlaylistFolder{}, errors.New("parent folder does not belong to user")
		}
	}
	folder := &model.PlaylistFolder{
		ID:       folderID,
		UserID:   userID,
		Name:     name,
		ParentID: parentFolder,
	}
	return ps.Store.CreatePlaylistFolder(folder)
}

func (ps *PlaylistService) CreatePlaylistWithContents(userID uuid.UUID, name string, songIDs []uuid.UUID) (model.Playlist, error) {
	rootFolderID, err := ps.Store.GetRootFolderID(userID)
	if err != nil {
		return model.Playlist{}, err
	}

	// TODO: Duplicate
	return ps.CreatePlaylist(uuid.New(), userID, name, rootFolderID, songIDs)
}

func (ps *PlaylistService) GetRootFolderID(userID uuid.UUID) (uuid.UUID, error) {
	return ps.Store.GetRootFolderID(userID)
}
