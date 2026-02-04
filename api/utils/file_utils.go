package utils

import (
	"bufio"
	"io"
	"os"
)

func ReadLastNLines(filePath string, n int) ([]string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	stat, err := file.Stat()
	if err != nil {
		return nil, err
	}

	filesize := stat.Size()
	// Simple Robust Strategy: Read last X bytes
	const REASONABLE_LOG_SIZE = 100 * 1024 // 100KB should cover 100 lines easily

	startPos := filesize - REASONABLE_LOG_SIZE
	if startPos < 0 {
		startPos = 0
	}

	_, err = file.Seek(startPos, io.SeekStart)
	if err != nil {
		return nil, err
	}

	scanner := bufio.NewScanner(file)
	allLines := []string{}
	for scanner.Scan() {
		allLines = append(allLines, scanner.Text())
	}

	// If we started in the middle of a line, the first line might be partial (garbage).
	// Drop 1st line if we seeked (>0) and have >0 lines
	if startPos > 0 && len(allLines) > 0 {
		allLines = allLines[1:]
	}

	if len(allLines) > n {
		return allLines[len(allLines)-n:], nil
	}
	return allLines, nil
}
