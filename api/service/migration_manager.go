package service

import (
	"encoding/json"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/ProjectDistribute/distributor/db"
	"github.com/ProjectDistribute/distributor/model"
	"github.com/ProjectDistribute/distributor/store"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

const (
	MigrationStatusKey = "migration_status"
)

type MigrationStepStatus struct {
	State          string `json:"state"`
	Processed      int    `json:"processed,omitempty"`
	Total          int    `json:"total,omitempty"`
	LastCreatedAt  string `json:"last_created_at,omitempty"`
	LastID         string `json:"last_id,omitempty"`
	Error          string `json:"error,omitempty"`
	LastUpdateUnix int64  `json:"last_update_unix,omitempty"`
}

type MigrationStatus struct {
	Running      bool                           `json:"running"`
	StartedAt    string                         `json:"started_at,omitempty"`
	UpdatedAt    string                         `json:"updated_at,omitempty"`
	Steps        map[string]MigrationStepStatus `json:"steps"`
	CurrentStep  string                         `json:"current_step,omitempty"`
	LastError    string                         `json:"last_error,omitempty"`
	VersionLabel string                         `json:"version_label,omitempty"`
}

type MigrationManager struct {
	db       *gorm.DB
	settings *store.SettingsStore
	songSvc  *SongService
	version  string

	mu      sync.Mutex
	running bool
	status  MigrationStatus
}

func NewMigrationManager(
	dbConn *gorm.DB,
	settings *store.SettingsStore,
	songSvc *SongService,
	version string,
) *MigrationManager {
	return &MigrationManager{
		db:       dbConn,
		settings: settings,
		songSvc:  songSvc,
		version:  version,
	}
}

func (m *MigrationManager) StartAsync() {
	m.mu.Lock()
	if m.running {
		m.mu.Unlock()
		return
	}
	m.running = true
	m.mu.Unlock()

	status := m.loadStatus()
	if status.VersionLabel == m.version && m.allStepsCompleted(status) {
		m.mu.Lock()
		m.running = false
		m.status = status
		m.mu.Unlock()
		return
	}

	go m.run()
}

func (m *MigrationManager) Retry() {
	m.mu.Lock()
	m.status = MigrationStatus{}
	m.running = false
	m.mu.Unlock()
	m.StartAsync()
}

func (m *MigrationManager) Status() MigrationStatus {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.status
}

func (m *MigrationManager) run() {
	status := m.loadStatus()
	if status.Steps == nil {
		status.Steps = map[string]MigrationStepStatus{}
	}
	status.Running = true
	status.StartedAt = time.Now().Format(time.RFC3339)
	status.VersionLabel = m.version
	m.saveStatus(status)

	if err := m.runStep("file_path_backfill", m.stepFilePathBackfill, &status); err != nil {
		return
	}
	if err := m.runStep("file_metadata_backfill", m.stepFileMetadataBackfill, &status); err != nil {
		return
	}
	if err := m.runStep("transcode_backfill", m.stepTranscodeBackfill, &status); err != nil {
		return
	}

	status = m.loadStatus()
	status.Running = false
	status.CurrentStep = ""
	status.UpdatedAt = time.Now().Format(time.RFC3339)
	status.VersionLabel = m.version
	m.saveStatus(status)

	m.mu.Lock()
	m.running = false
	m.status = status
	m.mu.Unlock()
}

func (m *MigrationManager) runStep(
	key string,
	fn func(step *MigrationStepStatus) error,
	status *MigrationStatus,
) error {
	step := status.Steps[key]
	if step.State == "completed" {
		return nil
	}

	step.State = "running"
	step.LastUpdateUnix = time.Now().Unix()
	status.CurrentStep = key
	status.Steps[key] = step
	m.saveStatus(*status)

	if err := fn(&step); err != nil {
		step.State = "failed"
		step.Error = err.Error()
		step.LastUpdateUnix = time.Now().Unix()
		status.LastError = err.Error()
		status.Steps[key] = step
		status.Running = false
		status.UpdatedAt = time.Now().Format(time.RFC3339)
		m.saveStatus(*status)
		return err
	}

	step.State = "completed"
	step.Error = ""
	step.LastUpdateUnix = time.Now().Unix()
	status.Steps[key] = step
	status.CurrentStep = ""
	status.UpdatedAt = time.Now().Format(time.RFC3339)
	m.saveStatus(*status)
	return nil
}

func (m *MigrationManager) stepFilePathBackfill(step *MigrationStepStatus) error {
	if m.db == nil {
		return fmt.Errorf("db not available")
	}
	return db.BackfillSongFilePaths(m.db)
}

func (m *MigrationManager) stepFileMetadataBackfill(step *MigrationStepStatus) error {
	if m.db == nil || m.songSvc == nil {
		return fmt.Errorf("services not available")
	}
	// ensure missing duration/size/bitrate
	EnsureFilesDuration(m.db, *m.songSvc)
	EnsureFilesSize(m.db)
	return nil
}

func (m *MigrationManager) stepTranscodeBackfill(step *MigrationStepStatus) error {
	if m.songSvc == nil || m.songSvc.Transcode == nil {
		return nil
	}

	total, err := m.songSvc.Store.CountSongs()
	if err != nil {
		return err
	}
	step.Total = total

	lastCreatedAt, lastID := parseCheckpoint(step.LastCreatedAt, step.LastID)
	batchSize := 50
	for {
		songs, err := m.songSvc.Store.GetSongsAfter(lastCreatedAt, lastID, batchSize)
		if err != nil {
			return err
		}
		if len(songs) == 0 {
			break
		}

		for _, song := range songs {
			step.Processed++
			if err := m.backfillSongTranscodes(song); err != nil {
				log.Printf("Backfill transcode failed for song %s: %v\n", song.ID, err)
			}
			lastCreatedAt = song.CreatedAt
			lastID = song.ID
		}

		step.LastCreatedAt = lastCreatedAt.Format(time.RFC3339Nano)
		step.LastID = lastID.String()
		step.LastUpdateUnix = time.Now().Unix()
		m.persistStep("transcode_backfill", *step)
	}
	return nil
}

func (m *MigrationManager) backfillSongTranscodes(song model.Song) error {
	if m.songSvc == nil {
		return nil
	}
	_, _, err := m.songSvc.EnsureStreamableHighestQuality(song)
	return err
}

func (m *MigrationManager) persistStep(key string, step MigrationStepStatus) {
	status := m.loadStatus()
	if status.Steps == nil {
		status.Steps = map[string]MigrationStepStatus{}
	}
	status.Steps[key] = step
	status.UpdatedAt = time.Now().Format(time.RFC3339)
	m.saveStatus(status)
}

func (m *MigrationManager) loadStatus() MigrationStatus {
	if m.settings == nil {
		return MigrationStatus{}
	}
	raw, err := m.settings.Get(MigrationStatusKey)
	if err != nil || raw == "" {
		return MigrationStatus{Steps: map[string]MigrationStepStatus{}}
	}
	var status MigrationStatus
	if err := json.Unmarshal([]byte(raw), &status); err != nil {
		return MigrationStatus{Steps: map[string]MigrationStepStatus{}}
	}
	return status
}

func (m *MigrationManager) saveStatus(status MigrationStatus) {
	m.mu.Lock()
	m.status = status
	m.mu.Unlock()
	if m.settings == nil {
		return
	}
	data, err := json.Marshal(status)
	if err != nil {
		return
	}
	_ = m.settings.Set(MigrationStatusKey, string(data))
}

func parseCheckpoint(lastCreatedAt, lastID string) (time.Time, uuid.UUID) {
	var t time.Time
	var id uuid.UUID
	if lastCreatedAt != "" {
		if parsed, err := time.Parse(time.RFC3339Nano, lastCreatedAt); err == nil {
			t = parsed
		}
	}
	if lastID != "" {
		if parsed, err := uuid.Parse(lastID); err == nil {
			id = parsed
		}
	}
	return t, id
}

func (m *MigrationManager) allStepsCompleted(status MigrationStatus) bool {
	if len(status.Steps) == 0 {
		return false
	}
	for _, step := range status.Steps {
		if step.State != "completed" {
			return false
		}
	}
	return true
}
