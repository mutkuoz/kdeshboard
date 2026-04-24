# Architecture

The project is deliberately three-piece. Each piece stands alone, the seams
between them are narrow, and the whole is no more complicated than the sum.

## 1. Color scheme

`luxury-journal.colors` is a Plasma 6 color scheme — the same format any
other KDE theme uses. Plasma looks at this file and themes everything: its
own widgets, third-party plasmoids, KDE apps, Qt apps on the desktop. The
file is flat INI. Once the user picks "Luxury Journal" in System Settings →
Colors, the palette is applied across every widget that uses
`Kirigami.Theme.*` lookups (which is all of them, by policy).

No code owns this step. The file is installed by `install.sh` and picked up
by Plasma at login or after a `plasma-apply-colorscheme` invocation.

## 2. Fonts

Nine `.ttf` files live under `~/.local/share/fonts/luxury-journal/`. Fonts
are user-local, not system-wide: they don't require root, don't pollute
other users' font lists, and can be removed by
`./uninstall.sh --purge` without leaving system config drift.

After font install, `install.sh` runs `fc-cache -f` so Qt sees them
immediately.

## 3. Plasmoids

Each plasmoid is a self-contained KPackage bundle: `metadata.json` at the
root plus `contents/ui/*.qml` and `contents/config/*`. Six of them in this
repo; each follows the same skeleton.

**Shared QML.** All six import from a small library — a `Palette`
singleton with color and font-family constants, an `Ornaments` component
collection, a `ParchmentBackground`, a `MoonPhase`. Source of truth is
`shared/qml/`. Plasma has no sanctioned way to share QML across plasmoids
in a single repo, so at install time `install.sh` copies
`shared/qml/*` into each plasmoid's `contents/ui/shared/`. The copy is in
`.gitignore`.

**Data sources.** Plasmoids that need external data (shell commands, HTTP,
DBus) use `Plasma5Support.DataSource` with the `executable` engine — the
same pattern the built-in widgets use. Each widget disconnects its sources
after each read to avoid leaks, per the spec's "Style notes" guidance.

**Config.** Every plasmoid defines a `config/main.xml` schema and a
`ui/configGeneral.qml` form. Plasma handles the rest: schema drives per-
instance config, form drives the wrench-icon dialog, values persist to
`~/.config/<pluginRc>`.

## Boundaries

- The color scheme knows nothing about the plasmoids.
- The plasmoids share only the QML kit and read palette semantics through
  `Kirigami.Theme.*` + `Palette.qml`.
- No plasmoid depends on another plasmoid.
- The install script is the only thing that touches all three pieces; it
  delegates the actual work (font cache, package registration, file copy)
  to upstream tools.
