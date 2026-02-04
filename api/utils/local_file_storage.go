package utils

import (
	"io"
	"os"
	"path/filepath"
)

type LocalFileStorage struct{}

func (LocalFileStorage) Save(path string, r io.Reader) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	_, err = io.Copy(f, r)
	return err
}

func (LocalFileStorage) Exists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func (LocalFileStorage) Delete(path string) error {
	return os.Remove(path)
}

func (LocalFileStorage) Move(src, dst string) error {
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}
	return os.Rename(src, dst)
}
