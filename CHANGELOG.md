# Changelog

All notable changes to this project will be documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
