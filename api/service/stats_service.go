package service

import (
	"sync"
	"time"
)

type BandwidthPoint struct {
	Timestamp time.Time `json:"timestamp"`
	BytesIn   int64     `json:"bytes_in"`
	BytesOut  int64     `json:"bytes_out"`
}

type StatsService struct {
	mu           sync.RWMutex
	history      []BandwidthPoint
	currentPoint BandwidthPoint
}

func NewStatsService() *StatsService {
	s := &StatsService{
		history: make([]BandwidthPoint, 0, 96), // 24 hours * 4 (15 min intervals)
	}
	s.currentPoint.Timestamp = time.Now()
	go s.ticker()
	return s
}

func (s *StatsService) ticker() {
	ticker := time.NewTicker(5 * time.Minute)
	for range ticker.C {
		s.mu.Lock()
		// Push current point to history
		s.history = append(s.history, s.currentPoint)
		if len(s.history) > 96 {
			s.history = s.history[1:]
		}
		// Reset current point
		s.currentPoint = BandwidthPoint{
			Timestamp: time.Now(),
			BytesIn:   0,
			BytesOut:  0,
		}
		s.mu.Unlock()
	}
}

func (s *StatsService) RecordIncoming(bytes int64) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.currentPoint.BytesIn += bytes
}

func (s *StatsService) RecordOutgoing(bytes int64) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.currentPoint.BytesOut += bytes
}

func (s *StatsService) GetBandwidthHistory() []BandwidthPoint {
	s.mu.RLock()
	defer s.mu.RUnlock()
	// Return copy to avoid races
	history := make([]BandwidthPoint, len(s.history)+1)
	copy(history, s.history)
	history[len(s.history)] = s.currentPoint // Include current partial interval
	return history
}
