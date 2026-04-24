# Luxury Journal — Design Spec

**Status:** approved · **Author:** Utku · **Date:** 2026-04-24 · **Version:** 0.1

## 1. Overview

Luxury Journal is a KDE Plasma 6 dashboard theme that turns the desktop into a
leather-bound journal: parchment wallpaper, oxblood accents, handwritten
labels, classical serif numerals. The original spec (`inst.md`) defines a
three-piece architecture — one color scheme, three fonts, two custom
plasmoids — with the remainder supplied by built-in and KDE-Store widgets.

This design expands that starting point to cover:

- Six custom plasmoids (two from spec + four new).
- An ornate-but-readable visual register with shared QML ornaments (gilt
  double-rules, fleurons, wax seals, page-corner folds).
- Subtle ambient + transition motion across all widgets.
- A hardened install lifecycle (install / uninstall / dev helpers).
- GitHub repository chrome with a linting CI workflow.

## 2. Scope

### 2.1 In scope

- Color scheme: the palette from `inst.md`, unchanged.
- Fonts: nine files — Parisienne, Caveat (variable), Cormorant Garamond
  (Light / Regular / Medium / SemiBold), Cormorant SC (Medium), IM FELL DW
  Pica (Regular), JetBrains Mono (Regular).
- Six custom plasmoids:
  1. Luxury Greeting (`com.utku.luxurygreeting`)
  2. Tmux Tail (`com.utku.tmuxtail`)
  3. Journal Tasks (`com.utku.journaltasks`)
  4. Journal Clock (`com.utku.journalclock`)
  5. Journal Weather (`com.utku.journalweather`)
  6. Journal NowPlaying (`com.utku.journalnowplaying`)
- Shared QML kit: `Palette`, `Ornaments`, `ParchmentBackground`, `MoonPhase`.
- Scripts: `install.sh`, `uninstall.sh`, `dev.sh`.
- Repo chrome: LICENSE (MIT), README, CHANGELOG, ARCHITECTURE doc,
  `.gitignore`, issue + PR templates, lint CI workflow, color-scheme
  validator.

### 2.2 Out of scope

- A plugin framework. Plasma is the framework.
- A shared config file. Each plasmoid uses Plasma's per-instance config.
- Hot-reload of layout. Plasma's Edit Mode owns this.
- Windows / macOS / non-Plasma compatibility.
- Public KDE Store distribution. Personal install only.
- ANSI color rendering in Tmux Tail (v1 strips, deferred).

## 3. Repository Layout

```
luxury-journal/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug.md
│   │   └── feature.md
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/lint.yml
├── docs/
│   ├── ARCHITECTURE.md
│   └── screenshots/
├── plasmoids/
│   ├── com.utku.luxurygreeting/
│   ├── com.utku.tmuxtail/
│   ├── com.utku.journaltasks/
│   ├── com.utku.journalclock/
│   ├── com.utku.journalweather/
│   └── com.utku.journalnowplaying/
├── shared/qml/
│   ├── Palette.qml
│   ├── Ornaments.qml
│   ├── ParchmentBackground.qml
│   └── MoonPhase.qml
├── tools/
│   └── validate_colors.py
├── install.sh
├── uninstall.sh
├── dev.sh
├── luxury-journal.colors
├── .gitignore
├── LICENSE
├── CHANGELOG.md
└── README.md
```

Each plasmoid directory follows `inst.md` conventions:

```
com.utku.<id>/
├── metadata.json
└── contents/
    ├── ui/
    │   ├── main.qml
    │   └── configGeneral.qml
    └── config/
        ├── config.qml
        └── main.xml
```

**Shared QML handling.** Plasma does not provide a sanctioned way to share
QML components across plasmoids in one repository. `install.sh` and `dev.sh`
copy `shared/qml/*` into each plasmoid's `contents/ui/shared/` directory at
install time. The copy is listed in `.gitignore`. The source of truth is
`shared/qml/`.

## 4. Design Tokens

### 4.1 Color scheme file

`luxury-journal.colors` matches `inst.md` byte-for-byte. Ten sections
(`General`, `KDE`, `Colors:Window`, `Colors:View`, `Colors:Button`,
`Colors:Selection`, `Colors:Tooltip`, `Colors:Complementary`,
`Colors:Header`, `WM`) define the six-role palette:

