import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "shared" as Shared

PlasmoidItem {
    id: root


    property real ts: (Plasmoid.configuration.textScale && Plasmoid.configuration.textScale > 0) ? Plasmoid.configuration.textScale : 1.25
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

        Shared.ParchmentBackground {
            anchors.fill: parent
            alpha:     Plasmoid.configuration.backgroundOpacity > 0 ? Plasmoid.configuration.backgroundOpacity : 1.0
            edgeStyle: Plasmoid.configuration.edgeStyle || "rounded"
        }
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
                font.pixelSize: 56 * root.ts
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                visible: root.showSeconds
                text: root.currentSeconds
                color: Shared.Palette.inkMedium
                font.family: Shared.Palette.fontSerif
                font.pixelSize: 22 * root.ts
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
                    font.pixelSize: 14 * root.ts
                }
                Text {
                    text: root.dateOrdinalHtml
                    textFormat: Text.RichText
                    color: Shared.Palette.inkDark
                    font.family: Shared.Palette.fontSerif
                    font.italic: true
                    font.pixelSize: 14 * root.ts
                }
            }
        }
    }
}
