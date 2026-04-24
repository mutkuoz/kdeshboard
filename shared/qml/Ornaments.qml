// Ornament primitives — use as inline Components:
//   import "../shared" as Shared
//   Shared.Ornaments.DoubleRule { width: parent.width }
//
// This file exposes each primitive as a Component property so callers
// instantiate them via `Shared.Ornaments.DoubleRule { ... }`.
// Palette is accessible unprefixed because it's a singleton in the same
// QML module as this file (see qmldir).
import QtQuick
import QtQuick.Shapes

QtObject {
    // ---- DoubleRule: two thin horizontal gilt lines ---------------------
    property Component DoubleRule: Component {
        Item {
            id: ruleRoot
            property color color: Palette.gilt
            property real inset: 0
            implicitHeight: 5

            Rectangle {
                x: ruleRoot.inset
                width: ruleRoot.width - ruleRoot.inset * 2
                height: 1
                color: ruleRoot.color
                antialiasing: true
                y: 0
            }
            Rectangle {
                x: ruleRoot.inset
                width: ruleRoot.width - ruleRoot.inset * 2
                height: 1
                color: ruleRoot.color
                antialiasing: true
                y: 3
            }
        }
    }

    // ---- Fleuron: centered ornament character ---------------------------
    property Component Fleuron: Component {
        Item {
            id: flRoot
            property string glyph: "❦"
            property real glyphSize: 14
            property color color: Palette.gilt
            implicitHeight: Math.ceil(glyphSize * 1.3)
            implicitWidth: Math.ceil(glyphSize * 1.6)

            Text {
                anchors.centerIn: parent
                text: flRoot.glyph
                color: flRoot.color
                font.family: Palette.fontSerif
                font.pixelSize: flRoot.glyphSize
            }
        }
    }

    // ---- WaxSeal: wax circle with gilt rim and centered initial --------
    property Component WaxSeal: Component {
        Item {
            id: sealRoot
            property real diameter: 18
            property string label: "T"
            property color bodyColor: Palette.wax
            property color rimColor:  Palette.gilt
            property color textColor: Palette.gilt
            property real rimOpacity: 1.0
            implicitWidth: diameter
            implicitHeight: diameter

            Rectangle {
                anchors.fill: parent
                radius: sealRoot.diameter / 2
                color: sealRoot.bodyColor
                antialiasing: true
                border.color: sealRoot.rimColor
                border.width: Math.max(1, sealRoot.diameter / 18)
                opacity: 1.0

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: sealRoot.rimColor
                    border.width: parent.border.width
                    opacity: sealRoot.rimOpacity
                    antialiasing: true
                }
            }

            Text {
                anchors.centerIn: parent
                text: sealRoot.label
                color: sealRoot.textColor
                font.family: Palette.fontInitial
                font.pixelSize: sealRoot.diameter * 0.56
            }
        }
    }

    // ---- PageCorner: turned-down paper corner (top-right placement) -----
    property Component PageCorner: Component {
        Item {
            id: cornerRoot
            property real size: 16
            property color fold: Palette.paperShadow
            property color edge: Palette.gilt
            implicitWidth: size
            implicitHeight: size

            Shape {
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    strokeColor: cornerRoot.edge
                    strokeWidth: 0.75
                    fillColor: cornerRoot.fold
                    startX: cornerRoot.size; startY: 0
                    PathLine { x: 0;                 y: 0 }
                    PathLine { x: cornerRoot.size;  y: cornerRoot.size }
                    PathLine { x: cornerRoot.size;  y: 0 }
                }
            }
        }
    }
}