| role | hex | usage |
|---|---|---|
| parchment outer | `#ece0c8` | `Window.BackgroundNormal` |
| parchment panel | `#f2e8d3` | `Window.BackgroundAlternate`, `View.BackgroundAlternate` |
| ink dark | `#2d1810` | `ForegroundNormal` |
| ink medium | `#6b4e36` | `ForegroundInactive` |
| burgundy | `#722529` | decorations, active text, selections |
| gold | `#9e7b3a` | `ForegroundNeutral` (warnings) |
| green | `#4a6b3a` | `ForegroundPositive` |
| red-negative | `#9e3540` | `ForegroundNegative` |

### 4.2 QML-local palette (`shared/qml/Palette.qml`)

A QML singleton that mirrors semantic `Kirigami.Theme.*` lookups and adds
five ornament-only tokens not representable in a Plasma color scheme:

| token | hex | purpose |
|---|---|---|
| `gilt` | `#9a7f3a` | double-rules, page-number dots, fleurons |
| `wax` | `#6e1e23` | seal bodies (darker than burgundy) |
| `paperShadow` | `#c4b498` | widget drop shadows (warm, not black) |
| `inkWet` | `#8a2a2e` | NowPlaying progress leading edge |
| `foxing` | `#b39a72` | subtle age spots on parchment (very low opacity) |

The singleton also exposes `parchment`, `inkDark`, `inkMedium`, `burgundy`
aliases to `Kirigami.Theme.*` so QML files don't mix literal strings with
semantic tokens.

### 4.3 Typography roles

| role | font | weight | used in |
|---|---|---|---|
| Display script | Parisienne | Regular | greeting, NowPlaying track title |
| Handwritten accent | Caveat | Variable | subtitles, weather line, section kickers |
| Body serif | Cormorant Garamond | Regular / Medium | main text, clock digits |
| Display serif (drop-cap) | IM FELL DW Pica | Regular | greeting drop-cap, ornaments |
| Small caps | Cormorant SC | Medium | task section headers |
| Monospace | JetBrains Mono | Regular | tmux, inline code |

Installed to `~/.local/share/fonts/luxury-journal/`. Nine files, ~2 MB total.

### 4.4 Ornament primitives (`shared/qml/Ornaments.qml`)

- `DoubleRule { color; inset }` — two thin gilt lines with 2px gap.
- `Fleuron { glyph }` — centered ornament character (`❦`, `❧`, `§`).
- `WaxSeal { diameter; label }` — wax-colored circle with gilt rim and
  centered IM FELL glyph.
- `PageCorner {}` — top-right SVG fragment suggesting a turned-down corner.
- `ParchmentBackground {}` (separate file) — Rectangle with an SVG
  turbulence-filter noise overlay + optional `foxing` spots.

## 5. Plasmoid Specs

### 5.1 Luxury Greeting — `com.utku.luxurygreeting`

**Layout.** Two lines stacked. Top: drop-cap in IM FELL DW Pica at 56px
(first letter of the greeting, rendered in `wax` with a 6-second subtle
opacity cycle between 0.92 and 1.0) followed by the rest of the phrase in
Parisienne at 44px. Bottom: date + period in Caveat at 16px,
`Kirigami.Theme.disabledTextColor`.

**Greeting pool.** Five phrases per period, four periods:

- `smallHours` (0–5): "Still up, {name}?", "The small hours, {name}.",
  "It is late, {name}.", "Not yet asleep, {name}?", "The lamps are low,
  {name}."
- `morning` (5–12): "Good morning, {name}.", "The day, {name}, begins.",
  "A fresh page, {name}.", "Dawn already, {name}?", "Morning, {name} — the
  coffee first."
- `afternoon` (12–17): "Good afternoon, {name}.", "Midday passes, {name}.",
  "The hours settle, {name}.", "A steady afternoon, {name}.", "The sun
  leans west, {name}."
- `evening` (17–24): "Good evening, {name}.", "Evening, {name} — the day
  closes.", "The lamps come on, {name}.", "A quiet hour, {name}.", "The
  night is yours, {name}."

**Selection.** `phrasePoolSeed + dayOfYear` modulo pool size — same
greeting all day, rotates daily, deterministic.

**Context overlays.** Applied after pool selection; append a clause to the
phrase:

- Monday before noon → "— the week opens."
- Friday after 17:00 → "— the week folds in on itself."
- 1st of the month before noon → "— a fresh chapter."
- User's configured birthday (MM-DD) → replaces the phrase entirely with
  one from a separate birthday pool of three lines.

**Config (`main.xml`).**

