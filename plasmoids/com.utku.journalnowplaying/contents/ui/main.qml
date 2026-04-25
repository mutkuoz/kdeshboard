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
            // Route by distinctive substrings of each qdbus command.
            if (sourceName.indexOf("grep ^org.mpris") !== -1) {
                const services = stdout.split("\n").filter(s => s.startsWith("org.mpris.MediaPlayer2."))
                if (preferredPlayer) {
                    const match = services.find(s => s.toLowerCase().endsWith("." + preferredPlayer.toLowerCase()))
                    currentPlayer = match || (services[0] || "")
                } else {
                    currentPlayer = services[0] || ""
                }
                if (currentPlayer) queryMetadata()
                else resetEmpty()
            } else if (sourceName.indexOf(".Player.Metadata") !== -1) {
                parseMetadata(stdout)
            } else if (sourceName.indexOf(".Player.PlaybackStatus") !== -1) {
                const m = stdout.match(/Playing|Paused|Stopped/)
                status = m ? m[0] : "Stopped"
            } else if (sourceName.indexOf(".Player.Position") !== -1) {
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
        // Try qdbus6 first (Plasma 6 default), then plain qdbus.
        executable.exec("(qdbus6 2>/dev/null || qdbus 2>/dev/null) | grep ^org.mpris.MediaPlayer2")
    }
    function queryMetadata() {
        if (!currentPlayer) return
        const qd = "(command -v qdbus6 >/dev/null && qdbus6 || qdbus)"
        executable.exec(qd + " " + currentPlayer + " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata")
        executable.exec(qd + " " + currentPlayer + " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlaybackStatus")
        executable.exec(qd + " " + currentPlayer + " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Position")
    }
    function control(method) {
        if (!currentPlayer) return
        const qd = "(command -v qdbus6 >/dev/null && qdbus6 || qdbus)"
        executable.exec(qd + " " + currentPlayer + " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player." + method)
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

        Shared.ParchmentBackground {
            anchors.fill: parent
            alpha:     Plasmoid.configuration.backgroundOpacity > 0 ? Plasmoid.configuration.backgroundOpacity : 1.0
            edgeStyle: Plasmoid.configuration.edgeStyle || "rounded"
        }
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
                font.pixelSize: 15
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
