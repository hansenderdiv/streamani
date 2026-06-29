# AniStream — Native iOS Anime & Movie Streaming App

![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)
![License](https://img.shields.io/badge/License-MIT-green)
![Build](https://github.com/YOUR_USERNAME/AniStream/actions/workflows/build.yml/badge.svg)

Ein vollständig nativer iOS Anime- und Film-Streaming-Client mit modernem Apple-Design, Dark Mode, Glassmorphism-Elementen und einem integrierten Stream-Link-Sniffer.

---

## Features

| Feature | Beschreibung |
|---|---|
| **Home Screen** | Featured-Banner-Karussell, Trending Now & Neu hinzugefügt |
| **Suche & Filter** | Volltextsuche mit Genre-, Jahr- und Typ-Filtern |
| **Release-Kalender** | Wöchentliche Übersicht aller Anime-Episoden mit GerDub/Sub-Fokus |
| **Watchlist** | Lokale SwiftData-Datenbank für persönliche Merkliste |
| **Verlauf** | Automatische Fortschrittsspeicherung mit Fortschrittsbalken |
| **Stream-Sniffer** | WKWebView-basierter Link-Sniffer mit JavaScript-Injection |
| **AVPlayer** | Nativer iOS-Videoplayer mit Custom Controls, AirPlay & Geschwindigkeitssteuerung |

---

## Architektur

```
AniStream/
├── AniStreamApp.swift          # App-Einstiegspunkt, SwiftData Container
├── ContentView.swift           # Haupt-TabView Navigation
├── Models/
│   └── AnimeModels.swift       # Datenmodelle (Anime, Episode, Stream, SwiftData)
├── ViewModels/
│   ├── HomeViewModel.swift     # Home-Screen Logik
│   ├── SearchViewModel.swift   # Suche & Filter mit Combine
│   ├── CalendarViewModel.swift # Release-Kalender Logik
│   └── PlayerViewModel.swift  # AVPlayer Steuerung & Stream-State
├── Views/
│   ├── Components/
│   │   └── AnimeCardView.swift # Wiederverwendbare UI-Komponenten
│   ├── Home/
│   │   ├── HomeView.swift      # Home-Screen mit Hero-Karussell
│   │   └── AnimeDetailView.swift # Detailseite mit Episodenliste
│   ├── Search/
│   │   └── SearchView.swift    # Suche mit Filter-Sheet
│   ├── Calendar/
│   │   └── CalendarView.swift  # Wöchentlicher Release-Kalender
│   ├── Watchlist/
│   │   └── WatchlistView.swift # Watchlist & Verlauf (SwiftData)
│   └── Player/
│       └── VideoPlayerView.swift # AVPlayer + WebView-Sniffer
└── Services/
    ├── MockDataService.swift   # Beispieldaten (durch echte API ersetzen)
    └── StreamSniffer.swift     # WKWebView Link-Sniffer mit JS-Injection
```

---

## Stream-Sniffer Funktionsweise

Der `StreamSniffer` ist das Herzstück der App. Er funktioniert in mehreren Schichten:

1. **WKWebView laden**: Die Provider-URL (VOE, Vidmoly, Vidoza etc.) wird in einem unsichtbaren WKWebView geladen.
2. **JavaScript-Injection**: Ein umfangreiches JS-Skript wird injiziert, das:
   - `XMLHttpRequest.open()` überwacht
   - `fetch()` überwacht
   - `<video>` Elemente und deren `src`-Attribut beobachtet
   - DOM-Mutationen für neue Video-Elemente überwacht
3. **Provider-spezifische Extraktion**: Zusätzliche Skripte für VOE, Vidmoly und Vidoza.
4. **URL-Übergabe**: Sobald eine `.m3u8` oder `.mp4` URL gefunden wird, wird sie via `WKScriptMessageHandler` an Swift übergeben.
5. **AVPlayer**: Die saubere Stream-URL wird direkt an `AVPlayer` übergeben — ohne Werbung, ohne Popups.

---

## Unterstützte Stream-Anbieter

| Anbieter | Typ | Status |
|---|---|---|
| VOE.sx | HLS (.m3u8) | Unterstützt |
| Vidmoly | HLS (.m3u8) | Unterstützt |
| Vidoza | MP4 | Unterstützt |
| DoodStream | HLS | Generisch |
| Streamtape | MP4 | Generisch |
| Filemoon | HLS | Generisch |

---

## Installation via SideStore

### Methode 1: GitHub Actions (Empfohlen)

1. Repository forken oder klonen
2. Auf GitHub navigieren → **Actions** Tab
3. Workflow **"Build AniStream IPA"** manuell starten (oder auf Push warten)
4. Nach erfolgreichem Build: **Artifacts** → `AniStream-unsigned-ipa` herunterladen
5. `AniStream.ipa` in SideStore importieren und installieren

### Methode 2: Lokal bauen

```bash
# 1. Repository klonen
git clone https://github.com/YOUR_USERNAME/AniStream.git
cd AniStream

# 2. Archive erstellen (unsigned)
xcodebuild archive \
  -project AniStream.xcodeproj \
  -scheme AniStream \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath ./build/AniStream.xcarchive \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# 3. IPA erstellen
mkdir -p ./build/Payload
cp -r ./build/AniStream.xcarchive/Products/Applications/AniStream.app ./build/Payload/
cd ./build && zip -r AniStream.ipa Payload/
```

---

## Anforderungen

| Komponente | Version |
|---|---|
| iOS | 17.0+ |
| Xcode | 15.0+ |
| Swift | 5.9+ |
| macOS (Build) | 14.0+ (Sonoma) |

---

## Echte API-Integration

Um die App mit echten Daten zu verbinden, ersetze `MockDataService.swift` durch eine echte API-Implementierung:

```swift
// Beispiel: Eigene Backend-API
final class AnimeAPIService {
    func fetchTrending() async throws -> [Anime] {
        let url = URL(string: "https://your-api.com/anime/trending")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Anime].self, from: data)
    }
}
```

---

## Lizenz

MIT License — Siehe [LICENSE](LICENSE) für Details.

---

> **Hinweis**: Diese App ist für den persönlichen Gebrauch konzipiert. Stelle sicher, dass du nur auf Inhalte zugreifst, für die du die entsprechenden Rechte besitzt.