- `userName` (String, default "Utku")
- `birthday` (String, default "" meaning disabled, format "MM-DD")
- `phrasePoolSeed` (Int, default 0)

**Ambient.** Drop-cap opacity cycle described above.

### 5.2 Tmux Tail — `com.utku.tmuxtail`

**Layout.** Header row in Caveat 19px: `"// <target>"` in burgundy, or
`"// session not found"` on error. `WaxSeal(diameter=18, label="T")` in
the top-right, tooltip "Double-click to attach". `DoubleRule` below header.
`ScrollView` fills the remaining area with a `TextArea` in JetBrains Mono
11px, `Kirigami.Theme.textColor` ink, read-only, no wrap, auto-scroll on
new content.

**Data.** `Plasma5Support.DataSource` engine `executable` polls
`tmux capture-pane -p -S -<lineCount> -t <target>` at `refreshMs` interval.
Disconnects each source after read.

**ANSI.** Stripped via the regex from `inst.md` (`\x1b\[[0-9;]*m`). Color
rendering deferred to v2.

**Errors.** Exit code non-zero → `sessionFound = false`, header switches to
the "not found" label, widget body renders empty.

**Double-click.** Runs `attachCommand` via the executable engine.

**Config (`main.xml`).**

- `tmuxTarget` (String, default "research:0")
- `lineCount` (Int, default 14)
- `refreshMs` (Int, default 2000)
- `attachCommand` (String, default `konsole -e tmux attach -t research`)

**Ambient.** The `WaxSeal`'s gilt rim cycles opacity 0.85 ↔ 1.0 over 5s.
The wax body stays at full opacity — rim-only breathing reads as
candle-lit, not as notification pulsing.

### 5.3 Journal Tasks — `com.utku.journaltasks`

**File.** `filePath` configurable, default `~/notes/tasks.md`. Polled via
executable engine on `stat -c %Y` change detection at 2s intervals.

**Parser.** One-pass line parser recognizing:

- `^(#{1,3})\s+(.+)$` → section header (rendered in Cormorant SC Medium
  13px, `burgundy`, letter-spacing +80).
- `^\s*- \[( |x|X)\]\s+(.+)$` → task item. Checkbox state + indent depth +
  body preserved.
- Other lines → muted body text in `inkMedium`.

**Rendering.** Vertical list. Section headers render above their items.
Tasks render as a horizontal row: a 14px checkbox glyph (both states use
the same gilt-ring outline; checked adds a centered IM FELL `✓` glyph in
`wax` inside the ring) + task body in Cormorant Garamond Regular 14px.
Completed items strike through via `font.strikeout` with a 300ms fade-in
when toggled.

**Interactions.**

- Click checkbox → rewrite that single line in the file (toggle
  `[ ]` ↔ `[x]`). Preserves all other content byte-for-byte via
  line-indexed write.
- Inline "add" field at the bottom: Caveat 14px, placeholder
  `"a new entry…"`. Enter appends `- [ ] <text>` under the last section
  header (or to EOF if no sections present).
- Scroll overflow with `ScrollView`.

**Ambient.** 1px gilt margin rule inset 24px from the left edge, 40%
opacity. Static.

**Config.**

- `filePath` (String, default "~/notes/tasks.md")
- `showCompleted` (Bool, default true)
- `sectionFilter` (String, default "", comma-separated; empty = show all)
- `refreshMs` (Int, default 2000)

### 5.4 Journal Clock — `com.utku.journalclock`

**Layout.** One row, three cells:

- Left (28×28): moon-phase SVG glyph from `shared/qml/MoonPhase.qml`,
  inked in `inkDark`.
- Center: time in Cormorant Garamond SemiBold 56px, tabular figures. The
  colon rendered as a centered U+00B7 dot (`·`) at matching weight.
- Right: two stacked lines, Caveat 14px day-of-week and Cormorant Italic
  14px date with ordinal superscript (`23ʳᵈ April`).

**Moon phase.** Computed locally. 8 phases keyed on age-in-days from a
known new-moon epoch:

```
age = ((JD - 2451549.5) % 29.53059) / 29.53059
phase = floor(age * 8) % 8
```

Each phase is a dedicated SVG path in `MoonPhase.qml`; no Unicode moon
glyphs (font variance is too high).

**Timer.** 60s when `showSeconds=false`; 1s when `showSeconds=true`. On
`showSeconds=true`, a hairline `:ss` in `inkMedium` Cormorant 22px appears
after the main numeral.

**Config.**

- `use24h` (Bool, default true)
- `showSeconds` (Bool, default false)
- `locale` (String, default "" meaning system)

