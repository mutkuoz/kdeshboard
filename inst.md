# Luxury Journal · Plasma-native dashboard

## Vision

Turn the KDE Plasma desktop into a leather-bound-journal dashboard: parchment wallpaper, oxblood accents, handwritten labels, classical serif numerals. All widgets are native Plasma plasmoids that inherit a custom color scheme, so the theme applies uniformly to built-in widgets, third-party plasmoids, and the custom ones we write.

Three pieces do the whole job:
1. **Color scheme** — one `.colors` file defines the palette system-wide.
2. **Fonts** — Parisienne / Caveat / Cormorant Garamond installed user-local.
3. **Custom plasmoids** — two QML widgets for the things that don't already exist: the greeting and the tmux log tail. Everything else comes from the KDE Store.

## Target environment

- Fedora, KDE Plasma 6.x (Wayland or X11).
- `plasma-sdk` package for `plasmoidviewer` during development (`sudo dnf install plasma-sdk`).
- Plasma 6 API: `PlasmoidItem` root, `Kirigami.Theme` for colors, `Plasma5Support.DataSource` with the `executable` engine for shell commands.

## Repository layout

```
luxury-journal/
├── install.sh
├── luxury-journal.colors
├── plasmoids/
│   ├── com.utku.luxurygreeting/
│   │   ├── metadata.json
│   │   └── contents/
│   │       ├── ui/
│   │       │   ├── main.qml
│   │       │   └── configGeneral.qml
│   │       └── config/
│   │           ├── config.qml
│   │           └── main.xml
│   └── com.utku.tmuxtail/
│       ├── metadata.json
│       └── contents/
│           ├── ui/
│           │   ├── main.qml
│           │   └── configGeneral.qml
│           └── config/
│               ├── config.qml
│               └── main.xml
└── README.md
```

## Palette

CSS-style values for reference. The actual Plasma colors file uses `R,G,B` triplets — see the file content below.

| role | hex | usage |
|---|---|---|
| parchment outer | `#ece0c8` | `Window.BackgroundNormal` |
| parchment panel | `#f2e8d3` | `Window.BackgroundAlternate`, `View.BackgroundAlternate` |
| ink dark | `#2d1810` | `ForegroundNormal` |
| ink medium | `#6b4e36` | `ForegroundInactive` |
| burgundy | `#722529` | `DecorationFocus/Hover`, `ForegroundActive/Link/Visited`, selections |
| gold | `#9e7b3a` | `ForegroundNeutral` (warnings) |
| green | `#4a6b3a` | `ForegroundPositive` |
| red-negative | `#9e3540` | `ForegroundNegative` |

## Files — drop in exactly as shown

### `luxury-journal.colors`

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

### Plasmoid 1: Luxury Greeting

#### `plasmoids/com.utku.luxurygreeting/metadata.json`

```json
{
  "KPackageStructure": "Plasma/Applet",
  "KPlugin": {
    "Authors": [{ "Name": "Utku" }],
    "Category": "Utilities",
    "Description": "Adaptive greeting in cursive with the day's date",
    "Icon": "preferences-desktop-notification",
    "Id": "com.utku.luxurygreeting",
    "License": "MIT",
    "Name": "Luxury Greeting",
    "Version": "1.0"
  },
  "X-Plasma-API-Minimum-Version": "6.0"
}
```

#### `plasmoids/com.utku.luxurygreeting/contents/ui/main.qml`

```qml
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property string userName: Plasmoid.configuration.userName
    property string currentGreeting: ""
    property string currentDate: ""
    property string currentPeriod: ""

    function updateGreeting() {
        const d = new Date()
        const h = d.getHours()

        if (h < 5)       currentGreeting = "Still up, " + userName + "?"
        else if (h < 12) currentGreeting = "Good morning, " + userName + "."
        else if (h < 17) currentGreeting = "Good afternoon, " + userName + "."
        else             currentGreeting = "Good evening, " + userName + "."

        if (h < 5)       currentPeriod = "in the small hours"
        else if (h < 12) currentPeriod = "in the morning"
        else if (h < 17) currentPeriod = "in the afternoon"
        else if (h < 21) currentPeriod = "in the evening"
        else             currentPeriod = "late at night"

        const days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
        const months = ["January","February","March","April","May","June",
                        "July","August","September","October","November","December"]
        const ordinal = n => {
            const s = ["th","st","nd","rd"]
            const v = n % 100
            return n + (s[(v-20)%10] || s[v] || s[0])
        }
        currentDate = days[d.getDay()] + ", the " + ordinal(d.getDate())
                    + " of " + months[d.getMonth()] + ", " + d.getFullYear()
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateGreeting()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 480
        Layout.preferredHeight: 100
        Layout.minimumWidth: 300

        ColumnLayout {
            anchors.fill: parent
            spacing: 4

            Text {
                text: root.currentGreeting
                font.family: "Parisienne"
                font.pixelSize: 44
                color: Kirigami.Theme.positiveTextColor === "" 
                       ? Kirigami.Theme.highlightColor
                       : "#722529"
                Layout.fillWidth: true
            }

            Text {
                text: root.currentDate + " · " + root.currentPeriod
                font.family: "Caveat"
                font.pixelSize: 16
                color: Kirigami.Theme.disabledTextColor
                Layout.fillWidth: true
            }
        }
    }
}
```

