# Verse 🎵

> **Free, real-time synchronized lyrics and Dynamic Island notch player for macOS 14+**

[![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B%20Sonoma%20%2F%20Sequoia-black?style=flat&logo=apple)](https://www.apple.com/macos/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat&logo=swift&logoColor=white)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zero External Dependencies](https://img.shields.io/badge/Dependencies-Zero-success.svg)](#architecture--tech-stack)
[![Lyrics by LRCLIB](https://img.shields.io/badge/Lyrics-LRCLIB-blueviolet.svg)](https://lrclib.net)
[![Privacy 100% Local](https://img.shields.io/badge/Privacy-100%25%20Local-brightgreen.svg)](#privacy--security)

**Verse** transforms your MacBook’s display notch into an interactive Dynamic Island music hub with synchronized, word-by-word karaoke-style lyrics, audio-reactive desktop light effects, vinyl turntable widgets, Bluetooth latency compensation, and a 100% private listening diary.

Built natively in pure Swift & SwiftUI with **zero external dependencies**, **zero configuration**, and **zero accounts or API keys required**.

---

```
                       MacBook Display Notch
                   ┌───────────────────────────┐
      [Cover Art]  │     Camera & Sensors      │  [||||] Equalizer
     ──────────────┴───────────────────────────┴──────────────────
                  "Somewhere only we know..."
               ◄── Live Synced Lyric Subtitle ──►
```

---

## ✨ Features at a Glance

### 🏝️ Dynamic Island & True Notch Geometry
- **Hardware-Aware Notch Integration**: Uses macOS display auxiliary area APIs (`auxiliaryTopLeftArea` / `auxiliaryTopRightArea`) to query real camera cutout geometry:
  - **Left Ear**: Displays current album artwork (or music source badge when expanded).
  - **Center Cutout**: Accurately offset with zero content hidden beneath the physical camera housing.
  - **Right Ear**: Real-time animated audio equalizer bars and live weather indicator.
  - **Lyric Subtitle**: Live synced lyrics positioned cleanly beneath the notch.
- **Floating Island Mode**: Automatically selected for external displays, Mac mini, Mac Studio, Mac Pro, and non-notch MacBooks. Renders as a floating pill capsule.
- **Hover-to-Expand**: Glide your cursor over the notch or island (or click) to reveal full media controls:
  - High-resolution album artwork with optional atmospheric background art effects
  - Interactive scrubbable seek bar with live timestamp readouts
  - Play, pause, previous, next, and mini volume slider
  - Dual-line synchronized lyric preview (current active line + upcoming line)
  - 6-hour weather forecast strip

---

### 🎤 22 Cinematic Lyric Themes
Verse includes 22 typography and animation themes that dynamically adapt to the color palette extracted from your currently playing album artwork:

| Theme | Aesthetic & Behavior |
|---|---|
| **Big Words** | Ultra-bold typography focusing on the active line with ambient artwork glow. |
| **Big Lines** | Full-width high-contrast lyrics with smooth multi-line vertical transitions. |
| **Karaoke** | Real-time gradient fill that sweeps left-to-right across words as they are sung. |
| **Wave** 🌊 | Words bob on organic liquid waves, illuminating on the beat with buoyant physics. |
| **Pop** 🎈 | Word-by-word bouncy speech bubble bursts that explode rhythmically with the lyrics. |
| **Echo** 🔊 | Concentric acoustic depth ripples reverberating behind the active lyric line. |
| **Cinema** 🎬 | Letterboxed 2.39:1 widescreen view with progress timestamps and subtitle typography. |
| **Liquid** 💧 | Shifting multi-color iridescent fluid sweeping across bold letters. |
| **Synthwave** 🕹️ | Neon-drenched 80s wireframe grid with glowing sunset and perspective lines. |
| **Vinyl** 💽 | Real-time spinning vinyl turntable disc floating alongside the active verse. |
| **Glitch** ⚡ | Cyberpunk RGB color splitting and chromatic aberration on lyric changes. |
| **Orbit** 🪐 | Words revolve around a 3D elliptical planetary trajectory, bringing the sung word forward. |
| **Aura** | Living ambient backdrop with three fluid, blurred color orbs orbiting to the music. |
| **Stars** | Twinkling particle starfield where sung words illuminate as celestial stars. |
| **Terminal** | Retro monospaced command-line hacker aesthetic. |
| **Neon** | Vibrant glowing neon-tube outlines pulsing with track energy. |
| **Metric** | High-tech audio telemetry HUD displaying elapsed/remaining time and line durations. |
| **Jumble** | Playful typographic layout with randomized angles and dynamic scattering. |
| **Minimal** | Clean, distraction-free typography on ultra-thin frosted glass. |
| **Lens** | Spotlight gradient highlighting the current lyric line while dimming surroundings. |
| **Typewriter** | Tactile mechanical typewriter aesthetic with monospaced character pacing. |
| **Poster** | Bold editorial Swiss-style graphic design layout. |

---

### ⚡ Audio-Reactive Edge Glow
Turn your entire display into an ambient music visualizer:
- **Live System Audio Analysis**: Powered by Apple's `ScreenCaptureKit` (`AudioReactor`), Verse analyzes output audio in real time to detect low-end bass kicks and energy peaks without using your microphone.
- **5 Glow Styles**:
  - **Border Glow**: Sleek perimeter stroke pulsing to the rhythm.
  - **Ripple**: Concentric shockwaves propagating inward from the screen borders.
  - **Spectrum**: Equalizer bars dancing along display edges.
  - **Corner Flares**: Explosive light bursts from the four corners on heavy bass drops.
  - **Aurora**: Flowing northern-lights ambient curtains.
- **4 Beat Sync Modes**:
  - **Live Audio**: Real-time DSP bass beat detection.
  - **Tempo (BPM)**: Rhythmic pulsing synced to track tempo.
  - **Lyric Lines**: Pulses on each new lyric line transition.
  - **Breathing**: Gentle ambient swell.
- **Fine-Tuned Customization**: Adjust intensity, border width, audio sensitivity, and color mode (Album Palette, Rainbow, or custom accents).

---

### 🎨 Atmospheric Album Art Backgrounds
Add rich depth behind lyrics and inside the Island with 6 selectable effects:
- **Aura**: Orbiting, saturated color blur with fluid radial gradients.
- **Soft Blur**: Heavy 60px atmospheric blur.
- **Full Art**: Crisp artwork with subtle gradient vignette.
- **Ken Burns**: Slow, cinematic panning and zoom camera motion.
- **Duotone**: High-contrast black-and-white tinted with the album's primary accent.
- **Split**: Elegant half-and-half gradient fade across the canvas.
- Features dedicated toggles for the Lyrics window and Island, plus an adjustable dimming slider.

---

### 🪟 5 Versatile Display Modes
Switch modes at any time from the menu bar extra or Settings:
1. **Island (Notch)**: Compact or expanded capsule attached to the notch or floating at the top of your display.
2. **Lyrics Window**: A movable, floating window (`760×440`) that stays pinned above your active apps while working or coding, featuring hover-activated top and bottom floating control bars.
3. **Full Screen**: Immersive distraction-free lyric visualizer for parties, sing-alongs, or ambient displays.
4. **Desktop Overlay**: Pins live lyrics directly onto your wallpaper beneath all active windows (`CGWindowLevelForKey(.desktopWindow) + 1`).
5. **Hidden**: Keeps Verse running silently in the background for private listening statistics.

---

### 💽 Desktop Vinyl Widget
- **Interactive Vinyl Turntable**: Sits directly on your desktop wallpaper. The vinyl physically spins in sync with playback, freezes on pause, and tracks seeks:
  - **Turntable**: Includes an animated tonearm that lowers into the groove during playback.
  - **Record Sleeve**: The spinning vinyl disc slides smoothly out of the album cover jacket.
  - **Aura Cover**: Album cover suspended over an ambient glowing color aura.

---

### 📊 Private Local Listening Diary
- **100% Offline & Private**: Stored locally in `~/Library/Application Support/Verse/diary.json`.
- **Zero Telemetry**: No third-party servers, no analytics, no tokens, no tracking.
- **Listening Insights**:
  - Total listening time: **Today**, **This Week**, and **All-Time**.
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
- **1-Click Lyric Card**: Renders a high-resolution 1080×1080 square graphic featuring album artwork, track metadata, color gradient, and current lyrics. Automatically copied to your clipboard and saved to `~/Desktop/Verse – [Song].png`.
- **Dynamic Palette Wallpaper**: Generates an abstract wallpaper matching the extracted dominant color scheme of the currently playing track and applies it to your macOS desktop with a single click.

---

### ⏱️ Latency & Precision Sync Control
- **Per-Song Sync Nudge**: Adjust timing by `±0.1s` or `±1.0s`. Verse automatically remembers offsets per song.
- **Global Bluetooth Delay**: Compensate for audio latency introduced by Bluetooth headphones (e.g., AirPods, Sony WH-1000XM, Bose) with a global delay slider (-5.0s to +5.0s).
- **Smart Duration Fallback**: Verse queries [LRCLIB](https://lrclib.net/) and matches synced lyrics closest to the track duration, preventing drift between radio edits and extended album cuts.

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

If you prefer building manually from terminal:

```bash
# Build release executable
swift build -c release

# Run directly
.build/release/Verse
```

---

## 🔐 Permissions & First Launch

### 1. Automation (Required)
On the first launch, macOS will ask permission to allow **Verse** to control **Spotify** or **Music**:
> **"Verse" wants access to control "Music" / "Spotify".**

1. Click **Allow** / **OK**.
2. If you accidentally clicked "Don't Allow", enable it under:
   - **System Settings** → **Privacy & Security** → **Automation** → Check the box under **Verse** for **Spotify** and **Music**.

### 2. Screen & System Audio Recording (Optional for Audio-Reactive Glow)
To sync Edge Glow with live music output, Verse uses Apple's `ScreenCaptureKit` loopback audio capture.
- Enable under: **System Settings** → **Privacy & Security** → **Screen & System Audio Recording** → Allow **Verse**.
> *Note: Verse only captures system audio output (never the microphone or screen contents), converts sample buffers directly to instantaneous energy levels in memory, and immediately discards them. Nothing is ever saved or transmitted.*

---

## 🧭 How to Use Verse

### Quick Actions via Menu Bar
Click the Verse icon in your menu bar (`music.note.list`) to:
- See the current playing track with album art, equalizer, seek bar, and transport controls
- Switch display modes (**Island**, **Lyrics window**, **Full screen**, **Desktop**, **Hidden**)
- Change the lyric theme with live preview
- Toggle album art background effects, Edge Glow styles, and Desktop Record widget
- Fine-tune sync timing (`-1s`, `-0.1s`, `+0.1s`, `+1s`, `Reset`)
- **Copy lyric card** to clipboard & Desktop
- **Set wallpaper from album colours**
- Open **Settings…** or **Quit**

### Settings Navigation
Preferences are organized into a modern macOS `NavigationSplitView` with 7 dedicated tabs:
- **General**: Display mode picker, launch at login toggle, edge glow toggle, desktop vinyl widget styles, and quick tools.
- **Lyric Themes**: Visual grid gallery of all 22 themes with live interactive preview tiles, typography settings (font style, text size, alignment, uppercase, scatter, lean, accent color), and global latency delay.
- **Album Art**: Background album art settings with 6 visual effects (Aura, Soft blur, Full art, Ken Burns, Duotone, Split), dimming slider, and separate toggles for Lyrics window and Island.
- **Edge Glow**: Style picker (Border, Ripple, Spectrum, Corner flares, Aurora), beat sync modes, color scheme, intensity, width, audio sensitivity, and beat tester.
- **Island**: Shape selector (Classic Notch vs Floating Pill), hover expansion toggle, and Open-Meteo weather city configuration (°C / °F).
- **Diary**: Personal scrobbling metrics (today, past week, all time) and top artists/songs charts.
- **About**: Credits, source information, and API attribution.

---

## 🛠️ Architecture & Tech Stack

Verse is built with performance and battery efficiency as primary design goals:

```
Sources/Verse/
├── VerseApp.swift       # Application delegate, NSPanel windowing & lifecycle
├── Core.swift           # Notch geometry (NotchInfo), color extraction & fonts
├── NowPlaying.swift     # Spotify & Apple Music AppleScript polling engine
├── Lyrics.swift         # LRCLIB API client, LRC parser & sync store
├── LyricsChrome.swift   # Hover-activated floating control bars for lyrics
├── Themes.swift         # 22 typography lyric themes & theme rendering container
├── Art.swift            # Atmospheric background album art effects (Aura, Ken Burns, etc.)
├── Island.swift         # Dynamic Island (Notch & Floating), seeker & media controls
├── Glow.swift           # ScreenCaptureKit live audio reactor & edge glow renderer
├── Record.swift         # Vinyl record desktop widget (Turntable, Sleeve, Aura)
├── MenuView.swift       # Menu bar extra popover with player & toggles
├── Settings.swift       # NavigationSplitView settings tabs & theme galleries
├── Weather.swift        # Open-Meteo geocoding & forecast client
├── Diary.swift          # Local JSON scrobbler & listening analytics
└── Share.swift          # 1080x1080 lyric card & desktop wallpaper generator
```

- **AppKit + SwiftUI Hybrid**: Utilizes `NSPanel` with `.statusBar` and `.nonactivatingPanel` styles, configured with `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]` so the island and widgets persist across all macOS virtual spaces without stealing window focus.
- **Hardware Notch Alignment**: `NotchInfo` inspects `NSScreen.main?.safeAreaInsets.top` and `auxiliaryTopLeftArea` / `auxiliaryTopRightArea` to determine physical notch margins dynamically, ensuring zero UI clipping across 14" and 16" MacBook Pro models or MacBook Airs.
- **Dominant Color Extraction**: Custom RGB/HSV color quantization algorithm in `Core.swift` that downsamples artwork bitmaps to 24×24 pixels, calculates saturation-weighted hue distribution, and extracts up to 3 dominant theme colors.
- **Low-Overhead Live Audio**: `AudioReactor` runs on a dedicated background dispatch queue using `ScreenCaptureKit` to sample audio frames with zero UI thread contention.
- **Zero Third-Party Packages**: Everything uses native Apple frameworks (`AppKit`, `SwiftUI`, `ScreenCaptureKit`, `Combine`, `ServiceManagement`, `Foundation`).

---

## ❓ Frequently Asked Questions

<details>
<summary><strong>What if lyrics are slightly ahead or behind the music?</strong></summary>

- **Per-song adjustment**: Open the menu bar or Lyrics window and use the `−0.1s` / `+0.1s` or `−1s` / `+1s` buttons. Verse remembers this offset specifically for that track.
- **Global Bluetooth headphone delay**: In **Settings → Lyric Themes → Sync**, adjust the **Global lyrics delay** slider (e.g. `+0.3s`) to compensate for Bluetooth audio latency across all songs.
</details>

<details>
<summary><strong>Does Verse work on external monitors or Macs without a notch?</strong></summary>

Yes! On Macs without a notch or on external monitors, Verse automatically activates **Floating Pill** mode. You can also explicitly toggle between **Notch** and **Floating pill** in **Settings → Island**.
</details>

<details>
<summary><strong>Why does macOS prompt for Automation permission?</strong></summary>

macOS requires user permission for apps that send AppleScript events to other applications (`NSAppleEventsUsageDescription`). Verse only uses AppleScript to read the currently playing track title, artist, album, duration, playback position, and album art from Spotify and Apple Music, and to send standard playback commands (play, pause, next, previous, volume).
</details>

<details>
<summary><strong>How do I completely uninstall Verse?</strong></summary>

To remove Verse and all its locally cached settings and diary data:
```bash
rm -rf /Applications/Verse.app
rm -rf ~/Library/Application\ Support/Verse
defaults delete com.local.verse
```
</details>

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