**Ambient.** None. Moon glyph swaps at midnight only.

### 5.5 Journal Weather — `com.utku.journalweather`

**Data.** OpenMeteo, no API key.

1. **Geocoding** — `https://geocoding-api.open-meteo.com/v1/search?name=<city>&count=1`
   Cached per `cityName`; re-resolved only on city change.
2. **Forecast** — `https://api.open-meteo.com/v1/forecast` with query
   params `latitude`, `longitude`,
   `current=temperature_2m,weather_code,wind_speed_10m,wind_direction_10m`,
   `daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max`,
   `timezone=auto`, `forecast_days=3`. 30-minute refresh.

Both calls go through the `executable` engine via `curl -s` for
consistency with spec patterns. Response parsed with `JSON.parse` in QML.

**Rendering.** Three lines, all Caveat, sizes 16 / 13 / 13:

1. Current: `"<temp>°C, <condition-prose>, <wind-prose>."`
2. Tomorrow: `"Tomorrow — high <max>°, <precipitation-prose>."`
3. Day-after: `"<DayName> — <condition-prose>, high <max>°, <precip-prose>."`

**Prose tables.** Hand-curated, not auto-translated:

- Wind compass 16-point → English: N="from the north", NE="from the
  northeast", E="from the east", … 16 entries.
- Wind speed bucket → adjective: `<2`="still", `<8`="a gentle wind",
  `<15`="a steady wind", `<25`="a stiff wind", `<40`="a hard wind",
  `≥40`="a gale".
- WMO weather code → phrase: 0="clear", 1="mostly clear", 2="a little
  cloud", 3="overcast", 45/48="foggy", 51/53/55="a drizzle",
  61/63/65="rain", 71/73/75="snow", 80/81/82="showers", 95="a
  thunderstorm", 96/99="a thunderstorm with hail". Unknown codes →
  "weather unclear".
- Precipitation probability → phrase: `<10`="no rain in hand",
  `<30`="a slim chance of rain", `<60`="rain likely", `≥60`="rain in
  earnest".

**Errors.** Any fetch failure → `"— the almanac is silent. —"` in
`inkMedium` Caveat 14px. Logged once with `console.warn`. Next successful
refresh restores normal output.

**Config.**

- `cityName` (String, default "Istanbul")
- `refreshMinutes` (Int, default 30)
- `units` (String, default "metric", enum "metric"/"imperial")

**Ambient.** None.

### 5.6 Journal NowPlaying — `com.utku.journalnowplaying`

**Data.** MPRIS via DBus through the `executable` engine. Query commands:

```
qdbus org.mpris.MediaPlayer2.<player> /org/mpris/MediaPlayer2 \
  org.freedesktop.DBus.Properties.Get \
  org.mpris.MediaPlayer2.Player Metadata
```

Same pattern for `PlaybackStatus` and `Position`. Player discovery: list
`org.mpris.MediaPlayer2.*` services via
`qdbus | grep org.mpris.MediaPlayer2`. If `preferredPlayer` is set, use
it; otherwise pick the first playing service.

Polled at 1s intervals when playing, 5s intervals when paused/stopped,
backs off to 30s after 60s of inactivity.

**Rendering (at rest).**

- Track title in Parisienne 22px, `wax` color.
- Artist in Caveat 14px, `inkMedium`.
- Album in Caveat Italic 12px, `inkMedium`.
- Bottom edge: 2px gilt progress rule, filled from left to current
  position. Leading edge 1px `inkWet` glow (see ambient).

**Rendering (on hover).** Three SVG-path glyph controls fade in along
the bottom-right over 150ms: prev (`◁◁`), play/pause (`❙❙` or `▷`),
next (`▷▷`). Controls in `wax`, hover-tint to `burgundy`. Fade out on
mouse-leave with 200ms delay.

**Empty state.** `"— no song in the air —"` Caveat 14px `inkMedium`.
Widget opacity drops to 0.7.

**Controls.** Each control button emits a
`qdbus … org.mpris.MediaPlayer2.Player.<Method>` (Previous / PlayPause /
Next). No seek, no volume, no shuffle — the widget is a diary entry, not
a remote.

**Config.**

- `preferredPlayer` (String, default "", empty = auto)
- `showAlbumArt` (Bool, default false; retained for future toggle)

**Ambient.** When playing, `inkWet` leading edge glow cycles width 0 ↔ 1px
over 3s. Paused/stopped: static at 0.

