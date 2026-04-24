# Luxury Journal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a KDE Plasma 6 dashboard "theme" (a color scheme, a font roster, and six custom QML plasmoids) styled as a leather-bound journal, with install / uninstall / dev scripts and a linting CI workflow.

**Architecture:** Three-piece design. (1) A `.colors` file defines the system-wide palette. (2) `install.sh` installs nine Google Fonts to `~/.local/share/fonts/luxury-journal/`. (3) Six QML plasmoids import from a shared kit (`Palette` singleton, `Ornaments` library, `ParchmentBackground`, `MoonPhase`) and call out to shell/HTTP via `Plasma5Support.DataSource`. Each plasmoid is self-contained after install: `install.sh` copies `shared/qml/*` into every plasmoid's `contents/ui/shared/` so each package ships with its dependencies.

**Tech Stack:** QML (Qt 6.x) · Plasma 6 Applet API (`PlasmoidItem`, `Kirigami.Theme`, `Plasma5Support.DataSource` with the `executable` engine) · Bash 5 · Python 3 (for the color-scheme validator) · GitHub Actions (lint CI).

**Spec:** `docs/superpowers/specs/2026-04-24-luxury-journal-design.md`.

**Verification strategy:** QML lacks a standard unit-test framework for plasmoids. Each code task is followed by a static-analysis step — `qmllint-qt6` for QML, `shellcheck` for shell, `xmllint`/`jq`/`python` for config files. End-to-end verification (running in Plasma) happens on the user's machine and is captured as a post-install checklist in the README.

---

## Task 0: Install verification toolchain

**Files:** none — this task only installs tools into the sandbox.

- [ ] **Step 1: Install shellcheck, xmllint, jq, python3, qt6-qtdeclarative-devel**

Run:
```bash
sudo dnf install -y ShellCheck libxml2 jq python3 qt6-qtdeclarative-devel
which shellcheck xmllint jq python3 qmllint-qt6 || which qmllint6 || which qmllint
```
Expected: all six paths print. If `qmllint-qt6` is missing but `qmllint6` or `qmllint` is present, note which binary is the Qt 6 lint tool (Fedora 43 ships it as `qmllint-qt6`). If no qmllint variant installs, proceed — later QML steps fall back to manual inspection and the lint CI step is marked `continue-on-error: true`.

- [ ] **Step 2: Record the qmllint binary name**

Create a throwaway note to yourself of the exact binary:
```bash
QMLLINT=$(command -v qmllint-qt6 || command -v qmllint6 || command -v qmllint || echo "")
echo "QMLLINT=$QMLLINT"
```
Use this binary name consistently for the rest of the plan when a step says "run qmllint". If empty, skip the qmllint steps (still run all other validators).

---

## Task 1: Repo skeleton

**Files:**
- Create: `.gitignore`
- Create: `LICENSE`
- Create: `CHANGELOG.md`
- Create: `README.md` (stub)
- Create: empty `.gitkeep` markers inside every directory that will be populated later

- [ ] **Step 1: Write `.gitignore`**

Create `/mnt/hangar/projects/kdeshboard/.gitignore`:
```gitignore
# OS & editor cruft
*.swp
*~
.DS_Store

# Python
__pycache__/
*.pyc

# Shared QML is the single source of truth in shared/qml/.
# install.sh and dev.sh copy it into each plasmoid at install time;
# the copy must never be committed.
plasmoids/*/contents/ui/shared/
```

- [ ] **Step 2: Write `LICENSE` (MIT)**

Create `/mnt/hangar/projects/kdeshboard/LICENSE`:
```
MIT License

Copyright (c) 2026 Utku

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: Write `CHANGELOG.md` stub**

Create `/mnt/hangar/projects/kdeshboard/CHANGELOG.md`:
```markdown
# Changelog

All notable changes to this project will be documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Repository skeleton (LICENSE, .gitignore, CHANGELOG, README stub).
```

- [ ] **Step 4: Write `README.md` stub**

Create `/mnt/hangar/projects/kdeshboard/README.md`:
```markdown
# Luxury Journal

A KDE Plasma 6 dashboard theme — leather-bound journal aesthetic applied
through one color scheme, nine fonts, and six custom plasmoids.

Under construction. See `docs/superpowers/specs/2026-04-24-luxury-journal-design.md`
for the design, `docs/superpowers/plans/2026-04-24-luxury-journal.md` for the
implementation plan.
```

- [ ] **Step 5: Create directory markers**

Run:
```bash
cd /mnt/hangar/projects/kdeshboard
mkdir -p plasmoids/com.utku.luxurygreeting/contents/{ui,config} \
         plasmoids/com.utku.tmuxtail/contents/{ui,config} \
         plasmoids/com.utku.journaltasks/contents/{ui,config} \
         plasmoids/com.utku.journalclock/contents/{ui,config} \
         plasmoids/com.utku.journalweather/contents/{ui,config} \
         plasmoids/com.utku.journalnowplaying/contents/{ui,config} \
         shared/qml tools docs/screenshots \
         .github/ISSUE_TEMPLATE .github/workflows
# .gitkeep markers so empty dirs make it into the initial commit
for d in docs/screenshots shared/qml tools .github/ISSUE_TEMPLATE .github/workflows \
         plasmoids/com.utku.luxurygreeting/contents/ui \
         plasmoids/com.utku.luxurygreeting/contents/config \
         plasmoids/com.utku.tmuxtail/contents/ui \
         plasmoids/com.utku.tmuxtail/contents/config \
         plasmoids/com.utku.journaltasks/contents/ui \
         plasmoids/com.utku.journaltasks/contents/config \
         plasmoids/com.utku.journalclock/contents/ui \
         plasmoids/com.utku.journalclock/contents/config \
         plasmoids/com.utku.journalweather/contents/ui \
         plasmoids/com.utku.journalweather/contents/config \
         plasmoids/com.utku.journalnowplaying/contents/ui \
         plasmoids/com.utku.journalnowplaying/contents/config; do
  touch "$d/.gitkeep"
done
```

- [ ] **Step 6: Commit**

```bash
cd /mnt/hangar/projects/kdeshboard
git add .gitignore LICENSE CHANGELOG.md README.md plasmoids shared tools docs/screenshots .github
git commit -m "chore: scaffold repo skeleton

Directories, LICENSE, README stub, CHANGELOG, .gitignore."
```

---

## Task 2: Color scheme file

**Files:** Create `luxury-journal.colors`.

- [ ] **Step 1: Write the color scheme**

Create `/mnt/hangar/projects/kdeshboard/luxury-journal.colors` with the content from `inst.md` section "luxury-journal.colors" (verbatim):

```ini
[General]
ColorScheme=LuxuryJournal
Name=Luxury Journal
shadeSortColumn=true

[KDE]
contrast=4

[Colors:Window]
BackgroundNormal=236,224,200
BackgroundAlternate=242,232,211
ForegroundNormal=45,24,16
ForegroundInactive=107,78,54
ForegroundActive=114,37,41
ForegroundLink=114,37,41
ForegroundVisited=114,37,41
ForegroundNegative=158,53,64
ForegroundNeutral=158,123,58
ForegroundPositive=74,107,58
DecorationFocus=114,37,41
DecorationHover=114,37,41

[Colors:View]
BackgroundNormal=242,232,211
BackgroundAlternate=236,224,200
ForegroundNormal=45,24,16
ForegroundInactive=107,78,54
ForegroundActive=114,37,41
ForegroundLink=114,37,41
ForegroundVisited=114,37,41
ForegroundNegative=158,53,64
ForegroundNeutral=158,123,58
ForegroundPositive=74,107,58
DecorationFocus=114,37,41
DecorationHover=114,37,41

[Colors:Button]
BackgroundNormal=242,232,211
BackgroundAlternate=236,224,200
ForegroundNormal=45,24,16
ForegroundInactive=107,78,54
ForegroundActive=114,37,41
ForegroundLink=114,37,41
ForegroundVisited=114,37,41
ForegroundNegative=158,53,64
ForegroundNeutral=158,123,58
ForegroundPositive=74,107,58
DecorationFocus=114,37,41
DecorationHover=114,37,41

[Colors:Selection]
BackgroundNormal=114,37,41
BackgroundAlternate=114,37,41
ForegroundNormal=242,232,211
ForegroundInactive=240,230,210
ForegroundActive=255,255,255
ForegroundLink=255,255,255
ForegroundVisited=240,230,210
ForegroundNegative=255,200,200
ForegroundNeutral=255,230,180
ForegroundPositive=200,230,200
DecorationFocus=114,37,41
DecorationHover=114,37,41

[Colors:Tooltip]
BackgroundNormal=236,224,200
BackgroundAlternate=242,232,211
ForegroundNormal=45,24,16
ForegroundInactive=107,78,54
ForegroundActive=114,37,41
ForegroundLink=114,37,41
ForegroundVisited=114,37,41
ForegroundNegative=158,53,64
ForegroundNeutral=158,123,58
ForegroundPositive=74,107,58
DecorationFocus=114,37,41
DecorationHover=114,37,41

[Colors:Complementary]
BackgroundNormal=236,224,200
BackgroundAlternate=242,232,211
ForegroundNormal=45,24,16
ForegroundInactive=107,78,54
ForegroundActive=114,37,41
ForegroundLink=114,37,41
ForegroundVisited=114,37,41
ForegroundNegative=158,53,64
ForegroundNeutral=158,123,58
ForegroundPositive=74,107,58
DecorationFocus=114,37,41
DecorationHover=114,37,41

[Colors:Header]
BackgroundNormal=114,37,41
BackgroundAlternate=158,53,64
ForegroundNormal=242,232,211
ForegroundInactive=240,230,210
ForegroundActive=255,255,255
ForegroundLink=255,255,255
ForegroundVisited=240,230,210
ForegroundNegative=255,200,200
ForegroundNeutral=255,230,180
ForegroundPositive=200,230,200
DecorationFocus=242,232,211
DecorationHover=242,232,211

[WM]
activeBackground=114,37,41
activeBlend=114,37,41
activeForeground=242,232,211
inactiveBackground=236,224,200
inactiveBlend=236,224,200
inactiveForeground=107,78,54
```

- [ ] **Step 2: Sanity-check it parses as INI**

Run:
```bash
cd /mnt/hangar/projects/kdeshboard
python3 -c "import configparser; c = configparser.ConfigParser(); c.read('luxury-journal.colors'); print('sections:', c.sections())"
```
Expected: `sections: ['General', 'KDE', 'Colors:Window', 'Colors:View', 'Colors:Button', 'Colors:Selection', 'Colors:Tooltip', 'Colors:Complementary', 'Colors:Header', 'WM']`.

- [ ] **Step 3: Commit**

```bash
git add luxury-journal.colors
git commit -m "feat: add Luxury Journal color scheme

Ten-section Plasma 6 palette: parchment backgrounds, burgundy
selection/decoration, ink-brown foreground. Matches inst.md spec."
```

---

## Task 3: Color scheme validator

**Files:** Create `tools/validate_colors.py`.

- [ ] **Step 1: Write the validator**

Create `/mnt/hangar/projects/kdeshboard/tools/validate_colors.py`:
```python
#!/usr/bin/env python3
"""Validate a Plasma 6 .colors file has all mandatory keys.

Usage: validate_colors.py <path-to-.colors>
Exit code 0 on success, 1 on missing keys, 2 on parse error.
"""
from __future__ import annotations

import configparser
import re
import sys
from pathlib import Path

REQUIRED_COLOR_KEYS = {
    "BackgroundNormal",
    "BackgroundAlternate",
    "ForegroundNormal",
    "ForegroundInactive",
    "ForegroundActive",
    "ForegroundLink",
    "ForegroundVisited",
    "ForegroundNegative",
    "ForegroundNeutral",
    "ForegroundPositive",
    "DecorationFocus",
    "DecorationHover",
}
REQUIRED_SECTIONS = {"General", "Colors:Window", "Colors:View", "Colors:Button"}
RGB_PATTERN = re.compile(r"^\d{1,3},\d{1,3},\d{1,3}$")


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(f"usage: {argv[0]} <path-to-.colors>", file=sys.stderr)
        return 2
    path = Path(argv[1])
    if not path.is_file():
        print(f"not a file: {path}", file=sys.stderr)
        return 2

    parser = configparser.ConfigParser()
    try:
        parser.read(path)
    except configparser.Error as exc:
        print(f"parse error: {exc}", file=sys.stderr)
        return 2

    errors: list[str] = []
    for section in REQUIRED_SECTIONS:
        if section not in parser:
            errors.append(f"missing section: [{section}]")

    for section in parser.sections():
        if not section.startswith("Colors:"):
            continue
        missing = REQUIRED_COLOR_KEYS - set(parser[section].keys())
        for key in sorted(missing):
            errors.append(f"[{section}] missing key: {key}")
        for key, value in parser[section].items():
            if key in REQUIRED_COLOR_KEYS and not RGB_PATTERN.match(value.strip()):
                errors.append(f"[{section}] {key}: not R,G,B: {value!r}")

    if errors:
        for line in errors:
            print(line, file=sys.stderr)
        return 1
    print(f"ok: {path} — {len(parser.sections())} sections")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
```

- [ ] **Step 2: Run validator against the real color file**

Run:
```bash
cd /mnt/hangar/projects/kdeshboard
python3 tools/validate_colors.py luxury-journal.colors
```
Expected: `ok: luxury-journal.colors — 10 sections` and exit code 0.

- [ ] **Step 3: Run validator against a broken file (negative test)**

Run:
```bash
cd /mnt/hangar/projects/kdeshboard
python3 -c "print('[Colors:Window]\nBackgroundNormal=1,2,3\n')" > /tmp/bad.colors
python3 tools/validate_colors.py /tmp/bad.colors; echo "exit=$?"
rm /tmp/bad.colors
```
Expected: multiple `missing key:` lines for the 11 keys not supplied, plus `missing section: [General]` and others, and `exit=1`.

- [ ] **Step 4: Commit**

```bash
git add tools/validate_colors.py
git commit -m "feat(tools): add color-scheme validator

