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
                    color: Shared.Palette.burgundy
                    font.family: Shared.Palette.fontDisplay
                    font.pixelSize: 48
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
