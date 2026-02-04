# Project Distribute (Context)

Decentralized music platform with an offline-first Flutter client and a Go backend. This file is the shared context for both sides.

## Products
- **Client**: Offline-first music player.
- **Server**: Self-hosted streamer + library sync hub.

## Key Concepts
- **Offline-first**: Client uses local SQLite (Drift) and a `SyncQueue` to push/pull only the models needed for offline UX.
- **Source of truth**: Backend owns canonical data for sync.
- **Library models**: Playlists, folders, artists, albums, songs.

## Client (Flutter)
- **State/Navigation**: Bloc + `go_router`.
- **UI**: `AppIcons` for cross-platform icons.
- **Note**: `freezed` classes require the `abstract` keyword in recent versions.

## Server (Go)
- **Features**: Audio serving, trusted-server sync (push/pull), JWT auth, admin tools (`/doctor`, re-indexing, content management).
- **Search**: Meilisearch for songs, albums, artists, playlists.
- **API**: REST (Swagger/OpenAPI).
- **Permissions**: Admins manage songs/albums/artists; users manage playlists/folders.

## Backend Architecture
- **Flow**: Router → Middleware → Handler → Service → Store → DB
- **Structure**: `main.go` entry; `router/` setup; `handler/routes.go` endpoints; `model/` GORM structs.
- **Storage**: `data/` volume persists `/album_covers`, `/songs`, `/db`.
- **Logging**: `log.Printf`.
- **DB Notes**: Special identifiers only for songs/albums/artists. Songs can have multiple files (quality variants) and multiple artists; one album per song.

## Stack & Conventions
- **Stack**: Go 1.25, Echo v4, SQLite (GORM), Meilisearch, Docker.
- **Config**: Uses development `docker-compose.yml`.
- **Auth**: `Bearer <token>`.
- **Validation**: `go-playground/validator`.
