package service

import (
	"path/filepath"
	"strings"

	"github.com/ProjectDistribute/distributor/model"
)

func IsLosslessSourceFormat(format string) bool {
	switch strings.ToLower(format) {
	case "flac", "wav", "aiff", "alac":
		return true
	default:
		return false
	}
}

func IsLosslessSourcePath(path string) bool {
	ext := strings.TrimPrefix(strings.ToLower(filepath.Ext(path)), ".")
	if ext == "" {
		return false
	}
	return IsLosslessSourceFormat(ext)
}

func IsLosslessSourceFile(file model.SongFile) bool {
	if file.Variant == VariantLossless {
		return true
	}
	if file.Format != "" && IsLosslessSourceFormat(file.Format) {
		return true
	}
	if file.Codec != "" && IsLosslessSourceFormat(file.Codec) {
		return true
	}
	return false
}

func SelectBestSourceFile(files []model.SongFile) *model.SongFile {
	var best *model.SongFile
	for i, file := range files {
		if file.Variant == VariantLossless {
			return &files[i]
		}
		if file.Variant == VariantSource && best == nil {
			best = &files[i]
			continue
		}
		if best == nil {
			best = &files[i]
			continue
		}
		if best.Codec != "flac" && file.Codec == "flac" {
			best = &files[i]
			continue
		}
		if best.Format != "flac" && file.Format == "flac" {
			best = &files[i]
			continue
		}
		if file.Size > best.Size {
			best = &files[i]
		}
	}
	return best
}

func MissingProfiles(
	files []model.SongFile,
	profiles []TranscodeProfile,
) []TranscodeProfile {
	byVariant := map[string]bool{}
	for _, file := range files {
		if file.Variant != "" {
			byVariant[file.Variant] = true
		}
	}

	var missing []TranscodeProfile
	for _, profile := range profiles {
		if !byVariant[profile.Variant] {
			missing = append(missing, profile)
		}
	}
	return missing
}

func MissingOrMismatchedProfiles(
	files []model.SongFile,
	profiles []TranscodeProfile,
) []TranscodeProfile {
	byVariant := map[string]model.SongFile{}
	for _, file := range files {
		if file.Variant != "" {
			if _, exists := byVariant[file.Variant]; !exists {
				byVariant[file.Variant] = file
			}
		}
	}

	var missing []TranscodeProfile
	for _, profile := range profiles {
		file, ok := byVariant[profile.Variant]
		if !ok {
			missing = append(missing, profile)
			continue
		}
		fileFormat := strings.ToLower(strings.TrimSpace(file.Format))
		profileFormat := strings.ToLower(strings.TrimSpace(profile.Format))
		if profileFormat == "" || fileFormat == "" || profileFormat != fileFormat {
			missing = append(missing, profile)
			continue
		}
		fileCodec := strings.ToLower(strings.TrimSpace(file.Codec))
		profileCodec := strings.ToLower(strings.TrimSpace(profile.Codec))
		if profileCodec == "" || fileCodec == "" || profileCodec != fileCodec {
			missing = append(missing, profile)
			continue
		}
	}
	return missing
}
