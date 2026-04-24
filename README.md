# Luxury Journal

A KDE Plasma 6 dashboard theme — leather-bound journal aesthetic, applied
system-wide through one color scheme, nine fonts, and six custom plasmoids.

![placeholder hero screenshot](docs/screenshots/hero.png)

## What's inside

Three moving pieces — all the rest is Plasma itself:

1. **`luxury-journal.colors`** — a Plasma 6 color scheme (parchment, ink,
   burgundy). Applies system-wide; built-in and third-party widgets
   inherit the palette automatically.
2. **Nine fonts** installed user-local: Parisienne, Caveat, Cormorant
   Garamond (Light / Regular / Medium / SemiBold), Cormorant SC, IM FELL
   DW Pica, JetBrains Mono.
3. **Six custom plasmoids**, all self-contained after install:
   - **Luxury Greeting** — cursive greeting that rotates with the day and
     the week. Drop-cap in IM FELL DW Pica with a faint breathing opacity.
   - **Tmux Tail** — the last N lines of a tmux pane, refreshed on a
     timer. Double-click to attach.
   - **Journal Tasks** — reads `~/notes/tasks.md`, parses `## headers`
     and `- [ ]` checkboxes, click to toggle, inline add-entry field.
   - **Journal Clock** — serif time with a moon-phase glyph.
   - **Journal Weather** — OpenMeteo (no API key), three lines of journal
     prose.
   - **Journal NowPlaying** — MPRIS via qdbus, hover for ◁◁ ❙❙ ▷▷ controls.

## Install

```bash
git clone <this-repo> luxury-journal
cd luxury-journal
./install.sh
```

Then: System Settings → Colors & Themes → pick "Luxury Journal"; right-click
desktop → Add or Manage Widgets → add whichever of the six you want.

Flags:
- `./install.sh --dry-run` — preview actions, no writes
- `./install.sh --no-fonts` — skip font downloads
- `./install.sh --force` — overwrite the color scheme even if modified

## Uninstall

```bash
./uninstall.sh           # removes plasmoids + color scheme; keeps fonts
./uninstall.sh --purge   # also removes fonts
```

## Develop

```bash
./dev.sh preview tmuxtail     # live preview a plasmoid
./dev.sh reload  tmuxtail     # copy shared QML + kpackagetool6 --upgrade
```

Short names (`tmuxtail`, `journaltasks`, `journalclock`, …) and full names
(`com.utku.tmuxtail`, …) both work.

## Companion widgets from the KDE Store

The project pairs well with these built-ins, which inherit the color scheme
automatically:

- **System Monitor** — pages for machine (CPU/RAM/GPU/disk/battery) and
  network (wi-fi SSID, bandwidth, ping).
- **Weather Report** (if you want more than the journal-prose version).
- **Notes** — the sticky-note for a scratchpad.
- **Folder View** or **Quicklaunch** — the "at hand" icon grid.

## Screenshots

_Placeholders — populate `docs/screenshots/` and reference them here._

## Troubleshooting

**Fonts don't render.** Check `fc-list | grep -i parisienne`. If empty,
re-run `./install.sh` (or `fc-cache -f ~/.local/share/fonts/luxury-journal`).

**Plasmoid shows QML errors.** Tail `journalctl --user -f -t plasmashell`
while the widget is being reloaded. Most errors at install time are
missing-import errors; confirm `install.sh` copied `shared/qml/*` into the
plasmoid's `contents/ui/shared/`.

**Tmux Tail says "session not found".** Verify
`tmux list-sessions` shows the configured target. The value is
`session[:window[.pane]]`, default `research:0`.

**Weather widget silent.** Check that `curl` can reach
`https://api.open-meteo.com`. Verify the configured city name resolves
via `curl -sS 'https://geocoding-api.open-meteo.com/v1/search?name=<city>&count=1'`.

**NowPlaying widget empty.** Run `qdbus | grep MediaPlayer2` — if nothing
listed, no player is exposing MPRIS. Spotify (native), mpv with the
`mpv-mpris` script, Firefox, and Chromium all work out of the box.

## License

MIT — see [LICENSE](LICENSE).
