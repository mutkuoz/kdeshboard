pragma Singleton
import QtQuick

// Hard-coded color tokens. These are the journal's identity and must NOT
// inherit from Kirigami.Theme — when a plasmoid lands on a dark Plasma
// panel, Kirigami.Theme.backgroundColor turns dark gray and the leather
// aesthetic collapses. The system color scheme still themes everything
// outside the plasmoid (Plasma's own widgets, KDE apps); inside our
// custom plasmoids we render on parchment, deliberately.
QtObject {
    // Parchment & ink — match luxury-journal.colors so a user who picks
    // the system color scheme + a custom plasmoid sees the same hues.
    readonly property color parchment:   "#F2E8D3"   // 242,232,211
    readonly property color parchmentAlt: "#ECE0C8"  // 236,224,200
    readonly property color inkDark:     "#2D1810"   //  45, 24, 16
    readonly property color inkMedium:   "#6B4E36"   // 107, 78, 54
    readonly property color burgundy:    "#722529"   // 114, 37, 41

    // Ornament-only tokens not in the .colors file.
    readonly property color gilt:        "#9A7F3A"
    readonly property color wax:         "#6E1E23"
    readonly property color paperShadow: "#C4B498"
    readonly property color inkWet:      "#8A2A2E"
    readonly property color foxing:      "#B39A72"

    // Font family constants. The fonts themselves are installed by install.sh
    // under ~/.local/share/fonts/luxury-journal/; here we only name them.
    readonly property string fontDisplay: "Parisienne"
    readonly property string fontAccent:  "Caveat"
    readonly property string fontSerif:   "Cormorant Garamond"
    readonly property string fontInitial: "IM FELL DW Pica"
    readonly property string fontSmallCaps: "Cormorant SC"
    readonly property string fontMono:    "JetBrains Mono"
}
