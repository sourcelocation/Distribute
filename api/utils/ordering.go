package utils

import "strings"

const alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

const midChar = "V"

func GenerateNextKey(prev string) string {
	if prev == "" {
		return "a"
	}

	lastChar := prev[len(prev)-1]
	idx := strings.IndexByte(alphabet, lastChar)

	if idx == -1 || idx == len(alphabet)-1 {
		return prev + string(alphabet[0])
	}

	return prev[:len(prev)-1] + string(alphabet[idx+1])
}

func GenerateKeyBetween(prev, next *string) string {
	if prev == nil {
		if next == nil {
			return "a"
		}
		return midpoint("", *next)
	}

	if next == nil {
		return GenerateNextKey(*prev)
	}

	if *prev >= *next {
		return GenerateNextKey(*prev)
	}

	return midpoint(*prev, *next)
}

func midpoint(prev, next string) string {
	pLen := len(prev)
	nLen := len(next)
	i := 0

	for i < pLen && i < nLen && prev[i] == next[i] {
		i++
	}

	valP := -1
	if i < pLen {
		valP = strings.IndexByte(alphabet, prev[i])
	} else {
		return prev + midChar
	}

	valN := strings.IndexByte(alphabet, next[i])

	if valP == -1 || valN == -1 {
		return prev + midChar
	}

	if valN-valP > 1 {
		mid := (valP + valN) / 2
		return prev[:i] + string(alphabet[mid])
	}

	return prev + midChar
}
