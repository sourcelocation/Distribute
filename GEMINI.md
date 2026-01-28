# Project Distribute (Frontend)

**Client (Flutter)**
- **Core**: Offline-first music player using Bloc & `go_router`.
- **Data**: Local SQLite (Drift) handles offline data; syncs via `SyncQueue` to backend. Doesn't sync every data model from server, only the required ones for offline-first functionality.
- **Data**: Playlists, folders, artists, albums, songs.
- **UI**: This app uses `AppIcons` class for cross-platform icons. 

Note on freezed: recent versions require `abstract` keyword before class names to avoid errors.

**Backend (Go)**
- **Role**: Self-hosted, decentralized streamer; manages auth (JWT), files, & search.
- **Sync**: Acts as source of truth for client's offline-first push/pull sync.