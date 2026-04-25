// Parchment panel with optional stylish touches:
//   - alpha:       base background opacity (0.0..1.0) for "see-through" widgets
//   - edgeStyle:   "rounded" (default), "ripped" (torn bottom), "deckle" (wavy all-around),
//                  "stamped" (postage-stamp perforations), "embossed" (gilt frame)
//   - showFoxing:  three dim "age spots"
//   - showGrain:   faint SVG turbulence noise overlay
//
// Visibility rule: the simple Rectangle is the default and is shown for ANY
// edgeStyle that isn't one of the explicit shape modes ("ripped", "deckle").
// This makes the widget render correctly when the cfg alias is briefly an
// empty string during config load, or holds an unrecognised value.
//
// Important: the Palette singleton is declared in this directory's qmldir,
// but qmldir-declared singletons aren't automatically in scope for sibling
// files — we need an explicit local import. Without this, Lib.Palette.X
// silently resolves to undefined and Qt logs "Unable to assign [undefined]
// to QColor" for every color binding.
import QtQuick
import "." as Lib

Item {
    id: root
    property real cornerRadius: 4
    property bool showFoxing: true
    property bool showGrain: true
    property real noiseOpacity: 0.06
    property real alpha: 1.0                      // 0..1; applied to base fill
    property string edgeStyle: "rounded"          // "rounded" | "ripped" | "deckle" | "stamped" | "embossed"

    readonly property bool useShapedFill: edgeStyle === "ripped" || edgeStyle === "deckle"
    readonly property color resolvedColor: Qt.rgba(
        Lib.Palette.parchment.r, Lib.Palette.parchment.g, Lib.Palette.parchment.b, root.alpha)

    // --- Default base fill — always shown unless a shaped mode is active ----
    Rectangle {
        id: basePlain
        visible: !root.useShapedFill
        anchors.fill: parent
        radius: root.cornerRadius
        antialiasing: true
        color: root.resolvedColor
        border.width: root.edgeStyle === "embossed" ? 1.5 : 0
        border.color: Lib.Palette.gilt
    }

    // --- Ripped/deckle fill via Canvas --------------------------------------
    Canvas {
        id: shapedFill
        visible: root.useShapedFill
        anchors.fill: parent
        antialiasing: true
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.fillStyle = root.resolvedColor
            ctx.strokeStyle = Lib.Palette.paperShadow
            ctx.lineWidth = 0.5
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(width, 0)

            if (root.edgeStyle === "deckle") {
                const steps = Math.max(6, Math.floor(height / 14))
                for (let i = 1; i <= steps; i++) {
                    const y = (i / steps) * height
                    const jitter = ((i * 31) % 7) - 3
                    ctx.lineTo(width + jitter, y)
                }
            } else {
                ctx.lineTo(width, height)
            }

            if (root.edgeStyle === "ripped") {
                const teeth = Math.max(8, Math.floor(width / 22))
                for (let i = teeth - 1; i >= 0; i--) {
                    const x = (i / teeth) * width
                    const down = (i * 41) % 9
                    const up   = (i * 53) % 7
                    ctx.lineTo(x + width / (teeth * 2), height - up)
                    ctx.lineTo(x, height + down)
                }
            } else if (root.edgeStyle === "deckle") {
                const steps = Math.max(8, Math.floor(width / 14))
                for (let i = steps - 1; i >= 0; i--) {
                    const x = (i / steps) * width
                    const jitter = ((i * 23) % 7) - 3
                    ctx.lineTo(x, height + jitter)
                }
            } else {
                ctx.lineTo(0, height)
            }

            if (root.edgeStyle === "deckle") {
                const steps = Math.max(6, Math.floor(height / 14))
                for (let i = steps - 1; i >= 0; i--) {
                    const y = (i / steps) * height
                    const jitter = ((i * 17) % 7) - 3
                    ctx.lineTo(jitter, y)
                }
            }

            ctx.lineTo(0, 0)
            ctx.closePath()
            ctx.fill()
            ctx.stroke()
        }
        Connections {
            target: root
            function onAlphaChanged()       { shapedFill.requestPaint() }
            function onEdgeStyleChanged()   { shapedFill.requestPaint() }
        }
        onWidthChanged:  requestPaint()
        onHeightChanged: requestPaint()
    }

    // --- Stamped mode: postage-stamp perforation dots around the perimeter ---
    Item {
        id: stamped
        anchors.fill: parent
        visible: root.edgeStyle === "stamped"
        readonly property int hCount: Math.max(12, Math.floor(root.width / 12))
        readonly property int vCount: Math.max(8, Math.floor(root.height / 12))

        Repeater {
            model: stamped.hCount
            Rectangle {
                width: 4; height: 4; radius: 2
                color: Lib.Palette.parchment
                x: (index / stamped.hCount) * root.width - 2
                y: -2
            }
        }
        Repeater {
            model: stamped.hCount
            Rectangle {
                width: 4; height: 4; radius: 2
                color: Lib.Palette.parchment
                x: (index / stamped.hCount) * root.width - 2
                y: root.height - 2
            }
        }
        Repeater {
            model: stamped.vCount
            Rectangle {
                width: 4; height: 4; radius: 2
                color: Lib.Palette.parchment
                y: (index / stamped.vCount) * root.height - 2
                x: -2
            }
        }
        Repeater {
            model: stamped.vCount
            Rectangle {
                width: 4; height: 4; radius: 2
                color: Lib.Palette.parchment
                y: (index / stamped.vCount) * root.height - 2
                x: root.width - 2
            }
        }
    }

    // --- Noise overlay (turbulence SVG) --------------------------------------
    Image {
        id: noise
        visible: root.showGrain
        anchors.fill: parent
        opacity: root.noiseOpacity * root.alpha
        fillMode: Image.Tile
        source: "data:image/svg+xml;utf8," + encodeURIComponent(
            '<svg xmlns="http://www.w3.org/2000/svg" width="140" height="140">' +
              '<filter id="n">' +
                '<feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="7"/>' +
                '<feColorMatrix values="0 0 0 0 0.18  0 0 0 0 0.12  0 0 0 0 0.07  0 0 0 0.7 0"/>' +
              '</filter>' +
              '<rect width="140" height="140" filter="url(#n)"/>' +
            '</svg>')
        smooth: false
    }

    // --- Foxing spots --------------------------------------------------------
    Repeater {
        model: root.showFoxing ? 3 : 0
        Rectangle {
            parent: root
            property real spotSize: 14 + (index * 9) % 18
            width: spotSize
            height: spotSize
            radius: spotSize / 2
            color: Lib.Palette.foxing
            opacity: 0.10 * root.alpha
            x: (index === 0 ? 0.12 : index === 1 ? 0.78 : 0.55) * root.width
            y: (index === 0 ? 0.82 : index === 1 ? 0.22 : 0.48) * root.height
            antialiasing: true
            visible: root.width > 120 && root.height > 80
        }
    }
}
