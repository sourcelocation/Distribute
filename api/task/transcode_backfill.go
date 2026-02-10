package task

import (
	"log"

	"github.com/ProjectDistribute/distributor/service"
)

type TranscodeBackfillResult struct {
	Processed int `json:"processed"`
	Skipped   int `json:"skipped"`
	Created   int `json:"created"`
}

func BackfillTranscodes(songSvc *service.SongService) (TranscodeBackfillResult, error) {
	result := TranscodeBackfillResult{}
	if songSvc == nil || songSvc.Transcode == nil {
		return result, nil
	}

	songs, err := songSvc.Store.GetAllSongs()
	if err != nil {
		return result, err
	}

	for _, song := range songs {
		result.Processed++
		created, changed, err := songSvc.EnsureMissingTranscodes(song)
		if err != nil {
			log.Printf("Backfill transcode failed for song %s: %v\n", song.ID, err)
			continue
		}
		if !changed {
			result.Skipped++
			continue
		}
		result.Created += created
	}

	return result, nil
}
