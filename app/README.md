<img src="github-assets/banner.png" alt="Distribute Banner" width="100%" />

<div align="center">
  
# Distribute

**Stop renting your music.**  
An offline-first streaming music app that connects to your home server.

<p align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  </a>
  <a href="https://dart.dev">
    <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  </a>
  <a href="https://pub.dev/packages/flutter_bloc">
    <img src="https://img.shields.io/badge/Bloc-State_Management-blue?style=for-the-badge&logo=bloc&logoColor=white" alt="Bloc" />
  </a>
  <a href="https://drift.simonbinder.eu/">
    <img src="https://img.shields.io/badge/Drift-Local_Database-lightgrey?style=for-the-badge&logo=sqlite&logoColor=white" alt="Drift" />
  </a>
</p>

[![Status](https://img.shields.io/badge/Status-Open_Beta-blue?style=flat-square)]()
[![License](https://img.shields.io/badge/License-Open_Source-green?style=flat-square)]()

</div>


## Overview

**Distribute** is a decentralized, offline-first music player designed for those who own their library. It connects directly to your home server, syncing your collection for seamless offline playback.

### 🎧 Features

| Feature | Description |
| :--- | :--- |
| **Offline Ready** | Your library is cached locally on your device. Take your entire collection on the plane, the subway, or into the wild. |
| **Home Server Sync** | Direct connection to your personal storage. Cross-sync servers to expand your library. |
| **Lossless Audio** | The clearest sound with no compromises, powered by a high-performance audio engine. |
| **Privacy Focused** | We don't store, control, or own your data. You host your hub. |


## Screenshots

<img src="github-assets/screenshot1.jpg" alt="Distribute Screenshot" max-width="600px" />

<img src="github-assets/screenshot2.png" alt="Distribute Screenshot" max-width="600px" />

<img src="github-assets/screenshot3.png" alt="Distribute Screenshot" max-width="600px" />


---

## 📀 Download

### Windows, Linux, macOS & Android
Download the latest release from the [releases](https://github.com/ProjectDistribute/Distribute/releases) page.

### iOS
Download from [TestFlight](https://testflight.apple.com/join/DA8bhKJH)

---

## 🛠️ Tech Stack

Distribute is built with a focus on **performance**, **beauty**, and **utility**.

- **App Engine**: [Flutter](https://flutter.dev) (Cross-platform native performance)
- **State Management**: [Bloc](https://bloclibrary.dev) (Predictable state containers)
- **Database**: [Drift](https://drift.simonbinder.eu) (Reactive SQLite for offline caching)
- **Audio**: [SoLoud](https://pub.dev/packages/flutter_soloud) (High-performance audio engine)
- **Networking**: [Dio](https://pub.dev/packages/dio) (Robust HTTP client)

---

## 🗺️ Roadmap

### **v0.2.0** (Current)
- [x] Global Search
- [x] User Request System
- [x] User Authentication
- [x] Song Downloads
- [x] Playlist Management
- [x] Built-in Music Player
- [x] Offline Mode
- [x] Setup Wizard
- [x] Album, artist search

### **v1.0.0**
- [ ] Advanced playlist management (reordering, playlist creation)
- [ ] Song streaming
- [ ] Browse local music files

### **v2.0.0**
- [ ] Cross-server content synchronization
- [ ] Social features (followers, comments)

### **v3.0.0**
- [ ] Music recommendation engine

> **Known Issues**
> - None

---

## 🛠️ Development

### Prerequisites

*   Flutter SDK (v3.40.0-0.2.pre or higher)
*   Dart SDK

### Getting Started

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/ProjectDistribute/Distribute.git
    cd app
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the project:**
    ```bash
    flutter run
    ```

### Code Generation

This project uses `build_runner` for type-safe code generation.

*   **Generate files once:**
    ```bash
    dart run build_runner build -d
    ```

*   **Watch for changes:**
    ```bash
    dart run build_runner watch -d
    ```

### VS Code Setup

To keep your file explorer clean, add this to your `.vscode/settings.json`:

```json
{
    "explorer.fileNesting.patterns": {
        "*.dart": "$(capture).g.dart, $(capture).freezed.dart"
    }
}
```

---

## Disclaimer

**We don't endorse piracy.**
Distribute is built for your owned library. Support the artists you love by purchasing their music.
