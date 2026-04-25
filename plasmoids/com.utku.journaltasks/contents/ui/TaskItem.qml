import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "shared" as Shared

Item {
    id: root
    property bool checked: false
    property string body: ""
    property int indent: 0
    property real ts: 1.0
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
                font.pixelSize: 14 * root.ts
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
            font.pixelSize: 14 * root.ts
            font.strikeout: root.checked
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Behavior on font.strikeout { enabled: false } // purely cosmetic flip; opacity animates instead
            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }
}