#### `plasmoids/com.utku.luxurygreeting/contents/config/config.qml`

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

#### `plasmoids/com.utku.luxurygreeting/contents/config/main.xml`

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
  </group>
</kcfg>
```

#### `plasmoids/com.utku.luxurygreeting/contents/ui/configGeneral.qml`

```qml
import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_userName: userNameField.text

    TextField {
        id: userNameField
        Kirigami.FormData.label: "Your name:"
    }
}
```

### Plasmoid 2: Tmux Tail

#### `plasmoids/com.utku.tmuxtail/metadata.json`

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

#### `plasmoids/com.utku.tmuxtail/contents/ui/main.qml`

```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property string tmuxTarget: Plasmoid.configuration.tmuxTarget
    property int    lineCount:  Plasmoid.configuration.lineCount
    property int    refreshMs:  Plasmoid.configuration.refreshMs
    property string attachCmd:  Plasmoid.configuration.attachCommand
    property string paneContent: ""
    property bool   sessionFound: true

    // Strip ANSI SGR escapes for v1. Color rendering is phase 2.
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

    fullRepresentation: Rectangle {
        Layout.preferredWidth: 520
        Layout.preferredHeight: 280
        Layout.minimumWidth: 300
        Layout.minimumHeight: 160
        color: Kirigami.Theme.backgroundColor
        border.color: Kirigami.Theme.highlightColor
        border.width: 1
        radius: 4

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.sessionFound
                          ? ("// " + root.tmuxTarget)
                          : "// session not found"
                    font.family: "Caveat"
                    font.pixelSize: 19
                    color: Kirigami.Theme.highlightColor
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Kirigami.Theme.highlightColor
                opacity: 0.35
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                TextArea {
                    id: logView
                    text: root.paneContent
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    color: Kirigami.Theme.textColor
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

#### `plasmoids/com.utku.tmuxtail/contents/config/config.qml`

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

#### `plasmoids/com.utku.tmuxtail/contents/config/main.xml`

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

#### `plasmoids/com.utku.tmuxtail/contents/ui/configGeneral.qml`

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

### `install.sh`

```bash
#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONT_DIR="$HOME/.local/share/fonts/luxury-journal"
COLOR_DIR="$HOME/.local/share/color-schemes"

echo "→ Installing fonts to $FONT_DIR"
mkdir -p "$FONT_DIR"

fetch() {
    local name=$1 url=$2 out=$3
    if [[ ! -f "$out" ]]; then
        echo "  · $name"
        curl -sL "$url" -o "$out"
    fi
}

fetch "Parisienne" \
    "https://github.com/google/fonts/raw/main/ofl/parisienne/Parisienne-Regular.ttf" \
    "$FONT_DIR/Parisienne-Regular.ttf"
fetch "Caveat" \
    "https://github.com/google/fonts/raw/main/ofl/caveat/Caveat%5Bwght%5D.ttf" \
    "$FONT_DIR/Caveat.ttf"
fetch "Cormorant Garamond" \
    "https://github.com/google/fonts/raw/main/ofl/cormorantgaramond/CormorantGaramond-Medium.ttf" \
    "$FONT_DIR/CormorantGaramond-Medium.ttf"

fc-cache -f "$FONT_DIR" > /dev/null

echo "→ Installing color scheme"
mkdir -p "$COLOR_DIR"
cp "$REPO_DIR/luxury-journal.colors" "$COLOR_DIR/"

echo "→ Installing plasmoids"
for dir in "$REPO_DIR"/plasmoids/*/; do
    id=$(basename "$dir")
    if kpackagetool6 -t Plasma/Applet --list 2>/dev/null | grep -q "^$id$"; then
        kpackagetool6 -t Plasma/Applet --upgrade "$dir"
    else
        kpackagetool6 -t Plasma/Applet --install "$dir"
    fi
done

cat <<EOF

Installed. Next steps:

  1. System Settings → Colors & Themes → Colors → pick "Luxury Journal"
  2. Right-click desktop → Add or Manage Widgets
     → add "Luxury Greeting" and "Tmux Tail"
     → configure each via the wrench icon
  3. (optional) System Settings → Fonts → set General to "Caveat",
     Fixed Width to "JetBrains Mono"
  4. Browse the KDE Store for the rest of the catalog (see README.md)

To iterate on a plasmoid without rebuilding:
    plasmoidviewer -a plasmoids/com.utku.tmuxtail
EOF
```

Make it executable with `chmod +x install.sh`.

## What to add from the KDE Store (no code needed)

Right-click desktop → Add or Manage Widgets → Get New Widgets → Download New Plasma Widgets. Search for:

- **System Monitor** (built-in, Plasma 6 native) — configurable sensor pages. Add one page called "Machine" showing CPU, Memory, GPU, Disk, Battery. Add another called "Connection" with wi-fi name, bandwidth, ping host. Both inherit the Luxury Journal palette automatically.
- **Digital Clock** (built-in) — the big HH:MM numeral. Set the font override to Cormorant Garamond 500.
- **Weather Report** (built-in) — OpenMeteo as the source, no API key.
- **Notes** (built-in) — sticky-note widget for the scratch pad.
- **Folder View** or **Quicklaunch** (both built-in) — the "at hand" icon grid. Folder View is better if you want it to mirror an actual `~/Launchers/` directory; Quicklaunch is better for explicit configuration.
- **Simple Menu / Tasks** (community) — for the tasks list, any file-backed todo plasmoid. If none of the community ones suit, add a third custom plasmoid that reads `~/notes/tasks.md` — same shape as the tmux widget but reading a file via `cat` instead of `tmux capture-pane`.

## MVP order

Each step must leave the desktop in a usable state.

1. **Color scheme + fonts** — run `install.sh` without any plasmoids enabled. Switch to Luxury Journal in System Settings. Every existing widget on your desktop should shift to parchment/burgundy. This validates the palette before committing to any custom code.
2. **Luxury Greeting plasmoid** — add it, configure name, verify the cursive renders and the greeting adapts across the day (test by temporarily changing system time).
3. **System Monitor + Digital Clock + Notes + Weather** — arrange these on the desktop, no custom code. This gets you 70% of the dashboard for free.
4. **Tmux Tail plasmoid** — install, configure a real session, verify double-click opens the attach command.
5. **Folder View or Quicklaunch** for the shortcut grid.
6. **Optional**: a third custom plasmoid for file-backed tasks, only if no existing one fits.

## Development loop

Fast iteration without Plasma restarts:

```bash
# Live-preview a plasmoid in its own window
plasmoidviewer -a plasmoids/com.utku.tmuxtail

# Edit main.qml, save, it reloads automatically.
# When the shape is right, reinstall into Plasma:
kpackagetool6 -t Plasma/Applet --upgrade plasmoids/com.utku.tmuxtail

# Then right-click the widget on the desktop → Refresh,
# or remove and re-add it.
```

QML errors go to stdout when launched via `plasmoidviewer`; when running inside Plasma, check with `journalctl --user -f -t plasmashell`.

## Non-goals

- A plugin framework. Plasma *is* the framework.
- A YAML config file. Plasmoids have their own per-instance config UI.
- Hot-reload of layout. The user drags widgets around in "Edit Mode"; Plasma remembers.
- Windows/macOS compatibility.
- Shipping on the KDE Store publicly. Personal setup, personal install.

## Acceptance criteria

- `./install.sh` succeeds on a fresh Fedora KDE install with no manual steps.
- Luxury Journal appears in System Settings → Colors and applies cleanly.
- Three fonts (Parisienne, Caveat, Cormorant Garamond) appear in System Settings → Fonts.
- Luxury Greeting renders cursive text, shows the correct greeting for the current hour, and updates when the hour rolls over.
- Tmux Tail shows the last N lines of a real tmux pane, refreshes at the configured interval, gracefully shows "session not found" if the target doesn't exist, and opens a real terminal on double-click.
- Both custom plasmoids visually inherit the Luxury Journal palette via `Kirigami.Theme.*` (no hardcoded colors beyond the one explicit burgundy fallback in the greeting).
- Plasma shell does not crash or throw QML errors to journalctl during normal operation.

## Style notes for the AI building this

- Every QML file is self-contained and readable without cross-referencing. No deep component hierarchies.
- Colors come from `Kirigami.Theme.*` — never hardcode hex values in QML except where explicitly called out (e.g. the Parisienne burgundy).
- Polling is always via `Plasma5Support.DataSource` with the `executable` engine; disconnect the source after each reply to avoid leaks.
- If a shell command fails, render a muted state — never let a plasmoid crash. Log once with `console.warn` then stay silent.
- Keep `main.qml` under 150 lines. If a widget wants more, it wants a helper component file.
- No external QML dependencies beyond Qt, Kirigami, Plasma, and Plasma5Support. These are guaranteed on any Plasma 6 install.
