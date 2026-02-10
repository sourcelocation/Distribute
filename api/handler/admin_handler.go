package handler

import (
	"github.com/ProjectDistribute/distributor/service"
	"github.com/ProjectDistribute/distributor/task"
	"github.com/labstack/echo/v4"
)

// RunDoctor godoc
// @Summary Run maintenance tasks
// @Description Runs server-side maintenance (ensures song file durations and sizes). Requires an admin JWT.
// @Tags admin
// @Security BearerAuth
// @Success 200 {string} string "OK"
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Router /doctor [post]
func (h *Handler) RunDoctor(c echo.Context) error {
	service.EnsureFilesDuration(h.db, *h.song_svc)
	service.EnsureFilesSize(h.db)
	return c.NoContent(200)
}

// ReindexSearch godoc
// @Summary Re-index search database
// @Description Deletes all documents in Meilisearch and re-indexes them from the database. Requires an admin JWT.
// @Tags admin
// @Security BearerAuth
// @Success 200 {string} string "OK"
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Router /search/reindex [post]
func (h *Handler) ReindexSearch(c echo.Context) error {
	task.ReindexAll(h.db, h.search_svc)
	return c.NoContent(200)
}

// RemoveOrphans godoc
// @Summary Remove orphan entities
// @Description Removes orphan songs, albums, artists, broken links, and related metadata (identifiers, files). Requires an admin JWT.
// @Tags admin
// @Security BearerAuth
// @Success 200 {object} map[string]int64
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Router /admin/orphans [delete]
func (h *Handler) RemoveOrphans(c echo.Context) error {
	results, err := task.RemoveOrphans(h.db)
	if err != nil {
		return c.JSON(500, ErrorResponse{Error: err.Error()})
	}

	anyDeleted := false
	for _, count := range results {
		if count > 0 {
			anyDeleted = true
			break
		}
	}

	if anyDeleted {
		task.ReindexAll(h.db, h.search_svc)
	}

	return c.JSON(200, results)
}

// CleanSongFiles godoc
// @Summary Remove invalid song files
// @Description Removes SongFile records where the physical file is missing from storage. Requires an admin JWT.
// @Tags admin
// @Security BearerAuth
// @Success 200 {object} map[string]int64
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Router /admin/files/cleanup [delete]
func (h *Handler) CleanSongFiles(c echo.Context) error {
	deleted, err := task.CleanupInvalidSongFiles(h.db, *h.song_svc)
	if err != nil {
		return c.JSON(500, ErrorResponse{Error: err.Error()})
	}

	return c.JSON(200, map[string]int64{
		"files_deleted": deleted,
	})
}

// BackfillTranscodes godoc
// @Summary Backfill missing transcodes
// @Description Generates missing transcode variants for existing songs based on current settings. Requires an admin JWT.
// @Tags admin
// @Security BearerAuth
// @Success 200 {object} task.TranscodeBackfillResult
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /admin/transcode/backfill [post]
func (h *Handler) BackfillTranscodes(c echo.Context) error {
	result, err := task.BackfillTranscodes(h.song_svc)
	if err != nil {
		return c.JSON(500, ErrorResponse{Error: err.Error()})
	}
	return c.JSON(200, result)
}

// GetMigrationStatus godoc
// @Summary Get migration status
// @Description Returns background migration status. Requires an admin JWT.
// @Tags admin
// @Security BearerAuth
// @Success 200 {object} service.MigrationStatus
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Router /admin/migrations/status [get]
func (h *Handler) GetMigrationStatus(c echo.Context) error {
	if h.migrationMgr == nil {
		return c.JSON(200, map[string]string{"status": "unavailable"})
	}
	return c.JSON(200, h.migrationMgr.Status())
}

// RetryMigrations godoc
// @Summary Retry migrations
// @Description Resets and re-runs background migrations. Requires an admin JWT.
// @Tags admin
// @Security BearerAuth
// @Success 202 {string} string "OK"
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Router /admin/migrations/retry [post]
func (h *Handler) RetryMigrations(c echo.Context) error {
	if h.migrationMgr == nil {
		return c.JSON(500, ErrorResponse{Error: "migration manager unavailable"})
	}
	h.migrationMgr.Retry()
	return c.NoContent(202)
}
