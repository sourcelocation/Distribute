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
