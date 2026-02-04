package handler

import (
	"fmt"
	"net/http"
	"runtime"
	"time"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/labstack/echo/v4"
	"github.com/shirou/gopsutil/v3/cpu"
	"github.com/shirou/gopsutil/v3/disk"
)

type StorageStats struct {
	Total   string `json:"total"`
	Used    string `json:"used"`
	Percent int    `json:"percent"`
}

type StatsResponse struct {
	TotalSongs     int64        `json:"total_songs"`
	TotalAlbums    int64        `json:"total_albums"`
	TotalArtists   int64        `json:"total_artists"`
	TotalUsers     int64        `json:"total_users"`
	TotalPlaylists int64        `json:"total_playlists"`
	Goroutines     int          `json:"goroutines"`
	Memory         string       `json:"memory"`
	Uptime         int64        `json:"uptime"`
	Cpu            float64      `json:"cpu"`
	Storage        StorageStats `json:"storage"`
}

var startTime = time.Now()

func (h *Handler) GetStats(c echo.Context) error {
	var stats StatsResponse

	if err := h.db.Model(&model.Song{}).Count(&stats.TotalSongs).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to count songs"})
	}
	if err := h.db.Model(&model.Album{}).Count(&stats.TotalAlbums).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to count albums"})
	}
	if err := h.db.Model(&model.Artist{}).Count(&stats.TotalArtists).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to count artists"})
	}
	if err := h.db.Model(&model.User{}).Count(&stats.TotalUsers).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to count users"})
	}
	if err := h.db.Model(&model.Playlist{}).Count(&stats.TotalPlaylists).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to count playlists"})
	}

	stats.Goroutines = runtime.NumGoroutine()
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	stats.Memory = formatBytes(m.Alloc)
	stats.Uptime = int64(time.Since(startTime).Seconds())

	// CPU
	cpuPercent, _ := cpu.Percent(0, false)
	if len(cpuPercent) > 0 {
		stats.Cpu = cpuPercent[0]
	}

	// Storage (Checking /app/storage which is mapped to ./data)
	// If checking inside container, ensure path exists or fallback to root
	diskStat, err := disk.Usage("/app/storage")
	if err == nil {
		stats.Storage = StorageStats{
			Total:   formatBytes(diskStat.Total),
			Used:    formatBytes(diskStat.Used),
			Percent: int(diskStat.UsedPercent),
		}
	} else {
		// Fallback for dev environment where /app/storage might not be exact
		diskStat, _ := disk.Usage("/")
		if diskStat != nil {
			stats.Storage = StorageStats{
				Total:   formatBytes(diskStat.Total),
				Used:    formatBytes(diskStat.Used),
				Percent: int(diskStat.UsedPercent),
			}
		}
	}

	return c.JSON(http.StatusOK, stats)
}

func (h *Handler) GetBandwidth(c echo.Context) error {
	history := h.stats_svc.GetBandwidthHistory()
	return c.JSON(http.StatusOK, history)
}

func formatBytes(b uint64) string {
	const unit = 1024
	if b < unit {
		return fmt.Sprintf("%d B", b)
	}
	div, exp := int64(unit), 0
	for n := b / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %ciB", float64(b)/float64(div), "KMGTPE"[exp])
}

func (h *Handler) BandwidthMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		// Incoming request size
		reqSize := c.Request().ContentLength
		if reqSize > 0 {
			h.stats_svc.RecordIncoming(reqSize)
		}

		err := next(c)

		// Outgoing response size
		resSize := c.Response().Size
		h.stats_svc.RecordOutgoing(resSize)

		return err
	}
}