## 6. Scripts

### 6.1 `install.sh`

`set -euo pipefail`. Stages:

1. **Preflight.** Exits with human-readable error if any check fails:
   - Plasma 6 (`plasmashell --version` matches `^plasmashell 6\.`).
   - Binaries present: `kpackagetool6`, `fc-cache`, `curl`, `awk`,
     `stat`, `rsync`.
   - Target dirs writable.
   - Network (3-second `curl` to `fonts.google.com/robots.txt`). Skipped
     if fonts already present.
2. **Fonts.** Nine URLs, each downloaded only if the target file is
   missing. An associative array at the top of the script records the
   SHA-256 of each expected file; after download, the script re-verifies
   with `sha256sum -c`. Mismatched files fail the install with a
   diagnostic. `fc-cache -f <font-dir>` at end.
3. **Color scheme.** Compare repo file and installed file via SHA-256;
   copy only if they differ.
4. **Shared QML.** `rsync shared/qml/ plasmoids/<id>/contents/ui/shared/`
   for each plasmoid.
5. **Plasmoids.** `kpackagetool6 --upgrade <dir>` if installed, else
   `--install <dir>`. Six plasmoids.
6. **Summary.** Prints next steps (identical to `inst.md`).

**Flags.**

- `--dry-run` — every action prints `would: <cmd>`, nothing executes.
- `--no-fonts` — skip font fetch.
- `--force` — overwrite color scheme even if checksum drifted.
- `--help` — usage.

### 6.2 `uninstall.sh`

- `kpackagetool6 --remove com.utku.<id>` for each of six plasmoids
  (ignores not-installed errors).
- Deletes `~/.local/share/color-schemes/luxury-journal.colors`.
- Does NOT touch the user's color-scheme selection in `kdeglobals`.
- `--purge` — also deletes `~/.local/share/fonts/luxury-journal/` and
  runs `fc-cache -f`.
- `--help` — usage.

### 6.3 `dev.sh`

- `dev.sh preview <id>` — resolves short names (`tmuxtail` →
  `com.utku.tmuxtail`), rsyncs shared QML into the plasmoid, runs
  `plasmoidviewer -a plasmoids/<id>`.
- `dev.sh reload <id>` — rsyncs shared QML, runs
  `kpackagetool6 --upgrade plasmoids/<id>`, prints refresh hint.
- `dev.sh --help` — usage.

## 7. GitHub Repo Chrome

### 7.1 `.github/workflows/lint.yml`

Single job on push + pull_request:

```yaml
- shellcheck install.sh uninstall.sh dev.sh
- jq -e . plasmoids/*/metadata.json
- xmllint --noout plasmoids/*/contents/config/main.xml
- python tools/validate_colors.py luxury-journal.colors
- qmllint-qt6 plasmoids/*/contents/ui/*.qml shared/qml/*.qml  # if available
```

### 7.2 `tools/validate_colors.py`

~30 lines: parses `.colors` as INI, verifies every `[Colors:*]` section
has the mandatory keys Plasma 6 expects (BackgroundNormal,
BackgroundAlternate, ForegroundNormal, ForegroundInactive,
ForegroundActive, ForegroundLink, ForegroundVisited, ForegroundNegative,
ForegroundNeutral, ForegroundPositive, DecorationFocus, DecorationHover).
Exits non-zero on missing keys.

### 7.3 Issue / PR templates

- `bug.md` — fields: reproduction, Plasma version, journalctl output,
  screenshot.
- `feature.md` — fields: user story, aesthetic fit, data sources.
- `PULL_REQUEST_TEMPLATE.md` — summary, screenshots, plasmoidviewer
  tested, journalctl clean.

### 7.4 `.gitignore`

```
*.swp
*~
.DS_Store
__pycache__/
*.pyc
plasmoids/*/contents/ui/shared/
```

### 7.5 `README.md`

Sections: pitch (one paragraph), quick install, uninstall, screenshots
(gallery of placeholders initially), design notes (3 paragraphs: fonts,
palette, three-piece architecture), KDE Store sibling widget list,
development loop, troubleshooting, license.

### 7.6 `CHANGELOG.md`

Starts at `0.1.0 — 2026-04-24` listing all six plasmoids, the color
scheme, the font roster, install/uninstall/dev scripts, lint CI.

### 7.7 `docs/ARCHITECTURE.md`

Short explainer of the three-piece design (colors → fonts → plasmoids)
and why each piece is where it is.

## 8. Build Order

