# Verse 🎵

> **Free, real-time synchronized lyrics, Dynamic Island notch player, Lock Screen hub, and audio visualizer for macOS 14+**

[![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B%20Sonoma%20%2F%20Sequoia-black?style=flat&logo=apple)](https://www.apple.com/macos/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat&logo=swift&logoColor=white)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zero External Dependencies](https://img.shields.io/badge/Dependencies-Zero-success.svg)](#architecture--tech-stack)
[![Lyrics by LRCLIB](https://img.shields.io/badge/Lyrics-LRCLIB-blueviolet.svg)](https://lrclib.net)
[![Privacy 100% Local](https://img.shields.io/badge/Privacy-100%25%20Local-brightgreen.svg)](#privacy--security)

**Verse** transforms your Mac into an immersive music experience with 35 synchronized lyric themes, a hardware-aligned Dynamic Island notch player, interactive Lock Screen widgets, audio-reactive ambient edge lighting, fine art wallpapers, tactile typing feedback, and a 100% offline listening diary.

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

### 🎤 35 Distinctive Cinematic Lyric Themes
Every theme in Verse is designed with its own unique layout, motion identity, graphical embellishments, and dynamic color adaptation:

| Theme | Aesthetic & Behavior |
|---|---|
| **Cassette** 📼 | Vintage 1980s Walkman cassette tape with dual spinning geared sprockets, moving magnetic tape, mixtape label, and tape counter. |
| **Spotlight** 🔦 | Moody theatrical overhead spotlight cutting through atmospheric haze with floor light pool, cast shadow, and illuminated lyrics. |
| **Magazine** 📰 | High-fashion editorial spread with oversized volume index, two-column grid, giant drop-cap initials, and barcode accents. |
| **Classic Pod** 📱 | Nostalgic 2000s iPod Classic with backlit LCD display, classic Chicago typography, diamond playback scrubber, and click wheel. |
| **Matrix** 🟢 | Digital rain canvas with streaming phosphor green katakana/hex glyphs and prompt cursor where lyric lines materialize. |
| **Radar** 📡 | Tactical aviation/sonar circular scope with 360° sweeping phosphor beam line, range rings, and words detected as sonar blips. |
| **CD Disc** 💿 | Picture-disc compact disc with live spinning album artwork, shimmering rainbow diffraction reflections, data tracks, and clear spindle hub. |
| **Stars** ✨ | Fluid celestial constellation where lyrics ignite as glowing star beacons connected by traveling photon energy beams (with sub-frame sync). |
| **Neon** 💡 | Retro neon sign on dark acrylic mount with luminous tube glow, white-hot filament core, and live on-air indicator. |
| **Minimal** 🫧 | Continuous vertical flowing lyric stream (Apple Music style) with active line sharp and surrounding lines gently blurred. |
| **Quantum** ⚛️ | High-energy 3D tilted electron orbital rings with revolving subatomic particles and live quantum telemetry. |
| **Zen** 🎋 | Japanese minimalist sumi-e ink wash divider with light calm typography, water-drop accent, and serene pacing. |
| **Cinema** 🎬 | Anamorphic 2.39:1 widescreen bars with running live audio waveform oscilloscope, film timecode, and cinematic subtitle italics. |
| **Synthwave** 🕹️ | Neon Outrun 1984 wireframe horizon grid speeding into distance with glowing segmented vector sunset. |
| **Vinyl** 💽 | High-fidelity spinning vinyl record turntable with micro-grooves, light gleams, tone-arm, and side lyrics. |
| **Karaoke** 🎤 | Real-time gradient fill that sweeps left-to-right across words as they are sung. |
| **Cyberpunk** ⚡ | Neon HUD layout with futuristic system telemetry, bracket framing, and dual-tone chromatic glow. |
| **Whisper** 🌫️ | Multi-line focal depth where inactive verses blur gently into the atmospheric background. |
| **Prism** 🌈 | Rhythmic chromatic aberration splitting into RGB channels on active lines. |
| **Aurora** 🌌 | Shimmering multi-hue gradient typography inspired by the northern lights. |
| **Wave** 🌊 | Words bob on organic liquid waves, illuminating on the beat with buoyant physics. |
| **Pop** 🎈 | Word-by-word bouncy speech bubble bursts that explode rhythmically with the lyrics. |
| **Echo** 🔊 | Concentric acoustic depth ripples reverberating behind the active lyric line. |
| **Liquid** 💧 | Shifting multi-color iridescent fluid sweeping across bold letters. |
| **Glitch** 👾 | Cyberpunk RGB color splitting and scanline chromatic aberration on lyric changes. |
| **Orbit** 🪐 | Words revolve around a 3D elliptical planetary trajectory, bringing the sung word forward. |
| **Aura** 🔮 | Living ambient backdrop with three fluid, blurred color orbs orbiting to the music. |
| **Terminal** 💻 | Retro monospaced command-line hacker aesthetic with live cursor blocks. |
| **Metric** ⏱️ | High-tech audio telemetry HUD displaying elapsed/remaining time, W/S tempo, and line durations. |
| **Jumble** 🎲 | Playful typographic layout with randomized angles and dynamic scattering. |
| **Big Words** 💥 | Kinetic word-by-word bold poster with dynamic rotation and scale pops. |
| **Big Lines** 📜 | Full-width high-contrast lyrics with smooth multi-line vertical transitions. |
| **Lens** 🔍 | Spotlight gradient highlighting the current lyric line while dimming surroundings. |
| **Typewriter** ⌨️ | Tactile mechanical typewriter aesthetic with monospaced character pacing. |
| **Poster** 📐 | Bold editorial Swiss-style graphic design layout. |

---

### 🔒 macOS Lock Screen Music Player & Face Unlock
- **Lock Screen Music Widget**: Displays an interactive music player directly beneath the macOS lock screen clock whenever audio is playing:
  - **3 Display Modes**: Rotating **Vinyl Turntable**, **High-Res Artwork**, or **Live Synced Lyrics**.
  - **Full Playback Controls**: Previous, Play/Pause with glowing button, and Next.
  - **Interactive Mode Switching**: Click anywhere on the lock screen widget to cycle between turntable, artwork, and lyrics.
  - **Desktop Preview**: Test and adjust your lock screen look anytime with the in-app preview toggle in Settings.
- **Face Unlock (Beta)**:
  - Uses the built-in FaceTime HD camera and Apple Vision framework (`VNDetectFaceRectanglesRequest`) to detect the user's face at the lock screen.
  - Automatically unlocks your Mac using locally encrypted Keychain credentials.
  - **100% Local Security**: Password never leaves your machine; camera frames are processed ephemerally in-memory and immediately discarded.

---

### ⌨️ Michael (Typing Buddy)
- **Real-Time WPM Speedometer**: Calculates typing speed (Words Per Minute) in real time and tracks lifetime keystrokes.
- **Interactive Bouncing Keycap**: 3D keycap icon that physically animates on every keypress.
- **4 Tactile Soundpacks**:
  - **Mechanical Tactile Switch**: Satisfying mechanical keyboard clacks.
  - **Vintage Typewriter**: Classic metal hammer strikes.
  - **Retro Terminal Click**: Nostalgic 80s computer clicks.
  - **Silent**: Visual and haptic feedback without sound.
- **Privacy Guarantee**: Verse only records ephemeral timestamps to compute speed—it **never** reads, logs, or stores typed characters.

---

### 🖼️ Curated Fine Art Wallpapers & Palette Generator
- **Masterpiece Gallery**: Built-in collection of 8 fine art masterpieces adapted for modern displays:
  - *The Starry Night* (Vincent van Gogh, 1889)
  - *Water Lilies* (Claude Monet, 1916)
  - *The Great Wave off Kanagawa* (Katsushika Hokusai, 1831)
  - *Wanderer above the Sea of Fog* (Caspar David Friedrich, 1818)
  - *The Kiss* (Gustav Klimt, 1908)
  - *Girl with a Pearl Earring* (Johannes Vermeer, 1665)
  - *Impression, Sunrise* (Claude Monet, 1872)
  - *Composition VIII* (Wassily Kandinsky, 1923)
- **Auto-Cycle Timer**: Automatically rotates your wallpaper **Hourly**, **Daily**, or on track change.
- **Album Palette Wallpaper**: 1-click generation of abstract blurred wallpapers matching the currently playing album's dominant colors.

---

### ⚡ Audio-Reactive Beat Glow
Turn your entire display into an ambient music visualizer:
- **Live System Audio Analysis**: Powered by Apple's `ScreenCaptureKit` (`AudioReactor`), Verse analyzes output audio in real time to detect low-end bass kicks and energy peaks without using your microphone.
- **5 Glow Styles**:
  - **Border Glow**: Sleek perimeter stroke pulsing to the rhythm.
  - **Ripple**: Concentric shockwaves propagating inward from the screen borders.
  - **Spectrum**: Equalizer bars dancing along display edges.
  - **Corner Flares**: Explosive light bursts from the four corners on heavy bass drops.
  - **Aurora**: Flowing northern-lights ambient curtains.
- **4 Beat Sync Modes**: **Live Audio** (DSP bass beat detection), **Tempo (BPM)**, **Lyric Lines**, or **Breathing (Smooth)**.
- **Fine-Tuned Customization**: Adjust intensity, border width, audio sensitivity, and color mode (Album Palette, Rainbow, or custom accents).

---

### 🎨 Atmospheric Album Art Backgrounds
Add rich visual depth behind lyrics and inside the Island with 6 selectable effects:
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
- **CoreAudio AirPods Monitor**: Real-time detection of connected AirPods and Beats devices.
- **Smart Duration Fallback**: Verse queries [LRCLIB](https://lrclib.net/) and matches synced lyrics closest to the track duration, preventing drift between radio edits and extended album cuts.

---

### 🔄 Over-The-Air (OTA) Updates
- **Automatic GitHub Releases Integration**: Automatically queries GitHub for newer releases without requiring external package managers or manual re-downloads.
- **Semantic Version Detection**: Compares installed build numbers against GitHub release tags (`v2.1` > `2.0`).
- **Direct In-App Download & Extraction**: Downloads `.zip` release assets with real-time progress bars, extracts the updated binary via `/usr/bin/ditto`, and validates bundle integrity.
- **1-Click Self-Relaunch**: Gracefully quits and restarts Verse with the newly updated version in-place.
- **Changelog Disclosure**: Expandable in-app release notes viewer right inside **Settings → About** and **Settings → General**.

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

### 🚀 Releasing Updates (Automated Methods)

Verse supports two fully automated workflows for shipping Over-The-Air updates:

#### ⚡ Method 1: Local 1-Command Release (`release.sh`)
Builds, signs, upgrades your local `/Applications/Verse.app`, packages `Verse.zip`, tags git, and pushes to GitHub in one command:

```bash
./release.sh <version> ["Optional release notes"]

# Example:
./release.sh 2.1 "Picture Disc CD theme, battery optimizations & bug fixes"
```

**What `./release.sh` executes automatically:**
1. **Version Bumping**: Updates `CFBundleShortVersionString` and `CFBundleVersion` in `build.sh` and `AppInfo.version` in `Sources/Verse/Core.swift`.
2. **Production Compilation**: Builds release binary (`swift build -c release`) and codesigns `Verse.app`.
3. **Archive Generation**: Packages `Verse.zip` using Apple `/usr/bin/ditto` (preserving file modes, symlinks, and code signature hashes).
4. **Local In-Place Upgrade**: If `/Applications/Verse.app` exists on your Mac, it gracefully terminates the old process, replaces the app bundle, strips quarantine attributes, and relaunches the new version.
5. **Git Version Tagging**: Commits version changes, creates an annotated git tag (e.g. `v2.1`), and pushes both `main` and the tag to GitHub.
6. **Release Publishing**:
   - If GitHub CLI (`gh`) is installed: Publishes the GitHub release and attaches `Verse.zip` immediately.
   - If `gh` is not installed: Pushing the tag automatically triggers **Method 2 (GitHub Actions)** in the cloud.

---

#### ☁️ Method 2: Cloud CI/CD Automation (GitHub Actions)
Builds, packages, and attaches `Verse.zip` directly on GitHub's cloud runners whenever a version tag is pushed:

```bash
# Push any version tag to trigger cloud release:
git tag v2.1
git push origin v2.1
```

Or trigger it on the web:
1. Navigate to your repository on GitHub: **Actions** → **Release Verse** → **Run workflow**.
2. Enter the version tag (e.g. `v2.1`) and click **Run workflow**.

**What the Cloud Pipeline ([.github/workflows/release.yml](.github/workflows/release.yml)) does:**
1. Spins up a clean Apple Silicon runner (`macos-14`).
2. Checks out the repository and compiles the release binary via Swift Package Manager.
3. Packages `Verse.app` with icons, entitlements, and ad-hoc code signature.
4. Zips `Verse.app` into `Verse.zip`.
5. Creates the GitHub Release, attaches `Verse.zip`, and automatically generates release notes from your commit history.

---

### Building via Swift Package Manager

If you prefer building manually from terminal:

```bash
# Build release executable
swift build -c release

# Run directly
.build/release/Verse
```

---

## 🔐 Permissions & Privacy

### 1. Automation (Required for Music Control)
On first launch, macOS will request permission to allow Verse to read currently playing track information:
- **System Settings** → **Privacy & Security** → **Automation** → Allow **Verse** for **Spotify** and **Music**.

### 2. Screen & System Audio Recording (Optional for Audio-Reactive Glow)
To sync Edge Glow with live music output, Verse uses Apple's `ScreenCaptureKit` loopback audio capture:
- **System Settings** → **Privacy & Security** → **Screen & System Audio Recording** → Allow **Verse**.
> *Note: Verse only captures system audio output (never the microphone or screen contents), converts sample buffers directly to instantaneous energy levels in memory, and immediately discards them.*

### 3. Camera & Keychain (Optional for Face Unlock Beta)
- Requires FaceTime camera access to detect your face on the lock screen.
- User password is stored exclusively in your local encrypted macOS Keychain.

---

## 🧭 Settings Navigation (10 Tabs)

Preferences are organized into a modern macOS `NavigationSplitView` with 10 dedicated sections:
1. **General**: Display mode picker, launch at login toggle, edge glow toggle, desktop vinyl widget styles, and quick tools.
2. **Lyric Themes**: Visual grid gallery of all 28 themes with live interactive preview tiles, typography settings, and global latency delay.
3. **Album Art**: Background album art settings with 6 visual effects (Aura, Soft blur, Full art, Ken Burns, Duotone, Split), dimming slider, and separate toggles.
4. **Beat Glow**: Glow styles (Border, Ripple, Spectrum, Corner flares, Aurora), beat sync modes, color scheme, intensity, width, audio sensitivity, and beat tester.
5. **Island**: Shape selector (Classic Notch vs Floating Pill), hover expansion toggle, and Open-Meteo weather city configuration (°C / °F).
6. **Lock Screen**: Show album player on lock screen, style picker (Turntable, Artwork, Lyrics), desktop preview toggle, and Face Unlock (Beta).
7. **Wallpapers**: Curated fine art wallpaper gallery with auto-cycle timer (Hourly, Daily, on track change).
8. **Typing Buddy**: Michael the Typing Buddy with real-time WPM speedometer, keystroke counter, and 4 mechanical soundpacks.
9. **Diary**: Personal scrobbling metrics (today, past week, all time) and top artists/songs charts.
10. **About**: Credits, source information, and API attribution.

---

## 🛠️ Architecture & Tech Stack

Verse is built with performance, security, and battery efficiency as primary design goals:

```
Sources/Verse/
├── VerseApp.swift       # Application delegate, NSPanel windowing & lifecycle
├── Core.swift           # Notch geometry (NotchInfo), color extraction & fonts
├── NowPlaying.swift     # Spotify & Apple Music AppleScript polling engine
├── Lyrics.swift         # LRCLIB API client, LRC parser & sync store
├── LyricsChrome.swift   # Hover-activated floating control bars for lyrics
├── Themes.swift         # 28 typography lyric themes & theme rendering container
├── Art.swift            # Atmospheric background album art effects (Aura, Ken Burns, etc.)
├── Island.swift         # Dynamic Island (Notch & Floating), seeker & media controls
├── Glow.swift           # ScreenCaptureKit live audio reactor & edge glow renderer
├── Record.swift         # Vinyl record desktop widget (Turntable, Sleeve, Aura)
├── LockScreen.swift     # macOS Lock Screen player & live preview controller
├── FaceUnlock.swift     # FaceTime HD camera & Vision framework face unlock manager
├── Wallpapers.swift     # Fine art masterpiece wallpaper gallery & scheduler
├── TypingBuddy.swift    # Michael typing speed (WPM) monitor & mechanical sound engine
├── AirPods.swift        # CoreAudio AirPods & Beats headphone device detection
├── ScreenWake.swift     # Display wake & sleep event coordinator
├── MenuView.swift       # Menu bar extra popover with player & toggles
├── Settings.swift       # 10-tab NavigationSplitView preferences & live theme previews
├── Weather.swift        # Open-Meteo geocoding & forecast client
├── Diary.swift          # Local JSON scrobbler & listening analytics
└── Share.swift          # 1080x1080 lyric card & desktop wallpaper generator
```

- **AppKit + SwiftUI Hybrid**: Utilizes `NSPanel` with `.statusBar` and `.nonactivatingPanel` styles, configured with `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]` so the island and widgets persist across all macOS virtual spaces without stealing window focus.
- **Hardware Notch Alignment**: `NotchInfo` inspects `NSScreen.main?.safeAreaInsets.top` and `auxiliaryTopLeftArea` / `auxiliaryTopRightArea` to determine physical notch margins dynamically, ensuring zero UI clipping across 14" and 16" MacBook Pro models or MacBook Airs.
- **Dominant Color Extraction**: Custom RGB/HSV color quantization algorithm in `Core.swift` that downsamples artwork bitmaps to 24×24 pixels, calculates saturation-weighted hue distribution, and extracts up to 3 dominant theme colors.
- **Zero Third-Party Packages**: Everything uses native Apple frameworks (`AppKit`, `SwiftUI`, `ScreenCaptureKit`, `Vision`, `AVFoundation`, `CoreAudio`, `AudioToolbox`, `Combine`, `ServiceManagement`, `Foundation`).

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
<summary><strong>How does Lock Screen integration work?</strong></summary>

Verse observes macOS screen lock events via `DistributedNotificationCenter` (`com.apple.screenIsLocked`). When your Mac locks while music is playing, Verse raises a special floating panel to display your choice of vinyl turntable, high-res artwork, or live lyrics directly under the macOS clock. You can test this look anytime using the "Preview Lock Screen Widget" button in **Settings → Lock Screen**.
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
- **Typing Privacy**: The Typing Buddy only counts keystroke intervals ephemerally in-memory to compute WPM—no text is ever read, recorded, or saved.

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