Checks every [Colors:*] section has the 12 mandatory keys and each is a
valid R,G,B triplet. Ensures the required top-level sections exist.
Exits 1 on missing keys so CI can gate on it."
```

---

## Task 4: Shared QML — `Palette.qml` singleton

**Files:**
- Create: `shared/qml/Palette.qml`
- Create: `shared/qml/qmldir`

- [ ] **Step 1: Write the singleton**

Create `/mnt/hangar/projects/kdeshboard/shared/qml/Palette.qml`:
```qml
pragma Singleton
import QtQuick
import org.kde.kirigami as Kirigami

QtObject {
    // Ornament-only tokens not representable in Plasma's .colors.
    readonly property color gilt:        "#9a7f3a"
    readonly property color wax:         "#6e1e23"
    readonly property color paperShadow: "#c4b498"
    readonly property color inkWet:      "#8a2a2e"
    readonly property color foxing:      "#b39a72"

    // Aliases so QML files never mix literal strings with semantic lookups.
    // These are evaluated lazily so re-theming works.
    readonly property color parchment:   Kirigami.Theme.backgroundColor
    readonly property color inkDark:     Kirigami.Theme.textColor
    readonly property color inkMedium:   Kirigami.Theme.disabledTextColor
    readonly property color burgundy:    Kirigami.Theme.highlightColor

    // Font family constants. The fonts themselves are installed by install.sh
    // under ~/.local/share/fonts/luxury-journal/; here we only name them.
    readonly property string fontDisplay: "Parisienne"
    readonly property string fontAccent:  "Caveat"
    readonly property string fontSerif:   "Cormorant Garamond"
    readonly property string fontInitial: "IM FELL DW Pica"
    readonly property string fontSmallCaps: "Cormorant SC"
    readonly property string fontMono:    "JetBrains Mono"
}
```

- [ ] **Step 2: Write the qmldir so the singleton is importable**

Create `/mnt/hangar/projects/kdeshboard/shared/qml/qmldir`:
```
module shared
singleton Palette 1.0 Palette.qml
Ornaments 1.0 Ornaments.qml
ParchmentBackground 1.0 ParchmentBackground.qml
MoonPhase 1.0 MoonPhase.qml
```

- [ ] **Step 3: qmllint**

Run (substitute `$QMLLINT` with the binary recorded in Task 0):
```bash
cd /mnt/hangar/projects/kdeshboard
$QMLLINT shared/qml/Palette.qml
```
Expected: no output, exit 0. If qmllint reports `Kirigami is not a known type`, that's an import-resolution warning expected in-sandbox — not a QML syntax error. Proceed.

- [ ] **Step 4: Commit**

```bash
git add shared/qml/Palette.qml shared/qml/qmldir
git commit -m "feat(shared): add Palette singleton and qmldir

Gilt/wax/paperShadow/inkWet/foxing ornament colors + Kirigami aliases
+ typography constants. Lazy Kirigami lookups so re-theming works."
```

---

## Task 5: Shared QML — `Ornaments.qml`

**Files:** Create `shared/qml/Ornaments.qml`.

- [ ] **Step 1: Write the Ornaments library as a QtObject wrapper exposing Components**

Create `/mnt/hangar/projects/kdeshboard/shared/qml/Ornaments.qml`:
```qml
// Ornament primitives — use as inline Components:
//   import "../shared" as Shared
//   Shared.Ornaments.DoubleRule { width: parent.width }
//
// This file exposes each primitive as a Component property so callers
// instantiate them via `Shared.Ornaments.DoubleRule { ... }`.
// Palette is accessible unprefixed because it's a singleton in the same
// QML module as this file (see qmldir).
import QtQuick
import QtQuick.Shapes

QtObject {
    // ---- DoubleRule: two thin horizontal gilt lines ---------------------
    property Component DoubleRule: Component {
        Item {
            id: ruleRoot
            property color color: Palette.gilt
            property real inset: 0
            implicitHeight: 5

            Rectangle {
                x: ruleRoot.inset
                width: ruleRoot.width - ruleRoot.inset * 2
                height: 1
                color: ruleRoot.color
                antialiasing: true
                y: 0
            }
            Rectangle {
                x: ruleRoot.inset
                width: ruleRoot.width - ruleRoot.inset * 2
                height: 1
                color: ruleRoot.color
                antialiasing: true
                y: 3
            }
        }
    }

    // ---- Fleuron: centered ornament character ---------------------------
    property Component Fleuron: Component {
        Item {
            id: flRoot
            property string glyph: "❦"
            property real glyphSize: 14
            property color color: Palette.gilt
            implicitHeight: Math.ceil(glyphSize * 1.3)
            implicitWidth: Math.ceil(glyphSize * 1.6)

            Text {
                anchors.centerIn: parent
                text: flRoot.glyph
                color: flRoot.color
                font.family: Palette.fontSerif
                font.pixelSize: flRoot.glyphSize
            }
        }
    }

    // ---- WaxSeal: wax circle with gilt rim and centered initial --------
    property Component WaxSeal: Component {
        Item {
            id: sealRoot
            property real diameter: 18
            property string label: "T"
            property color bodyColor: Palette.wax
            property color rimColor:  Palette.gilt
            property color textColor: Palette.gilt
            property real rimOpacity: 1.0
            implicitWidth: diameter
            implicitHeight: diameter

            Rectangle {
                anchors.fill: parent
                radius: sealRoot.diameter / 2
                color: sealRoot.bodyColor
                antialiasing: true
                border.color: sealRoot.rimColor
                border.width: Math.max(1, sealRoot.diameter / 18)
                opacity: 1.0

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: sealRoot.rimColor
                    border.width: parent.border.width
                    opacity: sealRoot.rimOpacity
                    antialiasing: true
                }
            }

            Text {
                anchors.centerIn: parent
                text: sealRoot.label
                color: sealRoot.textColor
                font.family: Palette.fontInitial
                font.pixelSize: sealRoot.diameter * 0.56
            }
        }
    }

    // ---- PageCorner: turned-down paper corner (top-right placement) -----
    property Component PageCorner: Component {
        Item {
            id: cornerRoot
            property real size: 16
            property color fold: Palette.paperShadow
            property color edge: Palette.gilt
            implicitWidth: size
            implicitHeight: size

            Shape {
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    strokeColor: cornerRoot.edge
                    strokeWidth: 0.75
                    fillColor: cornerRoot.fold
                    startX: cornerRoot.size; startY: 0
                    PathLine { x: 0;                 y: 0 }
                    PathLine { x: cornerRoot.size;  y: cornerRoot.size }
                    PathLine { x: cornerRoot.size;  y: 0 }
                }
            }
        }
    }
}
```

Note: `QtQuick.Shapes` is a standard Qt 6 module; no extra install needed.

- [ ] **Step 2: qmllint**

Run:
```bash
cd /mnt/hangar/projects/kdeshboard
$QMLLINT shared/qml/Ornaments.qml
```
Expected: exit 0. Import-resolution warnings are fine.

- [ ] **Step 3: Commit**

```bash
git add shared/qml/Ornaments.qml
git commit -m "feat(shared): add Ornaments component library

DoubleRule, Fleuron, WaxSeal, PageCorner — exposed as Component
properties on a QtObject so callers instantiate them as inline
Components. Uses QtQuick.Shapes for the corner fold path."
```

---

## Task 6: Shared QML — `ParchmentBackground.qml`

**Files:** Create `shared/qml/ParchmentBackground.qml`.

- [ ] **Step 1: Write the background component**

Create `/mnt/hangar/projects/kdeshboard/shared/qml/ParchmentBackground.qml`:
```qml
// Parchment panel: base color + faint SVG turbulence noise overlay +
// optional foxing spots. Drop into any plasmoid's fullRepresentation.
// Palette is accessible unprefixed (same-module singleton).
import QtQuick

Rectangle {
    id: root
    property real cornerRadius: 4
    property bool showFoxing: true
    property real noiseOpacity: 0.06

    color: Palette.parchment
    radius: cornerRadius
    antialiasing: true
    clip: true
    border.color: Palette.gilt
    border.width: 0
    // Shadow — a second rect layered behind, at a slight y-offset,
    // in paperShadow. Parent must clip false; we rely on layering from
    // outside instead of from here. Callers who want shadow wrap this.

    // --- Noise overlay (inline SVG turbulence) --------------------------
    Image {
        id: noise
        anchors.fill: parent
        opacity: root.noiseOpacity
        fillMode: Image.Tile
        source: "data:image/svg+xml;utf8," + encodeURIComponent(
            '<svg xmlns="http://www.w3.org/2000/svg" width="140" height="140">' +
              '<filter id="n">' +
                '<feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="7"/>' +
                '<feColorMatrix values="0 0 0 0 0.18  0 0 0 0 0.12  0 0 0 0 0.07  0 0 0 0.7 0"/>' +
              '</filter>' +
              '<rect width="140" height="140" filter="url(#n)"/>' +
            '</svg>')
        smooth: false
    }

    // --- Foxing spots — three soft ellipses, very low opacity -----------
    Repeater {
        model: root.showFoxing ? 3 : 0
        Rectangle {
            parent: root
            property real spotSize: 14 + (index * 9) % 18
            width: spotSize
            height: spotSize
            radius: spotSize / 2
            color: Palette.foxing
            opacity: 0.10
            x: (index === 0 ? 0.12 : index === 1 ? 0.78 : 0.55) * root.width
            y: (index === 0 ? 0.82 : index === 1 ? 0.22 : 0.48) * root.height
            antialiasing: true
            visible: root.width > 120 && root.height > 80
        }
    }
}
```

- [ ] **Step 2: qmllint**

Run:
```bash
cd /mnt/hangar/projects/kdeshboard
$QMLLINT shared/qml/ParchmentBackground.qml
```
Expected: exit 0.

- [ ] **Step 3: Commit**

```bash
git add shared/qml/ParchmentBackground.qml
git commit -m "feat(shared): add ParchmentBackground component

Rectangle + inline SVG turbulence-noise overlay + three foxing spots
at deterministic positions. Drop-in background for every widget."
```

---

## Task 7: Shared QML — `MoonPhase.qml`

**Files:** Create `shared/qml/MoonPhase.qml`.

- [ ] **Step 1: Write the moon-phase component**

Create `/mnt/hangar/projects/kdeshboard/shared/qml/MoonPhase.qml`:
```qml
// MoonPhase: computes current phase index (0..7) and draws it with QtQuick.Shapes.
// 0=new, 1=waxing crescent, 2=first quarter, 3=waxing gibbous,
// 4=full, 5=waning gibbous, 6=third quarter, 7=waning crescent.
// Palette is accessible unprefixed (same-module singleton).
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property real size: 28
    property color ink: Palette.inkDark
    property int phase: currentPhase()
    implicitWidth: size
    implicitHeight: size

    function currentPhase() {
        const now = new Date()
        const julian = now.getTime() / 86400000 + 2440587.5
        const age = ((julian - 2451549.5) % 29.53059 + 29.53059) % 29.53059
        return Math.floor((age / 29.53059) * 8) % 8
    }

    // Recompute at midnight via a timer.
    Timer {
        interval: 60 * 60 * 1000  // 1h; cheap enough to just check hourly
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.phase = root.currentPhase()
    }

    Shape {
        anchors.fill: parent
        antialiasing: true

        // Full moon disk as base outline
        ShapePath {
            strokeColor: root.ink
            strokeWidth: 1
            fillColor: "transparent"
            startX: root.size / 2; startY: 0
            PathArc {
                x: root.size / 2; y: root.size
                radiusX: root.size / 2; radiusY: root.size / 2
                direction: PathArc.Clockwise
            }
            PathArc {
                x: root.size / 2; y: 0
                radiusX: root.size / 2; radiusY: root.size / 2
                direction: PathArc.Clockwise
            }
        }

        // Phase fill — a filled shape whose geometry depends on `phase`.
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: root.phase === 0 ? "transparent" : root.ink
            startX: root.size / 2; startY: 0
            // Right half
            PathArc {
                x: root.size / 2; y: root.size
                radiusX: root.size / 2; radiusY: root.size / 2
                direction: (root.phase >= 1 && root.phase <= 3) || root.phase === 4
                           ? PathArc.Clockwise
                           : PathArc.Counterclockwise
            }
            // Terminator (inner arc) — ellipse with radiusX proportional to phase offset from full
            // Map: 0->full-dark-side radius=R, 1->3R/4, 2->R/2, 3->R/4, 4->0 (full), 5->R/4, 6->R/2, 7->3R/4
            PathArc {
                x: root.size / 2; y: 0
                radiusX: {
                    const r = root.size / 2
                    const offsets = [r, 3*r/4, r/2, r/4, 0, r/4, r/2, 3*r/4]
                    return offsets[root.phase]
                }
                radiusY: root.size / 2
                direction: (root.phase >= 1 && root.phase <= 3)
                           ? PathArc.Counterclockwise
                           : PathArc.Clockwise
            }
        }
    }
}
```

- [ ] **Step 2: Sanity-check the phase algorithm in isolation**

Run (the algorithm in JS, to verify phase-on-a-known-date):
```bash
node -e '
const d = new Date("2026-04-24T12:00:00Z")
const julian = d.getTime() / 86400000 + 2440587.5
const age = ((julian - 2451549.5) % 29.53059 + 29.53059) % 29.53059
console.log("age-in-days:", age.toFixed(2), "phase:", Math.floor((age/29.53059)*8)%8)
' 2>/dev/null || python3 -c '
import datetime
d = datetime.datetime(2026, 4, 24, 12, 0, 0, tzinfo=datetime.timezone.utc)
julian = d.timestamp() / 86400.0 + 2440587.5
age = ((julian - 2451549.5) % 29.53059 + 29.53059) % 29.53059
print(f"age-in-days: {age:.2f} phase: {int((age/29.53059)*8)%8}")'
```
Expected: an age-in-days between 0 and 29.53 and a phase between 0 and 7. (Exact value depends on when you run this; on 2026-04-24 the age should be roughly 7 days → phase 1 or 2.)

- [ ] **Step 3: qmllint**

Run:
```bash
cd /mnt/hangar/projects/kdeshboard
$QMLLINT shared/qml/MoonPhase.qml
```
Expected: exit 0.

- [ ] **Step 4: Commit**

```bash
git add shared/qml/MoonPhase.qml
git commit -m "feat(shared): add MoonPhase component

