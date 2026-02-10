package service

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"os/exec"
	"sort"
	"strconv"
	"strings"

	"github.com/ProjectDistribute/distributor/model"
	"github.com/ProjectDistribute/distributor/store"
)

const (
	SettingTranscodeBitrates = "transcode_bitrates"
	SettingTranscodeProfiles = "transcode_profiles"

	VariantLossless = "lossless"
	VariantSource   = "source"
)

type TranscodeSettings struct {
	BitratesKbps []int
	Profiles     []TranscodeProfile
}

type TranscodeQuality struct {
	ID          string `json:"id,omitempty"`
	Label       string `json:"label,omitempty"`
	Variant     string `json:"variant"`
	BitrateKbps int    `json:"bitrate_kbps"`
	Lossless    bool   `json:"lossless"`
}

type TranscodeProfile struct {
	Variant     string `json:"variant"`
	Label       string `json:"label,omitempty"`
	Codec       string `json:"codec"`
	Format      string `json:"format"`
	BitrateKbps int    `json:"bitrate_kbps"`
	Lossless    bool   `json:"lossless"`
}

type TranscodeService struct {
	SettingsStore *store.SettingsStore
}

func NewTranscodeService(settings *store.SettingsStore) *TranscodeService {
	return &TranscodeService{SettingsStore: settings}
}

func (t *TranscodeService) GetSettings() TranscodeSettings {
	settings := TranscodeSettings{
		BitratesKbps: []int{160},
	}
	if t.SettingsStore == nil {
		return settings
	}

	if raw, err := t.SettingsStore.Get(SettingTranscodeProfiles); err == nil {
		if profiles, ok := parseProfileList(raw); ok && len(profiles) > 0 {
			settings.Profiles = profiles
			return settings
		}
	}

	if raw, err := t.SettingsStore.Get(SettingTranscodeBitrates); err == nil {
		if bitrates, ok := parseBitrateList(raw); ok {
			settings.BitratesKbps = bitrates
			return settings
		}
	}
	return settings
}

func (t *TranscodeService) ActiveProfiles(settings TranscodeSettings) []TranscodeProfile {
	if len(settings.Profiles) > 0 {
		return normalizeProfiles(settings.Profiles)
	}
	return defaultProfiles(settings.BitratesKbps)
}

func (t *TranscodeService) ProfilesForSource(
	settings TranscodeSettings,
	sourceLossless bool,
	sourceBitrateKbps int,
) []TranscodeProfile {
	return t.FilterProfilesForSource(
		t.ActiveProfiles(settings),
		sourceLossless,
		sourceBitrateKbps,
	)
}

func (t *TranscodeService) FilterProfilesForSource(
	profiles []TranscodeProfile,
	sourceLossless bool,
	sourceBitrateKbps int,
) []TranscodeProfile {
	if len(profiles) == 0 {
		return profiles
	}
	if sourceLossless {
		return profiles
	}
	filtered := profiles[:0]
	for _, profile := range profiles {
		if profile.Lossless || profile.BitrateKbps == 0 {
			continue
		}
		if sourceBitrateKbps > 0 && profile.BitrateKbps >= sourceBitrateKbps {
			continue
		}
		filtered = append(filtered, profile)
	}
	return filtered
}

func (t *TranscodeService) HighestQualityProfile(
	settings TranscodeSettings,
	sourceLossless bool,
	sourceBitrateKbps int,
) *TranscodeProfile {
	profiles := t.ProfilesForSource(settings, sourceLossless, sourceBitrateKbps)
	if len(profiles) == 0 {
		return nil
	}
	var best *TranscodeProfile
	for i := range profiles {
		if profiles[i].Lossless {
			return &profiles[i]
		}
		if best == nil || profiles[i].BitrateKbps > best.BitrateKbps {
			best = &profiles[i]
		}
	}
	return best
}

func (t *TranscodeService) AllowedVariants(settings TranscodeSettings) map[string]bool {
	allowed := map[string]bool{}
	for _, profile := range t.ActiveProfiles(settings) {
		if profile.Variant != "" {
			allowed[profile.Variant] = true
		}
	}
	return allowed
}

