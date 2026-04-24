// Compact donut gauge: track ring + filled arc + center numeric + label below.
// A missing value (-1) renders as an empty track with "—" in the middle.
import QtQuick
import "shared" as Shared

Item {
    id: root
    property real    value: 0           // actual reading; -1 means unavailable
    property real    maxValue: 100
    property string  unit: ""
    property string  label: ""
    property color   ringColor: Shared.Palette.burgundy
    property int     warnThreshold: 80  // shifts ring to wax when exceeded
    property color   warnColor: Shared.Palette.wax
    property bool    invertWarning: false

    implicitWidth: 78
    implicitHeight: 82

    readonly property bool available: root.value >= 0
    readonly property bool warned: available &&
        (invertWarning ? (value / maxValue) < (warnThreshold / 100)
                       : (value / maxValue) > (warnThreshold / 100))

    Canvas {
        id: ring
        width: 54
        height: 54
        anchors.top: parent.top
        anchors.topMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2
            const cy = height / 2
            const r  = Math.min(cx, cy) - 4

            // Track
            ctx.strokeStyle = Shared.Palette.gilt
            ctx.globalAlpha = 0.35
            ctx.lineWidth   = 3
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, 2 * Math.PI)
            ctx.stroke()
            ctx.globalAlpha = 1.0

            if (!root.available) return

            const pct = Math.max(0, Math.min(1, root.value / root.maxValue))
            ctx.strokeStyle = root.warned ? root.warnColor : root.ringColor
            ctx.lineWidth   = 3
            ctx.lineCap     = "round"
            ctx.beginPath()
            const start = -Math.PI / 2
            const end   = start + pct * 2 * Math.PI
            ctx.arc(cx, cy, r, start, end)
            ctx.stroke()
        }
        Connections {
            target: root
            function onValueChanged()     { ring.requestPaint() }
            function onRingColorChanged() { ring.requestPaint() }
            function onMaxValueChanged()  { ring.requestPaint() }
        }
    }

    Text {
        anchors.centerIn: ring
        text: root.available
              ? (root.value >= 100 ? Math.round(root.value) : root.value.toFixed(root.value < 10 ? 1 : 0))
              : "—"
        color: root.warned ? Shared.Palette.wax : Shared.Palette.inkDark
        font.family: Shared.Palette.fontSerif
        font.pixelSize: 15
        font.weight: Font.DemiBold
    }

    Text {
        anchors.top: ring.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 2
        text: (root.unit ? root.unit + " · " : "") + root.label
        color: Shared.Palette.inkMedium
        font.family: Shared.Palette.fontSmallCaps
        font.pixelSize: 9
        font.letterSpacing: 1.2
    }
}
