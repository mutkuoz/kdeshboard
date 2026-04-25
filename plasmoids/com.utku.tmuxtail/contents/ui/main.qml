import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "shared" as Shared

PlasmoidItem {
    id: root


    property real ts: (Plasmoid.configuration.textScale && Plasmoid.configuration.textScale > 0) ? Plasmoid.configuration.textScale : 1.25
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

        Shared.ParchmentBackground {
            anchors.fill: parent
            alpha:     Plasmoid.configuration.backgroundOpacity > 0 ? Plasmoid.configuration.backgroundOpacity : 1.0
            edgeStyle: Plasmoid.configuration.edgeStyle || "rounded"
        }

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
                font.pixelSize: 19 * root.ts
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
                    font.pixelSize: 14 * root.ts
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