func (t *TranscodeService) AvailableQualities() []TranscodeQuality {
	settings := t.GetSettings()
	profiles := t.ActiveProfiles(settings)
	qualities := make([]TranscodeQuality, 0, len(profiles))
	for _, profile := range profiles {
		qualities = append(qualities, TranscodeQuality{
			ID:          profile.Variant,
			Label:       profile.Label,
			Variant:     profile.Variant,
			BitrateKbps: profile.BitrateKbps,
			Lossless:    profile.Lossless,
		})
	}
	return qualities
}

func (t *TranscodeService) Transcode(
	sourcePath string,
	destPath string,
	profile TranscodeProfile,
) error {
	args := []string{"-y", "-i", sourcePath, "-vn"}
	switch profile.Codec {
	case "flac":
		args = append(args, "-c:a", "flac", "-compression_level", "5")
	case "alac":
		args = append(args, "-c:a", "alac")
	case "libvorbis":
		args = append(args, "-c:a", "libvorbis")
	default:
		return fmt.Errorf("unsupported codec: %s", profile.Codec)
	}
	if profile.BitrateKbps > 0 {
		args = append(args, "-b:a", fmt.Sprintf("%dk", profile.BitrateKbps))
	}
	format := strings.ToLower(strings.TrimSpace(profile.Format))
	if format == "" {
		format = "ogg"
	}
	if format == "m4a" {
		format = "ipod"
	}
	args = append(args, "-f", format, destPath)

	cmd := exec.Command("ffmpeg", args...)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		log.Printf("Transcode error: %v (%s)\n", err, stderr.String())
		return fmt.Errorf("ffmpeg failed: %v", err)
	}
	return nil
}

func (t *TranscodeService) FilterFilesBySettings(
	files []model.SongFile,
	settings TranscodeSettings,
) []model.SongFile {
	if len(files) == 0 {
		return nil
	}
	allowed := t.AllowedVariants(settings)
	filtered := make([]model.SongFile, 0, len(files))
	hasAllowed := false
	for _, file := range files {
		if file.Variant != "" && allowed[file.Variant] {
			filtered = append(filtered, file)
			hasAllowed = true
			continue
		}
		if file.Variant == VariantSource &&
			allowed[VariantLossless] &&
			IsLosslessSourceFile(file) {
			filtered = append(filtered, file)
			hasAllowed = true
		}
	}
	if hasAllowed {
		return filtered
	}
	for _, file := range files {
		if file.Variant == "" {
			filtered = append(filtered, file)
		}
	}
	if len(filtered) > 0 {
		return filtered
	}
	return files
}

func parseBitrateList(raw string) ([]int, bool) {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return []int{}, true
	}
	if strings.HasPrefix(trimmed, "[") {
		var payload any
		if err := json.Unmarshal([]byte(trimmed), &payload); err != nil {
			return nil, false
		}
		values, ok := extractBitrateValues(payload)
		return values, ok
	}

	values := parseDelimitedBitrates(trimmed)
	return values, true
}

func parseProfileList(raw string) ([]TranscodeProfile, bool) {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return nil, true
	}
	var payload []map[string]any
	if err := json.Unmarshal([]byte(trimmed), &payload); err != nil {
		return nil, false
	}
	profiles := make([]TranscodeProfile, 0, len(payload))
	for _, item := range payload {
		profile := TranscodeProfile{}
		if v, ok := item["variant"].(string); ok {
			profile.Variant = v
		} else if v, ok := item["id"].(string); ok {
			profile.Variant = v
		}
		if v, ok := item["label"].(string); ok {
			profile.Label = v
		}
		if v, ok := item["codec"].(string); ok {
			profile.Codec = v
		}
		if v, ok := item["format"].(string); ok {
			profile.Format = v
		}
		if v, ok := item["bitrate_kbps"].(float64); ok {
			profile.BitrateKbps = int(v)
		} else if v, ok := item["bitrate"].(float64); ok {
			profile.BitrateKbps = int(v)
		}
		if v, ok := item["lossless"].(bool); ok {
			profile.Lossless = v
		}
		profiles = append(profiles, profile)
	}
	return profiles, true
}

