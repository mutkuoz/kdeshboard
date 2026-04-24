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
