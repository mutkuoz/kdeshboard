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

    property string itemsText: Plasmoid.configuration.itemsText
    property int    iconSize:  Plasmoid.configuration.iconSize
    property int    columns:   Math.max(1, Plasmoid.configuration.columns)
    property bool   showLabels: Plasmoid.configuration.showLabels

    // Parsed list of { label, icon, command } from itemsText.
    property var items: parseItems(itemsText)

    function parseItems(text) {
        const out = []
        const lines = (text || "").split("\n")
        for (const line of lines) {
            const trimmed = line.trim()
            if (!trimmed || trimmed.startsWith("#")) continue
            const parts = trimmed.split("|").map(s => s.trim())
            if (parts.length >= 3 && parts[0] && parts[2]) {
                out.push({ label: parts[0], icon: parts[1] || "applications-other", cmd: parts[2] })
            }
        }
        return out
    }

    onItemsTextChanged: items = parseItems(itemsText)

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: function(sn) { disconnectSource(sn) }
        function exec(cmd) { if (cmd) connectSource(cmd) }
    }

    function launch(cmd) {
        if (!cmd) return
        executable.exec(cmd)
    }

    fullRepresentation: Item {
        Layout.preferredWidth:  Math.max(180, root.columns * (root.iconSize + 28) + 28)
        Layout.preferredHeight: 80 + Math.ceil(Math.max(1, root.items.length) / root.columns)
                                * (root.iconSize + (root.showLabels ? 28 : 12) + 8)
        Layout.minimumWidth:  140
        Layout.minimumHeight: 100

        Shared.ParchmentBackground {
            anchors.fill: parent
            alpha:     Plasmoid.configuration.backgroundOpacity > 0 ? Plasmoid.configuration.backgroundOpacity : 1.0
            edgeStyle: Plasmoid.configuration.edgeStyle || "rounded"
        }
        Loader { sourceComponent: Shared.Ornaments.PageCorner; anchors.top: parent.top; anchors.right: parent.right }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text {
                text: "QUICK ACCESS"
                color: Shared.Palette.burgundy
                font.family: Shared.Palette.fontSmallCaps
                font.pixelSize: 14 * root.ts
                font.letterSpacing: 2.0
                Layout.alignment: Qt.AlignHCenter
            }
            Loader { sourceComponent: Shared.Ornaments.DoubleRule; Layout.fillWidth: true }

            GridLayout {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                Layout.topMargin: 6
                columns: root.columns
                rowSpacing: 6
                columnSpacing: 6

                Repeater {
                    model: root.items

                    delegate: Item {
                        id: tile
                        property bool hovered: tileMouse.containsMouse
                        Layout.preferredWidth:  root.iconSize + 24
                        Layout.preferredHeight: root.iconSize + (root.showLabels ? 28 : 8)

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: tile.hovered ? Qt.rgba(Shared.Palette.gilt.r, Shared.Palette.gilt.g, Shared.Palette.gilt.b, 0.18)
                                                : "transparent"
                            border.color: tile.hovered ? Shared.Palette.gilt : "transparent"
                            border.width: 1
                            Behavior on color  { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            Kirigami.Icon {
                                source: modelData.icon
                                Layout.preferredWidth:  root.iconSize
                                Layout.preferredHeight: root.iconSize
                                Layout.alignment: Qt.AlignHCenter
                                color: Shared.Palette.inkDark   // tints monochrome icons
                                opacity: tile.hovered ? 1.0 : 0.92
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                            }
                            Text {
                                visible: root.showLabels
                                text: modelData.label
                                color: tile.hovered ? Shared.Palette.burgundy : Shared.Palette.inkDark
                                font.family: Shared.Palette.fontAccent
                                font.pixelSize: 12 * root.ts
                                Layout.alignment: Qt.AlignHCenter
                                Layout.maximumWidth: root.iconSize + 20
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }
                        }

                        ToolTip.visible: tile.hovered && (!root.showLabels || modelData.label.length > 12)
                        ToolTip.text: modelData.label + " — " + modelData.cmd
                        ToolTip.delay: 600

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.launch(modelData.cmd)
                        }
                    }
                }
            }

            // Empty-state hint when itemsText is blank or unparseable.
            Text {
                visible: root.items.length === 0
                Layout.alignment: Qt.AlignHCenter
                text: "— configure items in the wrench menu —"
                color: Shared.Palette.inkMedium
                font.family: Shared.Palette.fontAccent
                font.italic: true
                font.pixelSize: 13 * root.ts
            }
        }
    }
}