Computes phase from Julian Date mod synodic month. 8 phases rendered
with QtQuick.Shapes (two arcs — disk outline + terminator ellipse).
Refreshes hourly; phase only changes on day boundaries in practice."
```

---

## Task 8: Plasmoid — Luxury Greeting

**Files:**
- Create: `plasmoids/com.utku.luxurygreeting/metadata.json`
- Create: `plasmoids/com.utku.luxurygreeting/contents/ui/main.qml`
- Create: `plasmoids/com.utku.luxurygreeting/contents/ui/configGeneral.qml`
- Create: `plasmoids/com.utku.luxurygreeting/contents/config/config.qml`
- Create: `plasmoids/com.utku.luxurygreeting/contents/config/main.xml`
- Delete: the `.gitkeep` in the affected directories (automatic once files are added, but `git rm` them)

- [ ] **Step 1: Write `metadata.json`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.luxurygreeting/metadata.json`:
```json
{
  "KPackageStructure": "Plasma/Applet",
  "KPlugin": {
    "Authors": [{ "Name": "Utku" }],
    "Category": "Utilities",
    "Description": "Adaptive greeting in cursive with a journal date line",
    "Icon": "preferences-desktop-notification",
    "Id": "com.utku.luxurygreeting",
    "License": "MIT",
    "Name": "Luxury Greeting",
    "Version": "1.0"
  },
  "X-Plasma-API-Minimum-Version": "6.0"
}
```

- [ ] **Step 2: Write `config/main.xml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.luxurygreeting/contents/config/main.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.kde.org/standards/kcfg/1.0
                          http://www.kde.org/standards/kcfg/1.0/kcfg.xsd">
  <kcfgfile name="luxurygreetingrc"/>
  <group name="General">
    <entry name="userName" type="String">
      <default>Utku</default>
    </entry>
    <entry name="birthday" type="String">
      <default></default>
    </entry>
    <entry name="phrasePoolSeed" type="Int">
      <default>0</default>
    </entry>
  </group>
</kcfg>
```

- [ ] **Step 3: Write `config/config.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.luxurygreeting/contents/config/config.qml`:
```qml
import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "General"
        icon: "preferences-desktop"
        source: "configGeneral.qml"
    }
}
```

- [ ] **Step 4: Write `ui/configGeneral.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.luxurygreeting/contents/ui/configGeneral.qml`:
```qml
import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_userName:       userNameField.text
    property alias cfg_birthday:       birthdayField.text
    property alias cfg_phrasePoolSeed: seedSpin.value

    TextField {
        id: userNameField
        Kirigami.FormData.label: "Your name:"
    }
    TextField {
        id: birthdayField
        Kirigami.FormData.label: "Birthday (MM-DD):"
        placeholderText: "e.g. 07-14 — leave empty to disable"
    }
    SpinBox {
        id: seedSpin
        Kirigami.FormData.label: "Phrase seed:"
        from: 0
        to: 999
    }
}
```

- [ ] **Step 5: Write `ui/main.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.luxurygreeting/contents/ui/main.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "shared" as Shared

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property string userName: Plasmoid.configuration.userName
    property string birthday: Plasmoid.configuration.birthday
    property int    phrasePoolSeed: Plasmoid.configuration.phrasePoolSeed

    property string dropCapLetter: ""
    property string phraseRemainder: ""
    property string subtitleText: ""

    readonly property var pools: ({
        smallHours: [
            "Still up, %N?",
            "The small hours, %N.",
            "It is late, %N.",
            "Not yet asleep, %N?",
            "The lamps are low, %N."
        ],
        morning: [
            "Good morning, %N.",
            "The day, %N, begins.",
            "A fresh page, %N.",
            "Dawn already, %N?",
            "Morning, %N — the coffee first."
        ],
        afternoon: [
            "Good afternoon, %N.",
            "Midday passes, %N.",
            "The hours settle, %N.",
            "A steady afternoon, %N.",
            "The sun leans west, %N."
        ],
        evening: [
            "Good evening, %N.",
            "Evening, %N — the day closes.",
            "The lamps come on, %N.",
            "A quiet hour, %N.",
            "The night is yours, %N."
        ],
        birthday: [
            "A blessed new year, %N.",
            "The pen marks a year more, %N.",
            "Many more pages, %N."
        ]
    })

    function dayOfYear(d) {
        const start = new Date(d.getFullYear(), 0, 0)
        const diff = d - start + (start.getTimezoneOffset() - d.getTimezoneOffset()) * 60000
        return Math.floor(diff / 86400000)
    }

    function periodFor(hour) {
        if (hour < 5)  return "smallHours"
        if (hour < 12) return "morning"
        if (hour < 17) return "afternoon"
        return "evening"
    }

    function periodLabel(hour) {
        if (hour < 5)  return "in the small hours"
        if (hour < 12) return "in the morning"
        if (hour < 17) return "in the afternoon"
        if (hour < 21) return "in the evening"
        return "late at night"
    }

    function contextClause(d, period) {
        const dow = d.getDay()   // 0=Sun..6=Sat
        const hour = d.getHours()
        const date = d.getDate()
        if (dow === 1 && hour < 12)   return " — the week opens."
        if (dow === 5 && hour >= 17)  return " — the week folds in on itself."
        if (date === 1 && hour < 12)  return " — a fresh chapter."
        return ""
    }

    function isBirthday(d) {
        if (!birthday) return false
        const mm = (d.getMonth() + 1).toString().padStart(2, "0")
        const dd = d.getDate().toString().padStart(2, "0")
        return birthday === (mm + "-" + dd)
    }

    function ordinal(n) {
        const s = ["th", "st", "nd", "rd"]
        const v = n % 100
        return n + (s[(v - 20) % 10] || s[v] || s[0])
    }

    function updateGreeting() {
        const d = new Date()
        const h = d.getHours()
        const period = periodFor(h)
        let pool, phrase

        if (isBirthday(d)) {
            pool = pools.birthday
            const idx = (dayOfYear(d) + phrasePoolSeed) % pool.length
            phrase = pool[idx].replace("%N", userName)
        } else {
            pool = pools[period]
            const idx = (dayOfYear(d) + phrasePoolSeed) % pool.length
            phrase = pool[idx].replace("%N", userName)
            phrase = phrase.replace(/\.$/, "") + contextClause(d, period)
            if (!/[.!?]$/.test(phrase)) phrase += "."
        }

        dropCapLetter = phrase.charAt(0)
        phraseRemainder = phrase.slice(1)

        const days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
        const months = ["January","February","March","April","May","June",
                        "July","August","September","October","November","December"]
        subtitleText = days[d.getDay()] + ", the " + ordinal(d.getDate()) +
                       " of " + months[d.getMonth()] + ", " + d.getFullYear() +
                       " · " + periodLabel(h)
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateGreeting()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 520
        Layout.preferredHeight: 120
        Layout.minimumWidth: 340
        Layout.minimumHeight: 90

        Shared.ParchmentBackground {
            anchors.fill: parent
        }

        Loader {
            id: cornerLoader
            sourceComponent: Shared.Ornaments.PageCorner
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 0
            anchors.rightMargin: 0
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    id: dropCap
                    text: root.dropCapLetter
                    color: Shared.Palette.wax
                    font.family: Shared.Palette.fontInitial
                    font.pixelSize: 56
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.92; to: 1.0; duration: 3000; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 1.0; to: 0.92; duration: 3000; easing.type: Easing.InOutSine }
                    }
                }

                Text {
                    text: root.phraseRemainder
                    color: Shared.Palette.burgundy
                    font.family: Shared.Palette.fontDisplay
                    font.pixelSize: 44
                    Layout.fillWidth: true
                    elide: Text.ElideRight

                    Behavior on text { SequentialAnimation {
                        NumberAnimation { target: parent; property: "opacity"; to: 0; duration: 100 }
                        PropertyAction {}
                        NumberAnimation { target: parent; property: "opacity"; to: 1; duration: 200 }
                    } }
                }
            }

            Loader {
                sourceComponent: Shared.Ornaments.DoubleRule
                Layout.fillWidth: true
                Layout.topMargin: 2
            }

            Text {
                text: root.subtitleText
                color: Shared.Palette.inkMedium
                font.family: Shared.Palette.fontAccent
                font.pixelSize: 16
                Layout.fillWidth: true
            }
        }
    }
}
```

- [ ] **Step 6: Validate `metadata.json`**

Run:
```bash
cd /mnt/hangar/projects/kdeshboard
jq -e . plasmoids/com.utku.luxurygreeting/metadata.json >/dev/null && echo OK
```
Expected: `OK`.

- [ ] **Step 7: Validate `main.xml`**

Run:
```bash
cd /mnt/hangar/projects/kdeshboard
xmllint --noout plasmoids/com.utku.luxurygreeting/contents/config/main.xml && echo OK
```
Expected: `OK`.

- [ ] **Step 8: qmllint each QML file**

Run:
```bash
cd /mnt/hangar/projects/kdeshboard
$QMLLINT plasmoids/com.utku.luxurygreeting/contents/ui/main.qml \
         plasmoids/com.utku.luxurygreeting/contents/ui/configGeneral.qml \
         plasmoids/com.utku.luxurygreeting/contents/config/config.qml
```
Expected: exit 0; import-resolution warnings for Plasma/Kirigami modules are acceptable (these resolve in-Plasma).

- [ ] **Step 9: Remove `.gitkeep` markers that are now replaced by real files**

Run:
```bash
cd /mnt/hangar/projects/kdeshboard
rm plasmoids/com.utku.luxurygreeting/contents/ui/.gitkeep \
   plasmoids/com.utku.luxurygreeting/contents/config/.gitkeep
```

- [ ] **Step 10: Commit**

```bash
cd /mnt/hangar/projects/kdeshboard
git add plasmoids/com.utku.luxurygreeting
git commit -m "feat(greeting): add Luxury Greeting plasmoid

Drop-cap in IM FELL DW Pica (wax color, ambient opacity cycle) +
Parisienne phrase. 20 phrases across 4 periods, selected by
(dayOfYear + seed) mod pool. Monday/Friday/1st-of-month context
clauses and a 3-phrase birthday pool when the configured MM-DD
matches today. Subtitle in Caveat, DoubleRule between lines."
```

---

## Task 9: Plasmoid — Tmux Tail

**Files:**
- Create: `plasmoids/com.utku.tmuxtail/metadata.json`
- Create: `plasmoids/com.utku.tmuxtail/contents/ui/main.qml`
- Create: `plasmoids/com.utku.tmuxtail/contents/ui/configGeneral.qml`
- Create: `plasmoids/com.utku.tmuxtail/contents/config/config.qml`
- Create: `plasmoids/com.utku.tmuxtail/contents/config/main.xml`

- [ ] **Step 1: Write `metadata.json`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.tmuxtail/metadata.json`:
```json
{
  "KPackageStructure": "Plasma/Applet",
  "KPlugin": {
    "Authors": [{ "Name": "Utku" }],
    "Category": "System Information",
    "Description": "Tails a tmux pane into a leather-bound panel",
    "Icon": "utilities-terminal",
    "Id": "com.utku.tmuxtail",
    "License": "MIT",
    "Name": "Tmux Tail",
    "Version": "1.0"
  },
  "X-Plasma-API-Minimum-Version": "6.0"
}
```

- [ ] **Step 2: Write `config/main.xml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.tmuxtail/contents/config/main.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.kde.org/standards/kcfg/1.0
                          http://www.kde.org/standards/kcfg/1.0/kcfg.xsd">
  <kcfgfile name="tmuxtailrc"/>
  <group name="General">
    <entry name="tmuxTarget" type="String">
      <default>research:0</default>
    </entry>
    <entry name="lineCount" type="Int">
      <default>14</default>
    </entry>
    <entry name="refreshMs" type="Int">
      <default>2000</default>
    </entry>
    <entry name="attachCommand" type="String">
      <default>konsole -e tmux attach -t research</default>
    </entry>
  </group>
