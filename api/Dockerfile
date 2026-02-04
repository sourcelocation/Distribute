# syntax=docker/dockerfile:1

# -- Stage 1: Build Frontend --
FROM --platform=$BUILDPLATFORM node:22-alpine AS frontend-builder
WORKDIR /app-frontend
COPY admin/package.json admin/package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY admin/index.html ./
COPY admin/vite.config.js ./
COPY admin/eslint.config.js ./
COPY admin/public ./public
COPY admin/src ./src
RUN npm run build

# -- Stage 2: Build Backend --
FROM --platform=$BUILDPLATFORM golang:1.25-alpine AS backend-builder
COPY --from=tonistiigi/xx / /
WORKDIR /app-backend
ARG TARGETPLATFORM
RUN apk add --no-cache git clang lld
RUN xx-apk add --no-cache musl-dev gcc
COPY api/go.mod api/go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY api/ ./
RUN --mount=type=cache,target=/root/.cache/go-build --mount=type=cache,target=/go/pkg/mod \
    CGO_ENABLED=1 xx-go build -ldflags="-s -w" -o distributor .

# -- Stage 3: Final Runner --
FROM alpine:latest AS runner
WORKDIR /app

RUN apk add --no-cache ffmpeg ca-certificates su-exec && \
    adduser -D -g '' appuser

COPY --from=backend-builder /app-backend/distributor /usr/local/bin/distributor
COPY api/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

COPY --from=frontend-builder /app-frontend/dist /app/web

ENV LISTEN_ON=0.0.0.0:8585
EXPOSE 8585

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["distributor"]


# -- Stage 4: Development (Hot Reload) --
FROM golang:1.25-alpine AS dev
WORKDIR /app
RUN apk add --no-cache git build-base
RUN --mount=type=cache,target=/go/pkg/mod go install github.com/air-verse/air@latest
RUN --mount=type=cache,target=/go/pkg/mod go install github.com/go-delve/delve/cmd/dlv@latest
COPY api/go.mod api/go.sum ./
RUN go mod download
COPY api/ ./
CMD ["air", "-c", ".air.toml"]
