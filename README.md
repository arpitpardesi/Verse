# Verse 🎵

> **Free, real-time synchronized lyrics and Dynamic Island notch player for macOS 14+**

[![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B%20Sonoma%20%2F%20Sequoia-black?style=flat&logo=apple)](https://www.apple.com/macos/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat&logo=swift&logoColor=white)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zero External Dependencies](https://img.shields.io/badge/Dependencies-Zero-success.svg)](#architecture--tech-stack)
[![Lyrics by LRCLIB](https://img.shields.io/badge/Lyrics-LRCLIB-blueviolet.svg)](https://lrclib.net)
[![Privacy 100% Local](https://img.shields.io/badge/Privacy-100%25%20Local-brightgreen.svg)](#privacy--security)

Verse turns your MacBook’s display notch into an interactive Dynamic Island music hub with synchronized, word-by-word karaoke-style lyrics, playback controls, desktop widgets, audio latency compensation, and a 100% private listening diary.

Built natively in pure Swift & SwiftUI with **zero external dependencies**, **zero configuration**, and **zero accounts or API keys required**.

---

## ✨ Features at a Glance

### 🏝️ Dynamic Island & Notch Player
- **MacBook Notch Integration**: Sits seamlessly in the "ears" of your MacBook's camera notch with album artwork on the left, an animated visual equalizer on the right, and live lyrics underneath.
- **Floating Island Mode**: Perfect for external monitors, Mac mini, Mac Studio, Mac Pro, and non-notch MacBooks. Renders as a floating pill capsule.
- **Hover-to-Expand**: Glide your cursor over the notch or island to reveal full media controls:
  - High-resolution album artwork & track / artist / album metadata
  - Scrubbable interactive seek bar with live timestamp readouts
  - Play, pause, skip, previous, and volume slider controls
  - Dual-line synchronized lyric preview (current line + upcoming line)
  - Integrated weather forecast strip

---

### 🎤 13 Cinematic Lyric Themes
Verse includes 13 typography and animation themes that adapt to the dominant color palette extracted from your currently playing album artwork:

| Theme | Description |
|---|---|
| **Big Words** | Ultra-bold typography focusing on the active line with ambient artwork glow. |
| **Big Lines** | Full-width high-contrast lyrics with smooth multi-line scrolling. |
| **Karaoke** | Real-time gradient fill that sweeps left-to-right across words as they are sung. |
| **Aura** | Living ambient backdrop with three fluid, blurred color orbs orbiting to the music. |
| **Stars** | Twinkling particle starfield where words in active lines illuminate as bright celestial stars. |
| **Terminal** | Retro monospaced command-line hacker aesthetic. |
| **Neon** | Vibrant glowing neon-tube outlines pulsing with track energy. |
| **Metric** | High-tech audio telemetry HUD displaying elapsed/remaining time and line durations. |
| **Jumble** | Playful typographic layout with randomized angles and dynamic scattering. |
| **Minimal** | Clean, distraction-free typography on ultra-thin frosted glass. |
| **Lens** | Spotlight gradient highlighting the current lyric line while dimming surroundings. |
| **Typewriter** | Tactile mechanical typewriter aesthetic with monospaced character pacing. |
| **Poster** | Bold editorial Swiss-style graphic design layout. |

---

### 🪟 Versatile Display Modes
Switch between viewing modes from the menu bar icon or keyboard settings:
1. **Island (Notch)**: Compact or expanded capsule attached to the notch or floating at the top of your display.
2. **Lyrics Window**: A movable, resizable floating window (`760×440`) that stays above other apps while you work or code.
3. **Full Screen**: Immersive distraction-free lyric visualizer for parties, sing-alongs, or ambient displays.
4. **Desktop Overlay**: Pins live lyrics directly onto your wallpaper beneath all active windows (`CGWindowLevelForKey(.desktopWindow) + 1`).
5. **Hidden**: Keeps Verse running silently in the background for private listening statistics.

---

### 🎨 Desktop Vinyl Widget & Edge Glow
- **Vinyl Record Widget**: An interactive turntable on your desktop wallpaper. The vinyl physically spins in sync with the song’s playback time, pauses when you pause, and jumps when you seek.
  - **Turntable**: Includes an animated tonearm that lowers onto the vinyl when music starts playing.
  - **Record Sleeve**: The spinning vinyl disc slides smoothly out of the album cover jacket.
  - **Aura Cover**: Album cover suspended over an ambient glowing color aura.
- **Ambient Edge Glow**: A soft, border glow that travels smoothly around the perimeter of your entire display, matching the exact color palette of the album art.

---

### 📊 Private Local Listening Diary
- **100% Offline & Private**: Stored locally in `~/Library/Application Support/Verse/diary.json`.
- **Zero Telemetry**: No third-party servers, no analytics, no tokens, no tracking.
- **Stats Dashboard**:
  - Total listening time today, past 7 days, and all-time.
  - Ranked charts for your **Top 5 Artists** and **Top 5 Songs** with visual progress bars.

---

### ⛅ Integrated Weather Forecast
- Free weather integration powered by [Open-Meteo](https://open-meteo.com/) (no API key required).
- Add your city in **Settings → Island** to display:
  - Current temperature & dynamic weather symbol (SF Symbols)
  - Daily high / low temperatures
  - 6-hour hourly temperature forecast strip right inside the expanded Island

---

### 🖼️ Shareable Lyric Cards & Dynamic Wallpapers
- **1-Click Lyric Card (`⌥⌘C` or Menu)**: Renders a high-resolution 1080×1080 square graphic featuring album artwork, track metadata, color gradient, and current lyrics. Automatically copied to your clipboard and saved to `~/Desktop/Verse – [Song].png`.
- **Dynamic Palette Wallpaper**: Generates an abstract wallpaper matching the extracted dominant color scheme of the currently playing track and applies it to your macOS desktop with a single click.

---

### ⏱️ Latency & Precision Sync Control
- **Per-Song Sync Nudge**: Adjust timing by `±0.1s` or `±1.0s`. Verse remembers offsets per song in `UserDefaults`.
- **Global Bluetooth Delay**: Compensate for audio latency introduced by Bluetooth headphones (e.g., AirPods, Sony WH-1000XM, Bose) with a global delay slider (-5.0s to +5.0s).
- **Smart Duration Fallback**: Verse queries [LRCLIB](https://lrclib.net/) and automatically matches synced lyrics closest to the track duration, preventing drift between radio edits and extended album cuts.

---

## 🎧 Supported Music Players

Verse automatically monitors and synchronizes with:
- **Spotify** (official macOS desktop app)
- **Apple Music** (native macOS Music app)

When music starts playing in either app, Verse detects the active player automatically via lightweight AppleScript bridging.

---

## 🚀 Quick Start

### Prerequisites
- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1/M2/M3/M4) or Intel Mac
- Xcode Command Line Tools:
  ```bash
  xcode-select --install
  ```

### Installation (1-Command Build)

Clone this repository and run the included build script:

```bash
git clone https://github.com/arpitpardesi/Verse.git
cd Verse
chmod +x build.sh
./build.sh
```

`build.sh` compiles the release binary via Swift Package Manager, bundles it into a standalone `Verse.app`, signs it ad-hoc, and launches it.

To keep it permanently, drag `Verse.app` to your `/Applications` folder:
```bash
mv Verse.app /Applications/
```

### Building via Swift Package Manager

If you prefer building manually without the app bundle wrapper:

```bash
# Build release executable
swift build -c release

# Run directly
.build/release/Verse
```

---

## 🔐 Permissions & First Launch

On the first launch, macOS will present a permission dialog asking to allow **Verse** to control **Spotify** or **Music**:

> **"Verse" wants access to control "Music" / "Spotify".**

1. Click **Allow** / **OK**.
2. If you accidentally clicked "Don't Allow", you can enable it at any time in:
   - **System Settings** → **Privacy & Security** → **Automation** → Check the box under **Verse** for **Spotify** and **Music**.

---

## 🧭 How to Use Verse

### Menu Bar Extra
Click the Verse icon in your menu bar (represented by `music.note.list`) to:
- View current track info and album thumbnail
- Switch between display modes (**Island**, **Lyrics window**, **Full screen**, **Desktop**, **Hidden**)
- Switch lyric themes instantly
- Nudge sync timing (`-1s`, `-0.1s`, `+0.1s`, `+1s`, `Reset`)
- **Copy lyric card** to clipboard & Desktop
- **Set wallpaper from album colours**
- Open **Settings…** or **Quit**

### Settings Tabs
Access settings from the menu bar or click the gear icon in the expanded island:
- **General**: Display mode picker, launch at login toggle, edge glow toggle, desktop vinyl widget & style picker (Turntable, Sleeve, Aura).
- **Lyrics**: Interactive theme gallery, background style (Theme default, Black, Blurred cover, Glass), font styling (Rounded, Serif, Mono, System), alignment, accent colors, UPPERCASE switch, scale/scatter/lean sliders, and global latency delay slider.
- **Island**: Shape selector (Classic Notch vs Floating Pill), hover expansion toggle, and Open-Meteo weather city configuration (°C / °F).
- **Diary**: Personal scrobbling metrics (today, past week, all time) and top artists/songs charts.
- **About**: Credits, source information, and API attribution.

---

## 🛠️ Architecture & Tech Stack

Verse is built with performance and battery life as primary goals:

```
Sources/Verse/
├── VerseApp.swift     # Application delegate, NSPanel windowing & MenuBarExtra
├── Core.swift         # Color palette extraction, dynamic fonts & helper utilities
├── NowPlaying.swift   # Spotify & Apple Music AppleScript polling engine
├── Lyrics.swift       # LRCLIB API client, LRC parser & sync store
├── Themes.swift       # 13 typography lyric themes & theme rendering container
├── Island.swift       # Dynamic Island (Notch & Floating), seeker & media controls
├── Record.swift       # Vinyl record desktop widget & animated edge glow
├── Diary.swift        # Local JSON scrobbler & listening analytics
├── Weather.swift      # Open-Meteo geocoding & forecast client
├── Settings.swift     # SwiftUI Preferences tabs & live theme previews
└── Share.swift        # 1080x1080 lyric card & desktop wallpaper generator
```

- **AppKit + SwiftUI Hybrid**: Utilizes `NSPanel` with `.statusBar` and `.nonactivatingPanel` styles, configured with `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]` so the island and widgets persist across all macOS virtual spaces without taking window focus.
- **Dominant Color Extraction**: Custom RGB/HSV color quantization algorithm in `Core.swift` that samples artwork bitmaps down to 24×24 pixels, calculates saturation-weighted hue distribution, and extracts up to 3 harmonious theme colors.
- **Synchronous Animation Engine**: Powered by SwiftUI `TimelineView(.animation)` and `TimelineView(.periodic)` to minimize CPU and GPU overhead when idle.
- **Zero Third-Party Packages**: Everything uses native Apple frameworks (`AppKit`, `SwiftUI`, `Combine`, `ServiceManagement`, `Foundation`).

---

## 🛡️ Privacy & Security

- **No Remote User Data**: Verse has no user accounts, no login forms, and no proprietary backend server.
- **Local Data Only**: Your listening diary is stored exclusively on your Mac in:
  `~/Library/Application Support/Verse/diary.json`
- **Anonymous Lookups**:
  - Lyrics are fetched from [LRCLIB](https://lrclib.net/) using track title and artist name without transmitting personal identifiers.
  - Weather forecasts are fetched from [Open-Meteo](https://open-meteo.com/) using the city name you enter.

---

## 🤝 Contributing

Contributions, bug reports, and theme ideas are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/cool-new-theme`)
3. Commit your changes (`git commit -m 'feat: add retro wave theme'`)
4. Push to the branch (`git push origin feature/cool-new-theme`)
5. Open a Pull Request

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙏 Acknowledgments

- [LRCLIB](https://lrclib.net/) for their free, open community-driven lyrics API.
- [Open-Meteo](https://open-meteo.com/) for open weather and geocoding APIs.
- Apple Music & Spotify macOS developer scripting APIs.