func extractBitrateValues(payload any) ([]int, bool) {
	items, ok := payload.([]any)
	if !ok {
		return nil, false
	}
	values := make([]int, 0, len(items))
	for _, item := range items {
		switch v := item.(type) {
		case float64:
			values = append(values, int(v))
		case string:
			values = append(values, parseDelimitedBitrates(v)...)
		default:
			continue
		}
	}
	return values, true
}

func parseDelimitedBitrates(raw string) []int {
	parts := strings.FieldsFunc(raw, func(r rune) bool {
		return r == ',' || r == ';' || r == ' ' || r == '\t' || r == '\n'
	})
	if len(parts) == 0 {
		return []int{}
	}
	values := make([]int, 0, len(parts))
	for _, part := range parts {
		value, err := strconv.Atoi(strings.TrimSpace(part))
		if err != nil {
			continue
		}
		values = append(values, value)
	}
	return values
}

func normalizeBitrates(values []int) []int {
	if len(values) == 0 {
		return nil
	}
	seen := map[int]bool{}
	normalized := make([]int, 0, len(values))
	for _, value := range values {
		if value <= 0 {
			continue
		}
		if seen[value] {
			continue
		}
		seen[value] = true
		normalized = append(normalized, value)
	}
	sort.Ints(normalized)
	return normalized
}

func variantForBitrate(bitrate int) string {
	return fmt.Sprintf("%dk", bitrate)
}

func defaultProfiles(bitrates []int) []TranscodeProfile {
	profiles := []TranscodeProfile{
		{
			Variant:     VariantLossless,
			Label:       "Lossless",
			Codec:       "flac",
			Format:      "flac",
			BitrateKbps: 0,
			Lossless:    true,
		},
	}
	for _, bitrate := range normalizeBitrates(bitrates) {
		profiles = append(
			profiles,
			TranscodeProfile{
				Variant:     variantForBitrate(bitrate),
				Label:       fmt.Sprintf("%dkbps", bitrate),
				Codec:       "libvorbis",
				Format:      "ogg",
				BitrateKbps: bitrate,
				Lossless:    false,
			},
		)
	}
	return profiles
}

func normalizeProfiles(raw []TranscodeProfile) []TranscodeProfile {
	normalized := make([]TranscodeProfile, 0, len(raw))
	seen := map[string]bool{}
	for _, profile := range raw {
		p := profile
		p.Variant = strings.TrimSpace(p.Variant)
		p.Label = strings.TrimSpace(p.Label)
		p.Codec = strings.ToLower(strings.TrimSpace(p.Codec))
		p.Format = strings.ToLower(strings.TrimSpace(p.Format))
		if p.Lossless {
			p.BitrateKbps = 0
		} else if p.BitrateKbps <= 0 {
			p.Lossless = true
			p.BitrateKbps = 0
		}
		if p.Variant == "" {
			if p.Lossless {
				p.Variant = VariantLossless
			} else if p.BitrateKbps > 0 {
				p.Variant = variantForBitrate(p.BitrateKbps)
			}
		}
		if p.Codec == "" {
			if p.Lossless {
				p.Codec = "flac"
			} else {
				p.Codec = "libvorbis"
			}
		}
		if p.Format == "" {
			if p.Lossless {
				p.Format = "flac"
			} else {
				p.Format = "ogg"
			}
		}
		if p.Label == "" {
			if p.Lossless {
				p.Label = "Lossless"
			} else if p.BitrateKbps > 0 {
				p.Label = fmt.Sprintf("%dkbps", p.BitrateKbps)
			}
		}
		if p.Variant == "" || p.Codec == "" || p.Format == "" {
			continue
		}
		if seen[p.Variant] {
			continue
		}
		seen[p.Variant] = true
		normalized = append(normalized, p)
	}
	if len(normalized) == 0 {
		return defaultProfiles(nil)
	}
	return normalized
}
