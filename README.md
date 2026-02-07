# Distribute

<img src="github-assets/banner.png" alt="Distribute Banner" width="100%" />

<div align="center">
  
## Distribute

**Stop renting your music.**  
Distribute is a decentralized, offline-first music player designed for those who own their library. It connects directly to your home server, syncing your collection for seamless offline playback.

</div>

## Features

| Feature | Description |
| :--- | :--- |
| **Offline Ready** | Your library is cached locally on your device. Take your entire collection on the plane, the subway, or into the wild. |
| **Home Server Sync** | Direct connection to your personal storage. Cross-sync servers to expand your library. |
| **Lossless Audio** | The clearest sound with no compromises, powered by a high-performance audio engine. |
| **Privacy Focused** | We don't store, control, or own your data. You host your hub. |


## Showcase

![Distribute screenshot 1](github-assets/screenshot1.jpg)
![Distribute screenshot 2](github-assets/screenshot2.png)
![Distribute screenshot 3](github-assets/screenshot3.png)

## Installation
### App
- Client builds (Windows, Linux, macOS, Android) on the [Distribute releases](https://github.com/ProjectDistribute/Distribute/releases) page.
- iOS beta via [TestFlight](https://testflight.apple.com/join/DA8bhKJH).

### Server
Please see wiki for full instructions: https://distribute-docs.sourceloc.net/docs

## Development

1. Clone this repo.
2. Project structure:

- `app/` – Flutter mobile client (Bloc, Drift). `flutter pub get && flutter run`.
- `api/` – Echo REST server + Meilisearch. `go run .` or `docker compose up` from `api/docker-compose.yml`.
- `admin/` – Vite + React admin console. `npm install && npm run dev`.
- `landing/` – Next.js marketing site. `npm install && npm run dev`.
- `docs/` – Fumadocs site (`source.config.ts`). `npm install && npm run dev`.

3. Pull requests are welcome. For major changes, please contact me first!

Assets (banner + screenshots) live under `github-assets/`.


## Roadmap

- **v1.0 / s1.0** – Artist, album pages; song streaming; mailbox automation.
- **v2.0+** – Cross-server sync; social layers; recommendation engine.

## Disclaimer

We don’t endorse piracy. Distribute is for the music you own—support artists directly.
