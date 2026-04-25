import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "shared" as Shared

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property string upcomingLabel: Plasmoid.configuration.upcomingLabel
    property string upcomingDate:  Plasmoid.configuration.upcomingDate   // "MM-DD"
    property string hemisphere:    Plasmoid.configuration.hemisphere     // "north" | "south"

    property string dateLine:   ""
    property string seasonLine: ""
    property string moonLine:   ""
    property string dayCount:   ""
    property string countdown:  ""

    readonly property var moonNames: [
        "new moon","waxing crescent","first quarter","waxing gibbous",
        "full moon","waning gibbous","last quarter","waning crescent"
    ]

    function ordinal(n) {
        const s = ["th","st","nd","rd"]
        const v = n % 100
        return n + (s[(v - 20) % 10] || s[v] || s[0])
    }

    function dayOfYear(d) {
        const start = new Date(d.getFullYear(), 0, 1)
        return Math.floor((d - start) / 86400000) + 1
    }

    function isLeap(y) {
        return (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0
    }

    function daysInYear(y) { return isLeap(y) ? 366 : 365 }

    function seasonName(d) {
        const m = d.getMonth() + 1
        const day = d.getDate()
        // Approximate solstice/equinox dates; flip for southern hemisphere
        function northSeason() {
            if ((m === 3 && day >= 20) || m === 4 || m === 5 || (m === 6 && day < 21)) return "spring"
            if ((m === 6 && day >= 21) || m === 7 || m === 8 || (m === 9 && day < 23)) return "summer"
            if ((m === 9 && day >= 23) || m === 10 || m === 11 || (m === 12 && day < 21)) return "autumn"
            return "winter"
        }
        const n = northSeason()
        if (hemisphere === "south") {
            return { spring: "autumn", summer: "winter", autumn: "spring", winter: "summer" }[n]
        }
        return n
    }

    function moonPhaseIndex(d) {
        const julian = d.getTime() / 86400000 + 2440587.5
        const age = ((julian - 2451549.5) % 29.53059 + 29.53059) % 29.53059
        return Math.floor((age / 29.53059) * 8) % 8
    }

    function parseMMDD(s) {
        const m = /^(\d{1,2})-(\d{1,2})$/.exec(s || "")
        if (!m) return null
        return { month: parseInt(m[1], 10), day: parseInt(m[2], 10) }
    }

    function daysUntil(mmdd, from) {
        const target = parseMMDD(mmdd)
        if (!target) return -1
        let t = new Date(from.getFullYear(), target.month - 1, target.day, 0, 0, 0)
        const f = new Date(from.getFullYear(), from.getMonth(), from.getDate(), 0, 0, 0)
        if (t < f) t = new Date(from.getFullYear() + 1, target.month - 1, target.day)
        return Math.round((t - f) / 86400000)
    }

    function update() {
        const d = new Date()
        const days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
        const months = ["January","February","March","April","May","June",
                        "July","August","September","October","November","December"]
        dateLine = days[d.getDay()] + ", the " + ordinal(d.getDate()) +
                   " of " + months[d.getMonth()] + ", " + d.getFullYear()

        seasonLine = "Season of " + seasonName(d)
        moonLine = "Moon — " + moonNames[moonPhaseIndex(d)]
        const n = dayOfYear(d)
        const total = daysInYear(d.getFullYear())
        dayCount = ordinal(n) + " day · " + (total - n) + " remain"

        if (upcomingLabel && upcomingDate) {
            const n2 = daysUntil(upcomingDate, d)
            if (n2 === 0)      countdown = upcomingLabel + " — today."
            else if (n2 === 1) countdown = upcomingLabel + " — tomorrow."
            else if (n2 > 0)   countdown = n2 + " days until " + upcomingLabel + "."
            else               countdown = ""
        } else {
            countdown = ""
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.update()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 360
        Layout.preferredHeight: 180
        Layout.minimumWidth: 260
        Layout.minimumHeight: 140

        Shared.ParchmentBackground {
            anchors.fill: parent
            alpha:     Plasmoid.configuration.backgroundOpacity
            edgeStyle: Plasmoid.configuration.edgeStyle
        }
        Loader { sourceComponent: Shared.Ornaments.PageCorner; anchors.top: parent.top; anchors.right: parent.right }

        Shared.MoonPhase {
            id: moon
            size: 22
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 12
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 44
            anchors.rightMargin: 14
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            spacing: 2

            Text {
                text: "ALMANAC"
                color: Shared.Palette.burgundy
                font.family: Shared.Palette.fontSmallCaps
                font.pixelSize: 14
                font.letterSpacing: 2.0
            }
            Loader { sourceComponent: Shared.Ornaments.DoubleRule; Layout.fillWidth: true }

            Text {
                text: root.dateLine
                color: Shared.Palette.inkDark
                font.family: Shared.Palette.fontSerif
                font.italic: true
                font.pixelSize: 16
                Layout.topMargin: 4
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: "❦"; color: Shared.Palette.gilt; font.family: Shared.Palette.fontSerif; font.pixelSize: 15 }
                Text {
                    text: root.seasonLine
                    color: Shared.Palette.inkMedium
                    font.family: Shared.Palette.fontAccent
                    font.pixelSize: 14
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: "☾"; color: Shared.Palette.gilt; font.family: Shared.Palette.fontSerif; font.pixelSize: 15 }
                Text {
                    text: root.moonLine
                    color: Shared.Palette.inkMedium
                    font.family: Shared.Palette.fontAccent
                    font.pixelSize: 14
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: "§"; color: Shared.Palette.gilt; font.family: Shared.Palette.fontSerif; font.pixelSize: 15 }
                Text {
                    text: root.dayCount
                    color: Shared.Palette.inkMedium
                    font.family: Shared.Palette.fontAccent
                    font.pixelSize: 14
                }
            }
            Item { Layout.fillHeight: true }
            Text {
                visible: root.countdown.length > 0
                text: root.countdown
                color: Shared.Palette.wax
                font.family: Shared.Palette.fontDisplay
                font.pixelSize: 15
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }
}
