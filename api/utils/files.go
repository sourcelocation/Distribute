package utils

import "strings"

func GetFileFormat(filename string) *string {
	parts := strings.Split(filename, ".")
	if len(parts) < 2 {
		return nil
	}
	format := parts[len(parts)-1]
	return &format
}

func HasPathPrefix(path, prefix string) bool {
	return strings.HasPrefix(path, prefix)
}

func AudioContentType(format string) string {
	switch strings.ToLower(format) {
	case "mp3":
		return "audio/mpeg"
	case "flac":
		return "audio/flac"
	case "wav":
		return "audio/wav"
	case "ogg":
		return "audio/ogg"
	case "m4a":
		return "audio/mp4"
	default:
		return "application/octet-stream"
	}
}
