# Changelog

All notable changes to this project will be documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Five new plasmoids:
  - `com.utku.systeminfo` — 3×3 gauge grid for CPU/GPU/mem/disk/net/ping/battery.
  - `com.utku.analogclock` — analog clock in a wax-seal or postage-stamp housing.
  - `com.utku.almanac` — ordinal date, season, moon, day count, event countdown.
  - `com.utku.commonplacebook` — rotating quote, built-in pool + optional file.
  - `com.utku.hourglass` — Pomodoro timer drawn as a draining hourglass.
- `backgroundOpacity` (10–100%) and `edgeStyle` (rounded/ripped/deckle/
  stamped/embossed) config for every plasmoid, wired to
  `ParchmentBackground`.

### Changed
- `ParchmentBackground` now honors `alpha` on its base fill while keeping
  noise and foxing at their natural opacity, scaled by the factor.
- Luxury Greeting drop-cap now uses Parisienne (display font) so the
  first letter visually matches the rest of the phrase.

### Fixed
- Weather and NowPlaying DataSource queries: `LABEL: cmd` prefix routing
  broke under `/bin/sh -c` which tried to execute `LABEL:` as a command.
  Moved the routing tag to a trailing `#MARKER` shell comment.
- NowPlaying now prefers `qdbus6` over `qdbus`, matching Plasma 6 hosts.

## [0.1.0] — 2026-04-24

### Added
- Plasma 6 color scheme `luxury-journal.colors` (10 sections).
- Nine-font user-local roster: Parisienne, Caveat (variable), Cormorant
  Garamond (Light / Regular / Medium / SemiBold), Cormorant SC (Medium),
  IM FELL DW Pica (Regular), JetBrains Mono (Regular).
- Six custom plasmoids:
  - `com.utku.luxurygreeting`
  - `com.utku.tmuxtail`
  - `com.utku.journaltasks`
  - `com.utku.journalclock`
  - `com.utku.journalweather`
  - `com.utku.journalnowplaying`
- Shared QML kit: `Palette`, `Ornaments`, `ParchmentBackground`,
  `MoonPhase`.
- `install.sh` (idempotent, `--dry-run` / `--no-fonts` / `--force`).
- `uninstall.sh` (`--purge` also removes fonts).
- `dev.sh preview <id>` / `dev.sh reload <id>` helpers.
- `.github/workflows/lint.yml` — shellcheck / jq / xmllint / color
  validator / qmllint.
- `tools/validate_colors.py`.
- Issue + PR templates.
- README, ARCHITECTURE, LICENSE (MIT).
