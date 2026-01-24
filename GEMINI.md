# Project Distribute (Frontend)

**Client (Flutter)**
- **Core**: Offline-first music player using Bloc & `go_router`.
- **Data**: Local SQLite (Drift) handles offline data; syncs via `SyncQueue` to backend. Doesn't sync every data model from server, only the required ones for offline-first functionality.

**Backend (Go)**
- **Role**: Self-hosted, decentralized streamer; manages auth (JWT), files, & search.
- **Sync**: Acts as source of truth for client's offline-first push/pull sync.