package utils

import (
	"context"
	"io"

	"golang.org/x/time/rate"
)

type RateLimitedReadSeeker struct {
	rs      io.ReadSeeker
	limiter *rate.Limiter
	ctx     context.Context
}

func NewRateLimitedReadSeeker(
	rs io.ReadSeeker,
	limiter *rate.Limiter,
	ctx context.Context,
) *RateLimitedReadSeeker {
	return &RateLimitedReadSeeker{rs: rs, limiter: limiter, ctx: ctx}
}

func (r *RateLimitedReadSeeker) Read(p []byte) (int, error) {
	n, err := r.rs.Read(p)
	if n > 0 && r.limiter != nil {
		// WaitN fails if n > burst, so wait in chunks.
		remaining := n
		burst := r.limiter.Burst()
		if burst < 1 {
			burst = 1
		}
		for remaining > 0 {
			chunk := remaining
			if chunk > burst {
				chunk = burst
			}
			if waitErr := r.limiter.WaitN(r.ctx, chunk); waitErr != nil {
				return n, waitErr
			}
			remaining -= chunk
		}
	}
	return n, err
}

func (r *RateLimitedReadSeeker) Seek(offset int64, whence int) (int64, error) {
	return r.rs.Seek(offset, whence)
}