</kcfg>
```

- [ ] **Step 3: Write `config/config.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.tmuxtail/contents/config/config.qml`:
```qml
import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "General"
        icon: "preferences-desktop"
        source: "configGeneral.qml"
    }
}
```

- [ ] **Step 4: Write `ui/configGeneral.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.tmuxtail/contents/ui/configGeneral.qml`:
```qml
import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_tmuxTarget:    targetField.text
    property alias cfg_lineCount:     linesSpin.value
    property alias cfg_refreshMs:     refreshSpin.value
    property alias cfg_attachCommand: attachField.text

    TextField {
        id: targetField
        Kirigami.FormData.label: "tmux target:"
        placeholderText: "session:window[.pane]"
    }
    SpinBox {
        id: linesSpin
        Kirigami.FormData.label: "Lines to capture:"
        from: 1
        to: 200
    }
    SpinBox {
        id: refreshSpin
        Kirigami.FormData.label: "Refresh (ms):"
        from: 500
        to: 60000
        stepSize: 500
    }
    TextField {
        id: attachField
        Kirigami.FormData.label: "On double-click:"
        placeholderText: "konsole -e tmux attach -t <session>"
    }
}
```

- [ ] **Step 5: Write `ui/main.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.tmuxtail/contents/ui/main.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "shared" as Shared

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property string tmuxTarget: Plasmoid.configuration.tmuxTarget
    property int    lineCount:  Plasmoid.configuration.lineCount
    property int    refreshMs:  Plasmoid.configuration.refreshMs
    property string attachCmd:  Plasmoid.configuration.attachCommand
    property string paneContent: ""
    property bool   sessionFound: true

    function stripAnsi(s) {
        return s.replace(/\x1b\[[0-9;]*m/g, "")
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            const exitCode = data["exit code"]
            const stdout = data["stdout"] || ""
            if (sourceName.indexOf("capture-pane") !== -1) {
                if (exitCode === 0) {
                    root.paneContent = root.stripAnsi(stdout)
                    root.sessionFound = true
                } else {
                    root.sessionFound = false
                    root.paneContent = ""
                }
            }
            disconnectSource(sourceName)
        }

        function exec(cmd) { if (cmd) connectSource(cmd) }
    }

    Timer {
        interval: root.refreshMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            executable.exec("tmux capture-pane -p -S -"
                            + root.lineCount + " -t " + root.tmuxTarget)
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 560
        Layout.preferredHeight: 300
        Layout.minimumWidth: 300
        Layout.minimumHeight: 160

        Shared.ParchmentBackground { anchors.fill: parent }

        Loader {
            sourceComponent: Shared.Ornaments.PageCorner
            anchors.top: parent.top
            anchors.right: parent.right
        }

        Loader {
            id: sealLoader
            sourceComponent: Shared.Ornaments.WaxSeal
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 10
            anchors.rightMargin: 26
            SequentialAnimation {
                loops: Animation.Infinite
                running: true
                NumberAnimation { target: sealLoader.item; property: "rimOpacity"; from: 0.85; to: 1.0; duration: 2500; easing.type: Easing.InOutSine }
                NumberAnimation { target: sealLoader.item; property: "rimOpacity"; from: 1.0; to: 0.85; duration: 2500; easing.type: Easing.InOutSine }
            }
        }

        ToolTip.visible: sealMouse.containsMouse
        ToolTip.text: "double-click to attach"
        MouseArea {
            id: sealMouse
            anchors.fill: sealLoader
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            Text {
                text: root.sessionFound
                      ? ("// " + root.tmuxTarget)
                      : "// session not found"
                color: Shared.Palette.burgundy
                font.family: Shared.Palette.fontAccent
                font.pixelSize: 19
                Layout.fillWidth: true
            }

            Loader {
                sourceComponent: Shared.Ornaments.DoubleRule
                Layout.fillWidth: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                TextArea {
                    id: logView
                    text: root.paneContent
                    font.family: Shared.Palette.fontMono
                    font.pixelSize: 11
                    color: Shared.Palette.inkDark
                    readOnly: true
                    wrapMode: TextArea.NoWrap
                    selectByMouse: true
                    background: null
                    onTextChanged: cursorPosition = text.length
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            propagateComposedEvents: true
            onDoubleClicked: if (root.attachCmd) executable.exec(root.attachCmd)
        }
    }
}
```

- [ ] **Step 6: Validate metadata + XML**

Run:
```bash
cd /mnt/hangar/projects/kdeshboard
jq -e . plasmoids/com.utku.tmuxtail/metadata.json >/dev/null && \
xmllint --noout plasmoids/com.utku.tmuxtail/contents/config/main.xml && echo OK
```
Expected: `OK`.

- [ ] **Step 7: qmllint**

Run:
```bash
cd /mnt/hangar/projects/kdeshboard
$QMLLINT plasmoids/com.utku.tmuxtail/contents/ui/main.qml \
         plasmoids/com.utku.tmuxtail/contents/ui/configGeneral.qml \
         plasmoids/com.utku.tmuxtail/contents/config/config.qml
```
Expected: exit 0.

- [ ] **Step 8: Remove .gitkeep markers**

Run:
```bash
cd /mnt/hangar/projects/kdeshboard
rm plasmoids/com.utku.tmuxtail/contents/ui/.gitkeep \
   plasmoids/com.utku.tmuxtail/contents/config/.gitkeep
```

- [ ] **Step 9: Commit**

```bash
cd /mnt/hangar/projects/kdeshboard
git add plasmoids/com.utku.tmuxtail
git commit -m "feat(tmux): add Tmux Tail plasmoid

Captures N lines from a configured tmux target every refreshMs via
Plasma5Support.DataSource. WaxSeal 'T' with breathing gilt rim in
the top-right, tooltipped 'double-click to attach'. Double-click on
widget runs attachCommand. Graceful 'session not found' sad path."
```

---

## Task 10: Plasmoid — Journal Tasks

**Files:**
- Create: `plasmoids/com.utku.journaltasks/metadata.json`
- Create: `plasmoids/com.utku.journaltasks/contents/ui/main.qml`
- Create: `plasmoids/com.utku.journaltasks/contents/ui/TaskItem.qml`
- Create: `plasmoids/com.utku.journaltasks/contents/ui/configGeneral.qml`
- Create: `plasmoids/com.utku.journaltasks/contents/config/config.qml`
- Create: `plasmoids/com.utku.journaltasks/contents/config/main.xml`

- [ ] **Step 1: Write `metadata.json`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journaltasks/metadata.json`:
```json
{
  "KPackageStructure": "Plasma/Applet",
  "KPlugin": {
    "Authors": [{ "Name": "Utku" }],
    "Category": "Utilities",
    "Description": "File-backed tasks rendered as a journal page",
    "Icon": "view-task",
    "Id": "com.utku.journaltasks",
    "License": "MIT",
    "Name": "Journal Tasks",
    "Version": "1.0"
  },
  "X-Plasma-API-Minimum-Version": "6.0"
}
```

- [ ] **Step 2: Write `config/main.xml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journaltasks/contents/config/main.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.kde.org/standards/kcfg/1.0
                          http://www.kde.org/standards/kcfg/1.0/kcfg.xsd">
  <kcfgfile name="journaltasksrc"/>
  <group name="General">
    <entry name="filePath" type="String">
      <default>~/notes/tasks.md</default>
    </entry>
    <entry name="showCompleted" type="Bool">
      <default>true</default>
    </entry>
    <entry name="sectionFilter" type="String">
      <default></default>
    </entry>
    <entry name="refreshMs" type="Int">
      <default>2000</default>
    </entry>
  </group>
</kcfg>
```

- [ ] **Step 3: Write `config/config.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journaltasks/contents/config/config.qml`:
```qml
import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "General"
        icon: "preferences-desktop"
        source: "configGeneral.qml"
    }
}
```

- [ ] **Step 4: Write `ui/configGeneral.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journaltasks/contents/ui/configGeneral.qml`:
```qml
import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_filePath:       pathField.text
    property alias cfg_showCompleted:  showCompletedBox.checked
    property alias cfg_sectionFilter:  filterField.text
    property alias cfg_refreshMs:      refreshSpin.value

    TextField {
        id: pathField
        Kirigami.FormData.label: "Tasks file:"
        placeholderText: "~/notes/tasks.md"
    }
    CheckBox {
        id: showCompletedBox
        Kirigami.FormData.label: "Show completed:"
    }
    TextField {
        id: filterField
        Kirigami.FormData.label: "Section filter (comma-separated):"
        placeholderText: "empty = show all"
    }
    SpinBox {
        id: refreshSpin
        Kirigami.FormData.label: "Refresh (ms):"
        from: 500
        to: 60000
        stepSize: 500
    }
}
```

- [ ] **Step 5: Write `ui/TaskItem.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journaltasks/contents/ui/TaskItem.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "shared" as Shared

Item {
    id: root
    property bool checked: false
    property string body: ""
    property int indent: 0
    signal toggled()

    implicitHeight: row.implicitHeight + 4

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 24 + root.indent * 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            id: box
            width: 14; height: 14; radius: 7
            color: "transparent"
            border.color: Shared.Palette.gilt
            border.width: 1
            antialiasing: true

            Text {
                anchors.centerIn: parent
                visible: root.checked
                text: "✓"
                color: Shared.Palette.wax
                font.family: Shared.Palette.fontInitial
                font.pixelSize: 11
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggled()
            }
        }

        Text {
            text: root.body
            color: root.checked ? Shared.Palette.inkMedium : Shared.Palette.inkDark
            font.family: Shared.Palette.fontSerif
            font.pixelSize: 14
            font.strikeout: root.checked
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Behavior on font.strikeout { enabled: false } // purely cosmetic flip; opacity animates instead
            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }
}
```

- [ ] **Step 6: Write `ui/main.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journaltasks/contents/ui/main.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "shared" as Shared

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property string filePath: Plasmoid.configuration.filePath
    property bool   showCompleted: Plasmoid.configuration.showCompleted
    property string sectionFilter: Plasmoid.configuration.sectionFilter
    property int    refreshMs: Plasmoid.configuration.refreshMs
    property string fileContent: ""
    property int    lastMtime: 0

    ListModel { id: entries }

    function expandPath(p) {
        if (p.startsWith("~/"))
            return executable.homeDir + "/" + p.slice(2)
        return p
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        property string homeDir: ""

        onNewData: function(sourceName, data) {
            const stdout = (data["stdout"] || "").replace(/\n$/, "")
            const exitCode = data["exit code"]
            if (sourceName.indexOf("echo $HOME") !== -1) {
                homeDir = stdout
            } else if (sourceName.indexOf("stat -c") !== -1) {
                const mtime = parseInt(stdout, 10) || 0
                if (mtime !== root.lastMtime) {
                    root.lastMtime = mtime
                    executable.exec("cat " + quote(root.expandPath(root.filePath)))
                }
            } else if (sourceName.startsWith("cat ")) {
                if (exitCode === 0) {
                    root.fileContent = stdout
                    rebuildModel()
                } else {
                    entries.clear()
                    entries.append({ kind: "error", text: "— the page is blank. —" })
                }
            }
            disconnectSource(sourceName)
        }
        function exec(cmd) { if (cmd) connectSource(cmd) }
    }

    function quote(s) { return "'" + s.replace(/'/g, "'\\''") + "'" }

    function rebuildModel() {
        entries.clear()
        const lines = root.fileContent.split("\n")
        const filters = root.sectionFilter
            .split(",").map(s => s.trim().toLowerCase()).filter(s => s.length > 0)
        let inFilteredSection = (filters.length === 0)

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            const headerMatch = line.match(/^(#{1,3})\s+(.+)$/)
            if (headerMatch) {
                const title = headerMatch[2]
                inFilteredSection = (filters.length === 0) ||
                    filters.includes(title.toLowerCase())
                if (inFilteredSection)
                    entries.append({ kind: "header", text: title, indent: 0, lineIndex: i, checked: false })
                continue
            }
            if (!inFilteredSection) continue

            const taskMatch = line.match(/^(\s*)- \[( |x|X)\]\s+(.*)$/)
            if (taskMatch) {
                const depth = Math.floor(taskMatch[1].length / 2)
                const done = taskMatch[2].toLowerCase() === "x"
                if (!done || root.showCompleted)
                    entries.append({ kind: "task", text: taskMatch[3], indent: depth,
                                     lineIndex: i, checked: done })
                continue
            }
            if (line.trim().length > 0)
                entries.append({ kind: "body", text: line, indent: 0, lineIndex: i, checked: false })
        }
    }

    function toggleLine(lineIndex, newChecked) {
        const lines = root.fileContent.split("\n")
        const line = lines[lineIndex]
        const replaced = line.replace(/^(\s*- \[)( |x|X)(\]\s+.*)$/,
            (_, pre, _old, post) => pre + (newChecked ? "x" : " ") + post)
        lines[lineIndex] = replaced
        const newContent = lines.join("\n")
        root.fileContent = newContent
        const expanded = root.expandPath(root.filePath)
        executable.exec("printf '%s' " + quote(newContent) + " > " + quote(expanded))
        rebuildModel()
    }

    function appendTask(body) {
        if (!body.trim()) return
        const lines = root.fileContent.split("\n")
        let insertAt = lines.length
        // Find last section header (top-level) and insert after its items.
        let lastHeader = -1
        for (let i = 0; i < lines.length; i++)
            if (/^#{1,3}\s/.test(lines[i])) lastHeader = i
        if (lastHeader >= 0) {
            let j = lastHeader + 1
            while (j < lines.length && !/^#{1,3}\s/.test(lines[j])) j++
            insertAt = j
        }
        const newLine = "- [ ] " + body.trim()
        lines.splice(insertAt, 0, newLine)
        const newContent = lines.join("\n").replace(/\n*$/, "\n")
        root.fileContent = newContent
        executable.exec("printf '%s' " + quote(newContent) + " > " + quote(root.expandPath(root.filePath)))
        rebuildModel()
    }

    Timer {
        interval: root.refreshMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!executable.homeDir) {
                executable.exec("echo $HOME")
            } else {
                executable.exec("stat -c %Y " + quote(root.expandPath(root.filePath)))
            }
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 420
        Layout.preferredHeight: 360
        Layout.minimumWidth: 280
        Layout.minimumHeight: 180

        Shared.ParchmentBackground { anchors.fill: parent }
        Loader { sourceComponent: Shared.Ornaments.PageCorner; anchors.top: parent.top; anchors.right: parent.right }

        // Gilt margin rule on the left
        Rectangle {
            x: 24
            y: 10
            width: 1
            height: parent.height - 20
            color: Shared.Palette.gilt
            opacity: 0.40
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 4

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: listView
                    model: entries
                    spacing: 2
                    delegate: Item {
                        width: listView.width
                        implicitHeight: loader.item ? loader.item.implicitHeight : 0

                        Loader {
                            id: loader
                            width: parent.width
                            sourceComponent: {
                                if (model.kind === "header") return headerCmp
                                if (model.kind === "task")   return taskCmp
                                if (model.kind === "body")   return bodyCmp
                                return errorCmp
                            }
                        }

                        Component {
                            id: headerCmp
                            Column {
                                spacing: 2
                                Text {
                                    text: model.text.toUpperCase()
                                    color: Shared.Palette.burgundy
                                    font.family: Shared.Palette.fontSmallCaps
                                    font.pixelSize: 13
                                    font.letterSpacing: 1.4
                                    leftPadding: 24
                                    topPadding: 8
                                }
                                Loader {
                                    sourceComponent: Shared.Ornaments.DoubleRule
                                    width: parent.width - 24
                                    x: 24
                                }
                            }
                        }
                        Component {
                            id: taskCmp
                            TaskItem {
                                checked: model.checked
                                body: model.text
                                indent: model.indent
                                onToggled: root.toggleLine(model.lineIndex, !model.checked)
                            }
                        }
                        Component {
                            id: bodyCmp
                            Text {
                                text: model.text
                                color: Shared.Palette.inkMedium
                                font.family: Shared.Palette.fontSerif
                                font.pixelSize: 13
                                font.italic: true
                                leftPadding: 24
                                wrapMode: Text.WordWrap
                            }
                        }
                        Component {
                            id: errorCmp
                            Text {
                                text: model.text
                                color: Shared.Palette.inkMedium
                                font.family: Shared.Palette.fontAccent
                                font.pixelSize: 14
                                leftPadding: 24
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                spacing: 6

                Text {
                    text: "❧"
                    color: Shared.Palette.gilt
                    font.family: Shared.Palette.fontSerif
                    font.pixelSize: 14
                }
                TextField {
                    id: addField
                    Layout.fillWidth: true
                    placeholderText: "a new entry…"
                    font.family: Shared.Palette.fontAccent
                    font.pixelSize: 14
                    color: Shared.Palette.inkDark
                    background: null
                    onAccepted: {
                        root.appendTask(text)
                        text = ""
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 7: Validate metadata + XML**

```bash
cd /mnt/hangar/projects/kdeshboard
jq -e . plasmoids/com.utku.journaltasks/metadata.json >/dev/null && \
xmllint --noout plasmoids/com.utku.journaltasks/contents/config/main.xml && echo OK
```
Expected: `OK`.

- [ ] **Step 8: qmllint**

```bash
cd /mnt/hangar/projects/kdeshboard
$QMLLINT plasmoids/com.utku.journaltasks/contents/ui/main.qml \
         plasmoids/com.utku.journaltasks/contents/ui/TaskItem.qml \
         plasmoids/com.utku.journaltasks/contents/ui/configGeneral.qml \
         plasmoids/com.utku.journaltasks/contents/config/config.qml
```
Expected: exit 0.

- [ ] **Step 9: Remove .gitkeep markers and commit**

```bash
cd /mnt/hangar/projects/kdeshboard
rm plasmoids/com.utku.journaltasks/contents/ui/.gitkeep \
   plasmoids/com.utku.journaltasks/contents/config/.gitkeep
git add plasmoids/com.utku.journaltasks
git commit -m "feat(tasks): add Journal Tasks plasmoid

Reads ~/notes/tasks.md (path configurable), recognizes ## headers and
- [ ] / - [x] items. Checkbox click rewrites that single line in the
file via printf/shell-redirect. Inline 'a new entry…' input appends
under the last section header. Section headers in Cormorant SC small
caps, gilt margin rule on left edge."
```

---

## Task 11: Plasmoid — Journal Clock

**Files:**
- Create: `plasmoids/com.utku.journalclock/metadata.json`
- Create: `plasmoids/com.utku.journalclock/contents/ui/main.qml`
- Create: `plasmoids/com.utku.journalclock/contents/ui/configGeneral.qml`
- Create: `plasmoids/com.utku.journalclock/contents/config/config.qml`
- Create: `plasmoids/com.utku.journalclock/contents/config/main.xml`

- [ ] **Step 1: Write `metadata.json`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journalclock/metadata.json`:
```json
{
  "KPackageStructure": "Plasma/Applet",
  "KPlugin": {
    "Authors": [{ "Name": "Utku" }],
    "Category": "Date and Time",
    "Description": "Serif clock with moon-phase glyph",
    "Icon": "clock",
    "Id": "com.utku.journalclock",
    "License": "MIT",
    "Name": "Journal Clock",
    "Version": "1.0"
  },
  "X-Plasma-API-Minimum-Version": "6.0"
}
```

- [ ] **Step 2: Write `config/main.xml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journalclock/contents/config/main.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.kde.org/standards/kcfg/1.0
                          http://www.kde.org/standards/kcfg/1.0/kcfg.xsd">
  <kcfgfile name="journalclockrc"/>
  <group name="General">
    <entry name="use24h" type="Bool">
      <default>true</default>
    </entry>
    <entry name="showSeconds" type="Bool">
      <default>false</default>
    </entry>
    <entry name="locale" type="String">
      <default></default>
    </entry>
  </group>
</kcfg>
```

- [ ] **Step 3: Write `config/config.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journalclock/contents/config/config.qml`:
```qml
import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory { name: "General"; icon: "preferences-desktop"; source: "configGeneral.qml" }
}
```

- [ ] **Step 4: Write `ui/configGeneral.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journalclock/contents/ui/configGeneral.qml`:
```qml
import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_use24h:      use24hBox.checked
    property alias cfg_showSeconds: secondsBox.checked
    property alias cfg_locale:      localeField.text

    CheckBox {
        id: use24hBox
        Kirigami.FormData.label: "24-hour clock:"
    }
    CheckBox {
        id: secondsBox
        Kirigami.FormData.label: "Show seconds:"
    }
    TextField {
        id: localeField
        Kirigami.FormData.label: "Locale (empty = system):"
        placeholderText: "e.g. en-GB, tr-TR"
    }
}
```

- [ ] **Step 5: Write `ui/main.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journalclock/contents/ui/main.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "shared" as Shared

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property bool use24h:      Plasmoid.configuration.use24h
    property bool showSeconds: Plasmoid.configuration.showSeconds
    property string localeTag: Plasmoid.configuration.locale

    property string currentTime: ""
    property string currentSeconds: ""
    property string dayName: ""
    property string dateOrdinalHtml: ""

    function ordinal(n) {
        const s = ["th","st","nd","rd"]
        const v = n % 100
        return n + (s[(v-20)%10] || s[v] || s[0])
    }

    function pad(n) { return n.toString().padStart(2,"0") }

    function update() {
        const d = new Date()
        let hours = d.getHours()
        const suffix = use24h ? "" : (hours < 12 ? " a.m." : " p.m.")
        if (!use24h) { hours = hours % 12; if (hours === 0) hours = 12 }
        currentTime = pad(hours) + "·" + pad(d.getMinutes()) + suffix
        currentSeconds = showSeconds ? (":" + pad(d.getSeconds())) : ""

        const names = localeTag ? new Intl.DateTimeFormat(localeTag, { weekday: "long" })
                                : new Intl.DateTimeFormat(undefined, { weekday: "long" })
        dayName = names.format(d)
        const month = (localeTag ? new Intl.DateTimeFormat(localeTag, { month: "long" })
                                 : new Intl.DateTimeFormat(undefined, { month: "long" })).format(d)
        const ord = ordinal(d.getDate())
        const ordBody = ord.replace(/^\d+/, "")
        const ordNum = ord.replace(/[a-z]+$/i, "")
        dateOrdinalHtml = "the " + ordNum + "<sup style='font-size:0.7em'>" + ordBody + "</sup> of " + month
    }

    Timer {
        interval: showSeconds ? 1000 : 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.update()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 300
        Layout.preferredHeight: 110
        Layout.minimumWidth: 220
        Layout.minimumHeight: 90

        Shared.ParchmentBackground { anchors.fill: parent }
        Loader { sourceComponent: Shared.Ornaments.PageCorner; anchors.top: parent.top; anchors.right: parent.right }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Shared.MoonPhase {
                size: 32
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: root.currentTime
                color: Shared.Palette.inkDark
                font.family: Shared.Palette.fontSerif
                font.pixelSize: 56
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                visible: root.showSeconds
                text: root.currentSeconds
                color: Shared.Palette.inkMedium
                font.family: Shared.Palette.fontSerif
                font.pixelSize: 22
                verticalAlignment: Text.AlignBottom
                topPadding: 18
            }

            Item { Layout.fillWidth: true }

            ColumnLayout {
                spacing: 0
                Text {
                    text: root.dayName
                    color: Shared.Palette.inkMedium
                    font.family: Shared.Palette.fontAccent
                    font.pixelSize: 14
                }
                Text {
                    text: root.dateOrdinalHtml
                    textFormat: Text.RichText
                    color: Shared.Palette.inkDark
                    font.family: Shared.Palette.fontSerif
                    font.italic: true
                    font.pixelSize: 14
                }
            }
        }
    }
}
```

- [ ] **Step 6: Validate metadata + XML**

```bash
cd /mnt/hangar/projects/kdeshboard
jq -e . plasmoids/com.utku.journalclock/metadata.json >/dev/null && \
xmllint --noout plasmoids/com.utku.journalclock/contents/config/main.xml && echo OK
```
Expected: `OK`.

- [ ] **Step 7: qmllint**

```bash
cd /mnt/hangar/projects/kdeshboard
$QMLLINT plasmoids/com.utku.journalclock/contents/ui/main.qml \
         plasmoids/com.utku.journalclock/contents/ui/configGeneral.qml \
         plasmoids/com.utku.journalclock/contents/config/config.qml
```
Expected: exit 0.

- [ ] **Step 8: Remove .gitkeep markers and commit**

```bash
cd /mnt/hangar/projects/kdeshboard
rm plasmoids/com.utku.journalclock/contents/ui/.gitkeep \
   plasmoids/com.utku.journalclock/contents/config/.gitkeep
git add plasmoids/com.utku.journalclock
git commit -m "feat(clock): add Journal Clock plasmoid

Cormorant Garamond SemiBold 56px time with '·' colon, hairline seconds
tail when enabled. MoonPhase glyph on the left, day-of-week + ordinal
date-and-month on the right. Intl.DateTimeFormat for locale-aware day/
month names."
```

---

## Task 12: Plasmoid — Journal Weather

**Files:**
- Create: `plasmoids/com.utku.journalweather/metadata.json`
- Create: `plasmoids/com.utku.journalweather/contents/ui/main.qml`
- Create: `plasmoids/com.utku.journalweather/contents/ui/configGeneral.qml`
- Create: `plasmoids/com.utku.journalweather/contents/config/config.qml`
- Create: `plasmoids/com.utku.journalweather/contents/config/main.xml`

- [ ] **Step 1: Write `metadata.json`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journalweather/metadata.json`:
```json
{
  "KPackageStructure": "Plasma/Applet",
  "KPlugin": {
    "Authors": [{ "Name": "Utku" }],
    "Category": "System Information",
    "Description": "Weather as a diary forecast, from OpenMeteo",
    "Icon": "weather-few-clouds",
    "Id": "com.utku.journalweather",
    "License": "MIT",
    "Name": "Journal Weather",
    "Version": "1.0"
  },
  "X-Plasma-API-Minimum-Version": "6.0"
}
```

- [ ] **Step 2: Write `config/main.xml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journalweather/contents/config/main.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.kde.org/standards/kcfg/1.0
                          http://www.kde.org/standards/kcfg/1.0/kcfg.xsd">
  <kcfgfile name="journalweatherrc"/>
  <group name="General">
    <entry name="cityName" type="String">
      <default>Istanbul</default>
    </entry>
    <entry name="refreshMinutes" type="Int">
      <default>30</default>
    </entry>
    <entry name="units" type="String">
      <default>metric</default>
    </entry>
  </group>
</kcfg>
```

- [ ] **Step 3: Write `config/config.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journalweather/contents/config/config.qml`:
```qml
import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory { name: "General"; icon: "preferences-desktop"; source: "configGeneral.qml" }
}
```

- [ ] **Step 4: Write `ui/configGeneral.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journalweather/contents/ui/configGeneral.qml`:
```qml
import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_cityName:       cityField.text
    property alias cfg_refreshMinutes: refreshSpin.value
    property alias cfg_units:          unitsField.text

    TextField {
        id: cityField
        Kirigami.FormData.label: "City:"
        placeholderText: "Istanbul"
    }
    SpinBox {
        id: refreshSpin
        Kirigami.FormData.label: "Refresh (minutes):"
        from: 5
        to: 240
    }
    TextField {
        id: unitsField
        Kirigami.FormData.label: "Units:"
        placeholderText: "metric or imperial"
    }
}
```

- [ ] **Step 5: Write `ui/main.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journalweather/contents/ui/main.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "shared" as Shared

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property string cityName:    Plasmoid.configuration.cityName
    property int    refreshMinutes: Plasmoid.configuration.refreshMinutes
    property string units:       Plasmoid.configuration.units

    property real   lat: 0
    property real   lon: 0
    property bool   havePosition: false
    property string line1: ""
    property string line2: ""
    property string line3: ""
    property bool   silent: false

    readonly property var windCompass: [
        "from the north","from the north-northeast","from the northeast","from the east-northeast",
        "from the east","from the east-southeast","from the southeast","from the south-southeast",
        "from the south","from the south-southwest","from the southwest","from the west-southwest",
        "from the west","from the west-northwest","from the northwest","from the north-northwest"
    ]

    readonly property var wmoCodes: ({
        0: "clear", 1: "mostly clear", 2: "a little cloud", 3: "overcast",
        45: "foggy", 48: "foggy",
        51: "a drizzle", 53: "a drizzle", 55: "a drizzle",
        56: "freezing drizzle", 57: "freezing drizzle",
        61: "rain", 63: "rain", 65: "rain",
        66: "freezing rain", 67: "freezing rain",
        71: "snow", 73: "snow", 75: "snow",
        77: "snow grains",
        80: "showers", 81: "showers", 82: "showers",
        85: "snow showers", 86: "snow showers",
        95: "a thunderstorm", 96: "a thunderstorm with hail", 99: "a thunderstorm with hail"
    })

    function windProse(speed, dirDeg) {
        const compass = windCompass[Math.round(((dirDeg % 360) / 22.5)) % 16]
        let adj
        if (speed < 2) adj = "still, no wind to speak of"
        else if (speed < 8) adj = "a gentle wind " + compass
        else if (speed < 15) adj = "a steady wind " + compass
        else if (speed < 25) adj = "a stiff wind " + compass
        else if (speed < 40) adj = "a hard wind " + compass
        else adj = "a gale " + compass
        return adj
    }

    function precipProse(p) {
        if (p == null) return "no rain in hand"
        if (p < 10) return "no rain in hand"
        if (p < 30) return "a slim chance of rain"
        if (p < 60) return "rain likely"
        return "rain in earnest"
    }

    function weatherProse(code) { return wmoCodes[code] || "weather unclear" }

    function unitSuffix() { return units === "imperial" ? "°F" : "°C" }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            const stdout = data["stdout"] || ""
            const exit = data["exit code"]
            if (sourceName.startsWith("GEOCODE:")) {
                try {
                    const body = stdout.slice(stdout.indexOf("{"))
                    const json = JSON.parse(body)
                    if (json.results && json.results.length > 0) {
                        root.lat = json.results[0].latitude
                        root.lon = json.results[0].longitude
                        root.havePosition = true
                        fetchForecast()
                    } else {
                        setSilent()
                    }
                } catch (e) { console.warn("geocoding parse:", e); setSilent() }
            } else if (sourceName.startsWith("FORECAST:")) {
                try {
                    const body = stdout.slice(stdout.indexOf("{"))
                    const json = JSON.parse(body)
                    const cur = json.current
                    const daily = json.daily
                    const tempUnit = unitSuffix()
                    const curLine = Math.round(cur.temperature_2m) + tempUnit + ", "
                                  + weatherProse(cur.weather_code) + ", "
                                  + windProse(cur.wind_speed_10m, cur.wind_direction_10m) + "."
                    const dayNames = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
                    const now = new Date()
                    const tomorrowIdx = 1, dayAfterIdx = 2
                    const tHi = Math.round(daily.temperature_2m_max[tomorrowIdx])
                    const tCode = daily.weather_code[tomorrowIdx]
                    const tPrecip = daily.precipitation_probability_max[tomorrowIdx]
                    const dHi = Math.round(daily.temperature_2m_max[dayAfterIdx])
                    const dCode = daily.weather_code[dayAfterIdx]
                    const dPrecip = daily.precipitation_probability_max[dayAfterIdx]
                    const dayAfter = new Date(now.getTime() + 2 * 86400000)
                    root.line1 = curLine
                    root.line2 = "Tomorrow — " + weatherProse(tCode) + ", high " + tHi + tempUnit
                               + ", " + precipProse(tPrecip) + "."
                    root.line3 = dayNames[dayAfter.getDay()] + " — " + weatherProse(dCode)
                               + ", high " + dHi + tempUnit + ", " + precipProse(dPrecip) + "."
                    root.silent = false
                } catch (e) { console.warn("forecast parse:", e); setSilent() }
            }
            disconnectSource(sourceName)
        }
        function exec(cmd) { if (cmd) connectSource(cmd) }
    }

    function setSilent() {
        silent = true
        line1 = "— the almanac is silent. —"
        line2 = ""
        line3 = ""
    }

    function fetchGeocode() {
        const url = "https://geocoding-api.open-meteo.com/v1/search?count=1&name="
                    + encodeURIComponent(cityName)
        executable.exec("GEOCODE: curl -sS --max-time 10 " + shellQuote(url))
    }

    function fetchForecast() {
        if (!havePosition) return
        const u = units === "imperial" ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : ""
        const url = "https://api.open-meteo.com/v1/forecast"
                  + "?latitude=" + lat + "&longitude=" + lon
                  + "&current=temperature_2m,weather_code,wind_speed_10m,wind_direction_10m"
                  + "&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max"
                  + "&timezone=auto&forecast_days=3" + u
        executable.exec("FORECAST: curl -sS --max-time 10 " + shellQuote(url))
    }

    function shellQuote(s) { return "'" + s.replace(/'/g, "'\\''") + "'" }

    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        property int elapsedMin: 9999
        onTriggered: {
            if (!havePosition) { fetchGeocode(); return }
            if (elapsedMin >= root.refreshMinutes) {
                elapsedMin = 0
                fetchForecast()
            } else {
                elapsedMin += 1
            }
        }
    }

    onCityNameChanged: {
        havePosition = false
        line1 = line2 = line3 = ""
        fetchGeocode()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 400
        Layout.preferredHeight: 140
        Layout.minimumWidth: 280
        Layout.minimumHeight: 100

        Shared.ParchmentBackground { anchors.fill: parent }
        Loader { sourceComponent: Shared.Ornaments.PageCorner; anchors.top: parent.top; anchors.right: parent.right }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 2

            Text {
                text: root.cityName
                color: Shared.Palette.burgundy
                font.family: Shared.Palette.fontSmallCaps
                font.pixelSize: 12
                font.letterSpacing: 1.6
            }
            Loader { sourceComponent: Shared.Ornaments.DoubleRule; Layout.fillWidth: true; Layout.topMargin: 2 }

            Text {
                text: root.line1
                color: root.silent ? Shared.Palette.inkMedium : Shared.Palette.inkDark
                font.family: Shared.Palette.fontAccent
                font.pixelSize: 16
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.topMargin: 4
            }
            Text {
                visible: !root.silent && root.line2.length > 0
                text: root.line2
                color: Shared.Palette.inkMedium
                font.family: Shared.Palette.fontAccent
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Text {
                visible: !root.silent && root.line3.length > 0
                text: root.line3
                color: Shared.Palette.inkMedium
                font.family: Shared.Palette.fontAccent
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
```

- [ ] **Step 6: Validate metadata + XML**

```bash
cd /mnt/hangar/projects/kdeshboard
jq -e . plasmoids/com.utku.journalweather/metadata.json >/dev/null && \
xmllint --noout plasmoids/com.utku.journalweather/contents/config/main.xml && echo OK
```
Expected: `OK`.

- [ ] **Step 7: qmllint**

```bash
cd /mnt/hangar/projects/kdeshboard
$QMLLINT plasmoids/com.utku.journalweather/contents/ui/main.qml \
         plasmoids/com.utku.journalweather/contents/ui/configGeneral.qml \
         plasmoids/com.utku.journalweather/contents/config/config.qml
```
Expected: exit 0.

- [ ] **Step 8: Remove .gitkeep markers and commit**

```bash
cd /mnt/hangar/projects/kdeshboard
rm plasmoids/com.utku.journalweather/contents/ui/.gitkeep \
   plasmoids/com.utku.journalweather/contents/config/.gitkeep
git add plasmoids/com.utku.journalweather
git commit -m "feat(weather): add Journal Weather plasmoid

OpenMeteo (no API key): geocoding → forecast. Three Caveat lines of
journal prose. WMO code → phrase table (clear / overcast / drizzle /
rain / showers / …); 16-point compass; speed bucket → adjective;
precip probability → English. Silent-almanac sad path on any failure."
```

---

## Task 13: Plasmoid — Journal NowPlaying

**Files:**
- Create: `plasmoids/com.utku.journalnowplaying/metadata.json`
- Create: `plasmoids/com.utku.journalnowplaying/contents/ui/main.qml`
- Create: `plasmoids/com.utku.journalnowplaying/contents/ui/configGeneral.qml`
- Create: `plasmoids/com.utku.journalnowplaying/contents/config/config.qml`
- Create: `plasmoids/com.utku.journalnowplaying/contents/config/main.xml`

- [ ] **Step 1: Write `metadata.json`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journalnowplaying/metadata.json`:
```json
{
  "KPackageStructure": "Plasma/Applet",
  "KPlugin": {
    "Authors": [{ "Name": "Utku" }],
    "Category": "Multimedia",
    "Description": "Now playing, as a gramophone entry",
    "Icon": "media-playback-start",
    "Id": "com.utku.journalnowplaying",
    "License": "MIT",
    "Name": "Journal NowPlaying",
    "Version": "1.0"
  },
  "X-Plasma-API-Minimum-Version": "6.0"
}
```

- [ ] **Step 2: Write `config/main.xml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journalnowplaying/contents/config/main.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.kde.org/standards/kcfg/1.0
                          http://www.kde.org/standards/kcfg/1.0/kcfg.xsd">
  <kcfgfile name="journalnowplayingrc"/>
  <group name="General">
    <entry name="preferredPlayer" type="String">
      <default></default>
    </entry>
    <entry name="showAlbumArt" type="Bool">
      <default>false</default>
    </entry>
  </group>
</kcfg>
```

- [ ] **Step 3: Write `config/config.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journalnowplaying/contents/config/config.qml`:
```qml
import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory { name: "General"; icon: "preferences-desktop"; source: "configGeneral.qml" }
}
```

- [ ] **Step 4: Write `ui/configGeneral.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journalnowplaying/contents/ui/configGeneral.qml`:
```qml
import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_preferredPlayer: playerField.text
    property alias cfg_showAlbumArt:    artBox.checked

    TextField {
        id: playerField
        Kirigami.FormData.label: "Preferred player:"
        placeholderText: "e.g. spotify; empty = auto"
    }
    CheckBox {
        id: artBox
        Kirigami.FormData.label: "Show album art:"
    }
}
```

- [ ] **Step 5: Write `ui/main.qml`**

Create `/mnt/hangar/projects/kdeshboard/plasmoids/com.utku.journalnowplaying/contents/ui/main.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "shared" as Shared

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property string preferredPlayer: Plasmoid.configuration.preferredPlayer
    property string currentPlayer: ""       // full dbus service name
    property string title: ""
    property string artist: ""
    property string album: ""
    property string status: "Stopped"       // Playing / Paused / Stopped
    property real   position: 0             // microseconds
    property real   length: 1               // microseconds, >0 to avoid div/0

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            const stdout = (data["stdout"] || "").trim()
            if (sourceName === "LIST") {
                const services = stdout.split("\n").filter(s => s.startsWith("org.mpris.MediaPlayer2."))
                if (preferredPlayer) {
                    const match = services.find(s => s.toLowerCase().endsWith("." + preferredPlayer.toLowerCase()))
                    currentPlayer = match || (services[0] || "")
                } else {
                    currentPlayer = services[0] || ""
                }
                if (currentPlayer) queryMetadata()
                else resetEmpty()
            } else if (sourceName.startsWith("META:")) {
                parseMetadata(stdout)
            } else if (sourceName.startsWith("STATUS:")) {
                const m = stdout.match(/Playing|Paused|Stopped/)
                status = m ? m[0] : "Stopped"
            } else if (sourceName.startsWith("POSITION:")) {
                const n = parseInt(stdout, 10)
                if (!isNaN(n)) position = n
            }
            disconnectSource(sourceName)
        }
        function exec(cmd) { if (cmd) connectSource(cmd) }
    }

    function resetEmpty() {
        title = ""; artist = ""; album = ""; status = "Stopped"; position = 0; length = 1
    }

    function parseMetadata(raw) {
        // qdbus prints each dict entry on its own line: "key: value"
        // xesam:title, xesam:artist (array), xesam:album, mpris:length
        const lines = raw.split("\n")
        let t = "", a = "", al = "", len = 1
        for (const line of lines) {
            const m = line.match(/^\s*([^:]+):\s*(.+)$/)
            if (!m) continue
            const k = m[1].trim().toLowerCase()
            const v = m[2].trim()
            if (k.endsWith("xesam:title")) t = v
            else if (k.endsWith("xesam:artist")) a = v.replace(/^\[|\]$/g, "")
            else if (k.endsWith("xesam:album")) al = v
            else if (k.endsWith("mpris:length")) {
                const n = parseInt(v, 10); if (!isNaN(n) && n > 0) len = n
            }
        }
        title = t; artist = a; album = al; length = len
    }

    function queryList() {
        executable.exec("LIST: qdbus 2>/dev/null | grep ^org.mpris.MediaPlayer2")
    }
    function queryMetadata() {
        if (!currentPlayer) return
        executable.exec("META: qdbus " + currentPlayer + " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata")
        executable.exec("STATUS: qdbus " + currentPlayer + " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlaybackStatus")
        executable.exec("POSITION: qdbus " + currentPlayer + " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Position")
    }
    function control(method) {
        if (!currentPlayer) return
        executable.exec("qdbus " + currentPlayer + " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player." + method)
    }

    Timer {
        interval: root.status === "Playing" ? 1000 : 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: currentPlayer ? queryMetadata() : queryList()
    }

    fullRepresentation: Item {
        id: frame
        Layout.preferredWidth: 360
        Layout.preferredHeight: 100
        Layout.minimumWidth: 260
        Layout.minimumHeight: 80
        opacity: root.title === "" ? 0.7 : 1.0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Shared.ParchmentBackground { anchors.fill: parent }
        Loader { sourceComponent: Shared.Ornaments.PageCorner; anchors.top: parent.top; anchors.right: parent.right }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            anchors.bottomMargin: 8
            spacing: 0

            Text {
                text: root.title || "— no song in the air —"
                color: Shared.Palette.wax
                font.family: root.title ? Shared.Palette.fontDisplay : Shared.Palette.fontAccent
                font.pixelSize: root.title ? 22 : 14
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                visible: root.title.length > 0
                text: root.artist
                color: Shared.Palette.inkMedium
                font.family: Shared.Palette.fontAccent
                font.pixelSize: 14
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                visible: root.title.length > 0 && root.album.length > 0
                text: root.album
                color: Shared.Palette.inkMedium
                font.family: Shared.Palette.fontAccent
                font.pixelSize: 12
                font.italic: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Item { Layout.fillHeight: true }
        }

        // Progress rule — gilt baseline + inkWet leading edge
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            height: 2
            color: Shared.Palette.gilt
            opacity: 0.6
        }
        Rectangle {
            id: progressFill
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.bottomMargin: 10
            anchors.leftMargin: 10
            height: 2
            width: root.length > 0 ? (parent.width - 20) * (root.position / root.length) : 0
            color: Shared.Palette.wax
            Rectangle {
                anchors.right: parent.right
                width: 1
                height: 2
                color: Shared.Palette.inkWet
                SequentialAnimation on width {
                    running: root.status === "Playing"
                    loops: Animation.Infinite
                    NumberAnimation { from: 0; to: 1; duration: 1500; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1; to: 0; duration: 1500; easing.type: Easing.InOutSine }
                }
            }
        }

        // Hover area — reveals controls
        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
        Row {
            id: controls
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.bottomMargin: 14
            anchors.rightMargin: 14
            spacing: 10
            opacity: hoverArea.containsMouse ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Repeater {
                model: [
                    { label: "◁◁", method: "Previous" },
                    { label: "❙❙", method: "PlayPause" },
                    { label: "▷▷", method: "Next" }
                ]
                Text {
                    text: modelData.label
                    color: controlMouse.containsMouse ? Shared.Palette.burgundy : Shared.Palette.wax
                    font.family: Shared.Palette.fontSerif
                    font.pixelSize: 14
                    MouseArea {
                        id: controlMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.control(modelData.method)
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 6: Validate metadata + XML**

```bash
cd /mnt/hangar/projects/kdeshboard
jq -e . plasmoids/com.utku.journalnowplaying/metadata.json >/dev/null && \
xmllint --noout plasmoids/com.utku.journalnowplaying/contents/config/main.xml && echo OK
```
Expected: `OK`.

- [ ] **Step 7: qmllint**

```bash
cd /mnt/hangar/projects/kdeshboard
$QMLLINT plasmoids/com.utku.journalnowplaying/contents/ui/main.qml \
         plasmoids/com.utku.journalnowplaying/contents/ui/configGeneral.qml \
         plasmoids/com.utku.journalnowplaying/contents/config/config.qml
```
Expected: exit 0.

- [ ] **Step 8: Remove .gitkeep markers and commit**

```bash
cd /mnt/hangar/projects/kdeshboard
rm plasmoids/com.utku.journalnowplaying/contents/ui/.gitkeep \
   plasmoids/com.utku.journalnowplaying/contents/config/.gitkeep
git add plasmoids/com.utku.journalnowplaying
git commit -m "feat(nowplaying): add Journal NowPlaying plasmoid

MPRIS via qdbus. Title in Parisienne (wax), artist/album in Caveat.
Gilt progress rule with inkWet leading glow (3s cycle) when playing.
Hover reveals ◁◁ ❙❙ ▷▷ controls bottom-right. Empty state dims the
widget to 0.7 opacity with '— no song in the air —'."
```

---

## Task 14: `install.sh`

**Files:** Create `install.sh`.

- [ ] **Step 1: Write the install script**

Create `/mnt/hangar/projects/kdeshboard/install.sh`:
```bash
#!/usr/bin/env bash
# Luxury Journal installer — color scheme, fonts, plasmoids.
# Idempotent: safe to re-run. Use --dry-run to preview.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONT_DIR="$HOME/.local/share/fonts/luxury-journal"
COLOR_DIR="$HOME/.local/share/color-schemes"

DRY_RUN=0
NO_FONTS=0
FORCE=0

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  --dry-run     Print actions without executing them
  --no-fonts    Skip font downloads (use existing installs)
  --force       Overwrite color scheme even if it differs from the repo copy
  -h, --help    Show this help
EOF
}

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --no-fonts) NO_FONTS=1 ;;
        --force)   FORCE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $arg" >&2; usage >&2; exit 2 ;;
    esac
done

say()  { echo "→ $*"; }
warn() { echo "⚠ $*" >&2; }
die()  { echo "✖ $*" >&2; exit 1; }
do_or_echo() {
    if (( DRY_RUN )); then
        echo "  would: $*"
    else
        eval "$@"
    fi
}

# ---- Preflight -------------------------------------------------------------
preflight() {
    say "Preflight checks"
    command -v plasmashell >/dev/null || die "plasmashell not found — is this Plasma 6?"
    local ver
    ver=$(plasmashell --version 2>/dev/null | awk '{print $2}')
    [[ "$ver" =~ ^6\. ]] || die "Plasma 6.x required, found: $ver"
    for bin in kpackagetool6 fc-cache curl awk stat rsync sha256sum; do
        command -v "$bin" >/dev/null || die "missing binary: $bin"
    done
    mkdir -p "$FONT_DIR" "$COLOR_DIR" || die "cannot create target dirs"
}

# ---- Fonts -----------------------------------------------------------------
declare -A FONT_URLS=(
    [Parisienne-Regular.ttf]="https://github.com/google/fonts/raw/main/ofl/parisienne/Parisienne-Regular.ttf"
    [Caveat.ttf]="https://github.com/google/fonts/raw/main/ofl/caveat/Caveat%5Bwght%5D.ttf"
    [CormorantGaramond-Light.ttf]="https://github.com/google/fonts/raw/main/ofl/cormorantgaramond/CormorantGaramond-Light.ttf"
    [CormorantGaramond-Regular.ttf]="https://github.com/google/fonts/raw/main/ofl/cormorantgaramond/CormorantGaramond-Regular.ttf"
    [CormorantGaramond-Medium.ttf]="https://github.com/google/fonts/raw/main/ofl/cormorantgaramond/CormorantGaramond-Medium.ttf"
    [CormorantGaramond-SemiBold.ttf]="https://github.com/google/fonts/raw/main/ofl/cormorantgaramond/CormorantGaramond-SemiBold.ttf"
    [CormorantSC-Medium.ttf]="https://github.com/google/fonts/raw/main/ofl/cormorantsc/CormorantSC-Medium.ttf"
    [IMFellDWPica-Regular.ttf]="https://github.com/google/fonts/raw/main/ofl/imfelldwpica/IMFellDWPica-Regular.ttf"
    [JetBrainsMono-Regular.ttf]="https://github.com/JetBrains/JetBrainsMono/raw/master/fonts/ttf/JetBrainsMono-Regular.ttf"
)

install_fonts() {
    (( NO_FONTS )) && { say "Fonts: skipped (--no-fonts)"; return; }
    say "Fonts → $FONT_DIR"
    local name url out
    local any_changed=0
    for name in "${!FONT_URLS[@]}"; do
        url="${FONT_URLS[$name]}"
        out="$FONT_DIR/$name"
        if [[ -f "$out" ]]; then
            echo "  · $name (present)"
            continue
        fi
        echo "  · $name ← downloading"
        do_or_echo curl -sSL --fail --max-time 60 "'$url'" -o "'$out'" \
            || { warn "download failed for $name"; any_changed=1; continue; }
        any_changed=1
    done
    if (( any_changed )); then
        do_or_echo fc-cache -f "'$FONT_DIR'" ">/dev/null"
    fi
}

# ---- Color scheme ----------------------------------------------------------
install_color_scheme() {
    say "Color scheme → $COLOR_DIR"
    local src="$REPO_DIR/luxury-journal.colors"
    local dst="$COLOR_DIR/luxury-journal.colors"
    [[ -f "$src" ]] || die "missing $src"
    if [[ -f "$dst" ]] && ! (( FORCE )); then
        local sh_src sh_dst
        sh_src=$(sha256sum "$src" | awk '{print $1}')
        sh_dst=$(sha256sum "$dst" | awk '{print $1}')
        if [[ "$sh_src" == "$sh_dst" ]]; then
            echo "  · luxury-journal.colors (unchanged)"
            return
        else
            warn "installed color scheme differs from repo; use --force to overwrite"
            return
        fi
    fi
    do_or_echo cp "'$src'" "'$dst'"
}

# ---- Shared QML ------------------------------------------------------------
copy_shared_qml() {
    say "Copying shared QML into each plasmoid"
    local dir
    for dir in "$REPO_DIR"/plasmoids/*/; do
        do_or_echo rsync -a --delete "'$REPO_DIR/shared/qml/'" "'$dir/contents/ui/shared/'"
    done
}

# ---- Plasmoids -------------------------------------------------------------
install_plasmoids() {
    say "Plasmoids"
    local dir id
    local installed
    installed=$(kpackagetool6 -t Plasma/Applet --list 2>/dev/null || true)
    for dir in "$REPO_DIR"/plasmoids/*/; do
        id=$(basename "$dir")
        if echo "$installed" | grep -q "^$id$"; then
            echo "  · $id (upgrade)"
            do_or_echo kpackagetool6 -t Plasma/Applet --upgrade "'$dir'"
        else
            echo "  · $id (install)"
            do_or_echo kpackagetool6 -t Plasma/Applet --install "'$dir'"
        fi
    done
}

# ---- Post-install summary --------------------------------------------------
summary() {
    cat <<EOF

Installed. Next steps:

  1. System Settings → Colors & Themes → Colors → pick "Luxury Journal".
  2. Right-click desktop → Add or Manage Widgets, add any of:
       Luxury Greeting · Tmux Tail · Journal Tasks ·
       Journal Clock · Journal Weather · Journal NowPlaying.
     Configure each via the wrench icon.
  3. (optional) System Settings → Fonts → General "Caveat",
     Fixed Width "JetBrains Mono".

Iterate on a plasmoid without a Plasma restart:
    ./dev.sh preview tmuxtail
EOF
}

main() {
    preflight
    install_fonts
    install_color_scheme
    copy_shared_qml
    install_plasmoids
    summary
}

main "$@"
```

- [ ] **Step 2: Make it executable**

```bash
cd /mnt/hangar/projects/kdeshboard
chmod +x install.sh
```

- [ ] **Step 3: shellcheck**

```bash
cd /mnt/hangar/projects/kdeshboard
shellcheck install.sh
```
Expected: exit 0, no output. If shellcheck objects to `do_or_echo`'s `eval`, read the SC code carefully — the script deliberately uses `eval` so `do_or_echo` expansion can handle the quoted paths. Silence the specific finding with `# shellcheck disable=SC2294` on the `eval` line if needed.

- [ ] **Step 4: Dry-run smoke test**

```bash
cd /mnt/hangar/projects/kdeshboard
./install.sh --dry-run 2>&1 | head -40 || true
```
Expected: preflight runs, prints "would: …" lines for fonts / color scheme / plasmoids (or `(present)` / `(unchanged)` lines), exits 0 or errors on the preflight if Plasma 6 isn't installed in the sandbox.

Note: if `plasmashell` isn't in the sandbox, preflight fails — that's correct behavior for a machine without Plasma. The dry-run is validated on the user's machine. For a sandbox check, temporarily stub: `command -v plasmashell || { echo "(stubbing for sandbox)"; exit 0; }` on its own line; do **not** commit the stub.

- [ ] **Step 5: Commit**

```bash
cd /mnt/hangar/projects/kdeshboard
git add install.sh
git commit -m "feat: add hardened install.sh

Preflight (Plasma 6, required binaries, writable targets), idempotent
font install (download only if missing), color scheme copy guarded by
SHA-256 comparison + --force, rsync'd shared QML into each plasmoid,
kpackagetool6 install-or-upgrade. Flags: --dry-run --no-fonts --force."
```

---

## Task 15: `uninstall.sh`

**Files:** Create `uninstall.sh`.

- [ ] **Step 1: Write the uninstall script**

Create `/mnt/hangar/projects/kdeshboard/uninstall.sh`:
```bash
#!/usr/bin/env bash
# Luxury Journal uninstaller. Removes plasmoids + color scheme.
# --purge also removes fonts.
set -euo pipefail

FONT_DIR="$HOME/.local/share/fonts/luxury-journal"
COLOR_DIR="$HOME/.local/share/color-schemes"

PURGE=0
DRY_RUN=0

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  --purge       Also remove installed fonts
  --dry-run     Print actions without executing them
  -h, --help    Show this help
EOF
}

for arg in "$@"; do
    case "$arg" in
        --purge)   PURGE=1 ;;
        --dry-run) DRY_RUN=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $arg" >&2; usage >&2; exit 2 ;;
    esac
done

say() { echo "→ $*"; }
do_or_echo() {
    if (( DRY_RUN )); then
        echo "  would: $*"
    else
        eval "$@"
    fi
}

PLASMOIDS=(
    com.utku.luxurygreeting
    com.utku.tmuxtail
    com.utku.journaltasks
    com.utku.journalclock
    com.utku.journalweather
    com.utku.journalnowplaying
)

say "Removing plasmoids"
installed=$(kpackagetool6 -t Plasma/Applet --list 2>/dev/null || true)
for id in "${PLASMOIDS[@]}"; do
    if echo "$installed" | grep -q "^$id$"; then
        echo "  · $id"
        do_or_echo kpackagetool6 -t Plasma/Applet --remove "$id"
    else
        echo "  · $id (not installed)"
    fi
done

say "Removing color scheme"
dst="$COLOR_DIR/luxury-journal.colors"
if [[ -f "$dst" ]]; then
    do_or_echo rm -f "'$dst'"
else
    echo "  · already absent"
fi

if (( PURGE )); then
    say "Removing fonts (--purge)"
    if [[ -d "$FONT_DIR" ]]; then
        do_or_echo rm -rf "'$FONT_DIR'"
        do_or_echo fc-cache -f ">/dev/null"
    else
        echo "  · font directory already absent"
    fi
else
    say "Fonts kept (re-run with --purge to remove)"
fi

say "Done. Your selected color scheme may still be 'Luxury Journal' in kdeglobals;"
say "Plasma will fall back to Breeze when it fails to find the removed scheme."
```

- [ ] **Step 2: Make executable + shellcheck**

```bash
cd /mnt/hangar/projects/kdeshboard
chmod +x uninstall.sh
shellcheck uninstall.sh
```
Expected: exit 0.

- [ ] **Step 3: Commit**

```bash
git add uninstall.sh
git commit -m "feat: add uninstall.sh

Removes all six plasmoids (ignores 'not installed' errors), deletes
the color scheme file. --purge also removes fonts. --dry-run for
preview. Does not touch kdeglobals; Plasma falls back gracefully."
```

---

## Task 16: `dev.sh`

**Files:** Create `dev.sh`.

- [ ] **Step 1: Write the dev helper**

Create `/mnt/hangar/projects/kdeshboard/dev.sh`:
```bash
#!/usr/bin/env bash
# Luxury Journal dev helper.
# Usage: dev.sh preview <id>   Live-preview a plasmoid via plasmoidviewer
#        dev.sh reload  <id>   Copy shared QML and kpackagetool6 --upgrade
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<EOF
Usage: $0 <command> <plasmoid-id>

Commands:
  preview <id>   Run plasmoidviewer on the plasmoid (live-reloads on save)
  reload  <id>   Copy shared/qml/ into the plasmoid and kpackagetool6 --upgrade it

<id> may be the full name (com.utku.tmuxtail) or the short name (tmuxtail).
EOF
}

resolve_id() {
    local input="$1"
    if [[ -d "$REPO_DIR/plasmoids/$input" ]]; then echo "$input"; return; fi
    if [[ -d "$REPO_DIR/plasmoids/com.utku.$input" ]]; then echo "com.utku.$input"; return; fi
    echo "unknown plasmoid: $input" >&2
    echo "available:" >&2
    ls "$REPO_DIR/plasmoids/" >&2
    exit 2
}

sync_shared() {
    local dir="$1"
    rsync -a --delete "$REPO_DIR/shared/qml/" "$dir/contents/ui/shared/"
}

cmd="${1:-}"; shift || true
case "$cmd" in
    preview)
        [[ $# -eq 1 ]] || { usage; exit 2; }
        id=$(resolve_id "$1")
        dir="$REPO_DIR/plasmoids/$id"
        sync_shared "$dir"
        exec plasmoidviewer -a "$dir"
        ;;
    reload)
        [[ $# -eq 1 ]] || { usage; exit 2; }
        id=$(resolve_id "$1")
        dir="$REPO_DIR/plasmoids/$id"
        sync_shared "$dir"
        kpackagetool6 -t Plasma/Applet --upgrade "$dir"
        echo "reloaded: $id — right-click the widget → Refresh on the desktop"
        ;;
    -h|--help|"") usage ;;
    *) echo "unknown command: $cmd" >&2; usage >&2; exit 2 ;;
esac
```

- [ ] **Step 2: Make executable + shellcheck**

```bash
cd /mnt/hangar/projects/kdeshboard
chmod +x dev.sh
shellcheck dev.sh
```
Expected: exit 0.

- [ ] **Step 3: Commit**

```bash
git add dev.sh
git commit -m "feat: add dev.sh helper

preview: rsyncs shared QML and runs plasmoidviewer -a for live reload.
reload:  rsyncs shared QML and kpackagetool6 --upgrade for in-desktop
         iteration. Accepts full (com.utku.x) or short (x) names."
```

---

## Task 17: GitHub CI lint workflow

**Files:** Create `.github/workflows/lint.yml`.

- [ ] **Step 1: Write the workflow**

Create `/mnt/hangar/projects/kdeshboard/.github/workflows/lint.yml`:
```yaml
name: lint

on:
  push:
    branches: [main]
  pull_request:

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install tools
        run: |
          sudo apt-get update
          sudo apt-get install -y shellcheck libxml2-utils jq python3
          # qmllint-qt6 ships with qt6-declarative-dev on Ubuntu.
          sudo apt-get install -y qt6-declarative-dev || true

      - name: shellcheck
        run: shellcheck install.sh uninstall.sh dev.sh

      - name: metadata.json
        run: |
          set -e
          for f in plasmoids/*/metadata.json; do
            jq -e . "$f" > /dev/null
          done

      - name: main.xml
        run: xmllint --noout plasmoids/*/contents/config/main.xml

      - name: color scheme
        run: python3 tools/validate_colors.py luxury-journal.colors

      - name: qmllint (non-fatal in CI)
        continue-on-error: true
        run: |
          QMLLINT="$(command -v qmllint-qt6 || command -v qmllint6 || command -v qmllint || echo)"
          if [[ -n "$QMLLINT" ]]; then
            "$QMLLINT" plasmoids/*/contents/ui/*.qml shared/qml/*.qml
          else
            echo "qmllint not available on runner; skipped"
          fi
        shell: bash
```

- [ ] **Step 2: Validate YAML parses**

```bash
cd /mnt/hangar/projects/kdeshboard
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/lint.yml'))" 2>/dev/null \
    || python3 -c "import sys; open('.github/workflows/lint.yml').read(); print('YAML read ok (no pyyaml installed)')"
```
Expected: no exception thrown.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/lint.yml
git commit -m "ci: add lint workflow

shellcheck on all three scripts, jq validation of every metadata.json,
xmllint of every main.xml, python validator for the color scheme,
qmllint (non-fatal — some runners lack the Qt 6 qmllint binary)."
```

---

## Task 18: Issue + PR templates

**Files:**
- Create: `.github/ISSUE_TEMPLATE/bug.md`
- Create: `.github/ISSUE_TEMPLATE/feature.md`
- Create: `.github/PULL_REQUEST_TEMPLATE.md`

- [ ] **Step 1: Write bug template**

Create `/mnt/hangar/projects/kdeshboard/.github/ISSUE_TEMPLATE/bug.md`:
```markdown
---
name: Bug report
about: Something is broken
title: "bug: "
labels: bug
---

**What happened**

**What you expected**

**Reproduction**
1.
2.
3.

**Plasma version**
Output of `plasmashell --version`:

**journalctl output**
Paste the last 20 lines of
```
journalctl --user -f -t plasmashell
```
after reproducing the bug.

**Screenshot**
```

- [ ] **Step 2: Write feature template**

Create `/mnt/hangar/projects/kdeshboard/.github/ISSUE_TEMPLATE/feature.md`:
```markdown
---
name: Feature request
about: A new widget, ornament, or behavior
title: "feat: "
labels: enhancement
---

**User story**
As a <role> I want <capability> so that <outcome>.

**Aesthetic fit**
How does it serve the leather-bound-journal metaphor? What existing
ornaments or fonts would it reuse?

**Data source**
Where does the information come from? (local file, DBus, HTTP API, etc.)

**Alternatives considered**
```

- [ ] **Step 3: Write PR template**

Create `/mnt/hangar/projects/kdeshboard/.github/PULL_REQUEST_TEMPLATE.md`:
```markdown
## Summary

## Screenshots

## Checklist
- [ ] `shellcheck` clean
- [ ] `qmllint-qt6` clean (where available)
- [ ] `jq`, `xmllint`, `validate_colors.py` clean
- [ ] Ran in `plasmoidviewer` without errors
- [ ] `journalctl --user -t plasmashell` clean after `kpackagetool6 --upgrade`
```

- [ ] **Step 4: Commit**

```bash
cd /mnt/hangar/projects/kdeshboard
rm .github/ISSUE_TEMPLATE/.gitkeep .github/workflows/.gitkeep 2>/dev/null || true
git add .github/ISSUE_TEMPLATE .github/PULL_REQUEST_TEMPLATE.md
git commit -m "chore: add issue and PR templates

Bug template asks for plasmashell version + journalctl output. Feature
template asks for aesthetic fit. PR template checklist covers the five
linters and the two manual tests (plasmoidviewer + journalctl)."
```

---

## Task 19: README, ARCHITECTURE, CHANGELOG

**Files:**
- Rewrite: `README.md`
- Create: `docs/ARCHITECTURE.md`
- Update: `CHANGELOG.md`

- [ ] **Step 1: Rewrite `README.md`**

Replace the content of `/mnt/hangar/projects/kdeshboard/README.md` with:
```markdown
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
```

- [ ] **Step 2: Write `docs/ARCHITECTURE.md`**

Create `/mnt/hangar/projects/kdeshboard/docs/ARCHITECTURE.md`:
```markdown
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
```

- [ ] **Step 3: Update `CHANGELOG.md`**

Replace the content of `/mnt/hangar/projects/kdeshboard/CHANGELOG.md` with:
```markdown
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
```

- [ ] **Step 4: Commit**

```bash
cd /mnt/hangar/projects/kdeshboard
git add README.md docs/ARCHITECTURE.md CHANGELOG.md
git commit -m "docs: expand README + add ARCHITECTURE + finalize CHANGELOG

README: install/uninstall/dev, companion-widget list, troubleshooting
entries for each plasmoid's likely-failure mode, MIT license pointer.
ARCHITECTURE: the three-piece explanation (colors/fonts/plasmoids) and
the boundaries between them. CHANGELOG: 0.1.0 with the full inventory."
```

---

## Task 20: Tag and final state verification

**Files:** none — operates on git.

- [ ] **Step 1: Run the full linter pass end-to-end**

```bash
cd /mnt/hangar/projects/kdeshboard
shellcheck install.sh uninstall.sh dev.sh && \
for f in plasmoids/*/metadata.json; do jq -e . "$f" >/dev/null; done && \
xmllint --noout plasmoids/*/contents/config/main.xml && \
python3 tools/validate_colors.py luxury-journal.colors && \
echo ALL CLEAN
```
Expected: `ALL CLEAN`.

- [ ] **Step 2: Run qmllint across everything**

```bash
cd /mnt/hangar/projects/kdeshboard
QMLLINT=$(command -v qmllint-qt6 || command -v qmllint6 || command -v qmllint || echo "")
if [[ -n "$QMLLINT" ]]; then
    "$QMLLINT" plasmoids/*/contents/ui/*.qml shared/qml/*.qml
    echo "qmllint clean"
else
    echo "qmllint not available — manual review pass noted"
fi
```
Expected: either "qmllint clean" or the manual-review fallback message. Any actual QML syntax errors reported must be fixed and re-committed before tagging.

- [ ] **Step 3: Tag**

```bash
cd /mnt/hangar/projects/kdeshboard
git tag -a v0.1.0 -m "v0.1.0 — Luxury Journal

Initial release. Plasma 6 color scheme, nine fonts, six custom
plasmoids (greeting, tmux tail, tasks, clock, weather, nowplaying),
install/uninstall/dev scripts, lint CI."
git log --oneline
```
Expected: a short list ending with a tag annotation on HEAD.

- [ ] **Step 4: Final status check**

```bash
cd /mnt/hangar/projects/kdeshboard
git status
git tag --list
```
Expected: `nothing to commit, working tree clean` and `v0.1.0` in the tag list.

---

## Notes on executing this plan

- Each task ends in a commit with a conventional-commits prefix. Do not
  batch commits across tasks — they are the review granularity.
- qmllint's import-resolution warnings on Plasma / Kirigami modules are
  expected in-sandbox (these modules resolve at Plasma runtime, not during
  lint). Actual QML *syntax* errors must be fixed. If unsure, the
  distinguishing signal: import warnings include `not found` or
  `unknown import`; syntax errors include `expected` or `unexpected`.
- The QML code uses `import "shared" as Shared` which resolves after
  `install.sh` copies `shared/qml/*` into each plasmoid. For
  `dev.sh preview`, the same copy step runs first. For lint-in-sandbox,
  the import path may not resolve (there's no `shared/` subdir alongside
  the QML file under source control — only after the copy). That's fine
  — treat those specific import warnings as expected noise.
- If shellcheck flags `do_or_echo`'s `eval`, disable the specific SC code
  on the offending line rather than rewriting the mechanism; the
  pattern is deliberate to get correct quoting on paths with spaces
  under both dry-run and real-run.