Each step ends with a conventional-commits-prefixed git commit.

1. Repo skeleton (`.gitignore`, `LICENSE`, `CHANGELOG.md` stub, dir
   skeleton via `.gitkeep`).
2. Color scheme file.
3. `install.sh` v0 (colors + fonts only).
4. Shared QML (`Palette`, `Ornaments`, `ParchmentBackground`,
   `MoonPhase`).
5. Greeting plasmoid.
6. Tmux Tail plasmoid.
7. Journal Tasks plasmoid.
8. Journal Clock plasmoid.
9. Journal Weather plasmoid.
10. Journal NowPlaying plasmoid.
11. `install.sh` v1 (add plasmoid install + shared-QML copy).
12. `uninstall.sh`, `dev.sh`.
13. `tools/validate_colors.py` + lint workflow.
14. Issue / PR templates.
15. README, ARCHITECTURE, screenshot placeholders.
16. Tag `v0.1.0`.

## 9. Verification Approach

Because this environment cannot run Plasma itself, acceptance is split:

**Verifiable in-sandbox:**

- `shellcheck install.sh uninstall.sh dev.sh` clean.
- `qmllint-qt6 …` clean (best-effort; falls back to manual review if
  unavailable).
- `jq` parses every `metadata.json`.
- `xmllint --noout` on every `main.xml`.
- `python tools/validate_colors.py luxury-journal.colors` clean.
- Git history is linear and each commit builds.

**Deferred to user's machine:**

- All plasmoids install cleanly via `./install.sh`.
- Luxury Journal color scheme applies.
- Each plasmoid renders without errors in
  `journalctl --user -t plasmashell`.
- Each plasmoid's configured behavior (greeting rotation, tmux capture,
  tasks toggle, clock moon phase, weather prose, nowplaying hover
  controls) works end-to-end.

The README includes a verification checklist the user runs after install.

## 10. Acceptance Criteria

- [ ] `./install.sh --dry-run` succeeds and prints all actions.
- [ ] `./install.sh` on a clean system installs 9 fonts, 1 color scheme,
      6 plasmoids.
- [ ] `./install.sh` is idempotent on re-run.
- [ ] `./uninstall.sh` reverses everything except fonts; `--purge`
      reverses fonts too.
- [ ] Luxury Journal appears in System Settings → Colors.
- [ ] All 6 custom plasmoids install without QML errors.
- [ ] Greeting: cursive renders; five phrases per period rotate daily;
      Monday / Friday / 1st-of-month / birthday context phrases fire.
- [ ] Tmux Tail: lines capture; refresh works; "session not found" sad
      path; double-click attaches.
- [ ] Tasks: file reads; checkbox click toggles file; add-input appends;
      section headers render small-caps.
- [ ] Clock: correct time; moon glyph correct for today; seconds toggle
      works.
- [ ] Weather: city geocoding works; three lines render with journal
      prose; 30-minute refresh; silent-almanac sad path.
- [ ] NowPlaying: any MPRIS player feeds it; hover reveals controls;
      empty state when silent.
- [ ] `Kirigami.Theme.*` used for all semantic color lookups; custom
      tokens only via `Palette.qml`.
- [ ] `shellcheck` clean.
- [ ] `qmllint-qt6` clean (where available).
- [ ] Lint CI workflow green.

## 11. Risks & Fallbacks

- **`qmllint-qt6` availability in-sandbox.** If the tool can't be
  installed on this environment (Fedora's `qt6-qtdeclarative-devel` is
  ~120 MB and may fail to install), QML review falls back to manual
  inspection plus a syntactic sanity pass written as a small Python
  helper. Not a blocker for implementation — the CI workflow still runs
  qmllint on the GitHub runner where it's available.
- **Font URL drift.** The install script pins SHA-256 of each font file;
  if Google Fonts reorganizes the `main` branch again (it has before),
  SHA mismatch flags the change loudly instead of silently shipping the
  wrong file. The URLs and hashes are centralized at the top of
  `install.sh` for easy update.
- **MPRIS player quirks.** Some players report `Metadata` as
  `dict { string "mpris:length" : int64 …}` (Firefox), others with
  different key casing (older mpv). The parser in the NowPlaying
  plasmoid must be lenient: treat missing fields as empty strings rather
  than throwing.
- **OpenMeteo outage.** Silent-almanac sad path covers it; the widget
  doesn't crash or spam retries.

## 12. Open Questions

None remaining at approval time. Any that surface during implementation
will be recorded in the plan and resolved before code is committed.
