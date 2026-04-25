import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "shared" as Shared

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property int    durationMinutes:   Plasmoid.configuration.durationMinutes
    property string completionCommand: Plasmoid.configuration.completionCommand
    property bool   autoRepeat:        Plasmoid.configuration.autoRepeat

    // State
    property bool running: false
    property real remainingMs: durationMinutes * 60000   // when paused, time left; when running, snapshot updated by tick
    property double startedAt: 0                         // Date.now() at last start; 0 when paused

    function totalMs()     { return durationMinutes * 60000 }
    function currentRemaining() {
        if (!running) return remainingMs
        return Math.max(0, remainingMs - (Date.now() - startedAt))
    }
    function progress() {
        const t = totalMs()
        return t > 0 ? 1 - currentRemaining() / t : 0
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: function(sn) { disconnectSource(sn) }
        function exec(cmd) { if (cmd) connectSource(cmd) }
    }

    function start() {
        if (running) return
        if (remainingMs <= 0) remainingMs = totalMs()
        startedAt = Date.now()
        running = true
    }
    function pause() {
        if (!running) return
        remainingMs = currentRemaining()
        startedAt = 0
        running = false
    }
    function reset() {
        running = false
        startedAt = 0
        remainingMs = totalMs()
    }
    function complete() {
        running = false
        startedAt = 0
        remainingMs = 0
        if (completionCommand) executable.exec(completionCommand)
        if (autoRepeat) {
            remainingMs = totalMs()
            start()
        }
    }

    // Tick driver. 250ms for smooth sand animation.
    Timer {
        interval: 250
        running: root.running
        repeat: true
        onTriggered: {
            glass.requestPaint()
            label.text = root.formatRemaining()
            if (root.currentRemaining() <= 0) root.complete()
        }
    }

    Connections {
        target: root
        function onDurationMinutesChanged() { root.reset(); glass.requestPaint() }
    }

    function formatRemaining() {
        const ms = currentRemaining()
        const total = Math.max(0, Math.floor(ms / 1000))
        const h = Math.floor(total / 3600)
        const m = Math.floor((total % 3600) / 60)
        const s = total % 60
        const pad = n => n.toString().padStart(2, "0")
        return h > 0 ? (h + ":" + pad(m) + ":" + pad(s)) : (pad(m) + ":" + pad(s))
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 220
        Layout.preferredHeight: 260
        Layout.minimumWidth: 160
        Layout.minimumHeight: 200

        Shared.ParchmentBackground {
            anchors.fill: parent
            alpha:     Plasmoid.configuration.backgroundOpacity
            edgeStyle: Plasmoid.configuration.edgeStyle
        }
        Loader { sourceComponent: Shared.Ornaments.PageCorner; anchors.top: parent.top; anchors.right: parent.right }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 2

            Text {
                text: "HOURGLASS"
                color: Shared.Palette.burgundy
                font.family: Shared.Palette.fontSmallCaps
                font.pixelSize: 14
                font.letterSpacing: 2.0
                Layout.alignment: Qt.AlignHCenter
            }
            Loader { sourceComponent: Shared.Ornaments.DoubleRule; Layout.fillWidth: true }

            // The hourglass itself
            Canvas {
                id: glass
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 6
                Layout.bottomMargin: 2
                antialiasing: true

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const w = width, h = height
                    const pad = 12
                    const frameW = Math.min(w, h * 0.65)
                    const cx = w / 2
                    const frameLeft = cx - frameW / 2
                    const top = pad
                    const bottom = h - pad
                    const midY = (top + bottom) / 2
                    const neckHalf = frameW * 0.08

                    // Frame (upper and lower caps in gilt)
                    ctx.strokeStyle = Shared.Palette.gilt
                    ctx.fillStyle = Qt.rgba(Shared.Palette.gilt.r, Shared.Palette.gilt.g, Shared.Palette.gilt.b, 0.6)
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    ctx.moveTo(frameLeft - 4, top - 3)
                    ctx.lineTo(frameLeft + frameW + 4, top - 3)
                    ctx.lineTo(frameLeft + frameW + 4, top + 4)
                    ctx.lineTo(frameLeft - 4, top + 4)
                    ctx.closePath()
                    ctx.fill()
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.moveTo(frameLeft - 4, bottom - 4)
                    ctx.lineTo(frameLeft + frameW + 4, bottom - 4)
                    ctx.lineTo(frameLeft + frameW + 4, bottom + 3)
                    ctx.lineTo(frameLeft - 4, bottom + 3)
                    ctx.closePath()
                    ctx.fill()
                    ctx.stroke()

                    // Hourglass body outline
                    ctx.strokeStyle = Shared.Palette.inkDark
                    ctx.lineWidth = 1.2
                    ctx.beginPath()
                    ctx.moveTo(frameLeft, top)
                    ctx.lineTo(cx - neckHalf, midY)
                    ctx.lineTo(frameLeft, bottom)
                    ctx.moveTo(frameLeft + frameW, top)
                    ctx.lineTo(cx + neckHalf, midY)
                    ctx.lineTo(frameLeft + frameW, bottom)
                    ctx.stroke()

                    // Sand. progress = fraction elapsed → sand fraction in lower bulb.
                    const prog = Math.max(0, Math.min(1, root.progress()))

                    function trapezoidPath(yFrom, yTo, isUpper) {
                        // Returns path between two heights in the hourglass shape.
                        const t = isUpper ? top : midY
                        const b = isUpper ? midY : bottom
                        function halfWidthAt(y) {
                            if (isUpper) {
                                const f = (y - t) / (b - t)
                                return (frameW / 2) * (1 - f) + neckHalf * f
                            } else {
                                const f = (y - t) / (b - t)
                                return neckHalf * (1 - f) + (frameW / 2) * f
                            }
                        }
                        ctx.beginPath()
                        const lwT = halfWidthAt(yFrom)
                        const lwB = halfWidthAt(yTo)
                        ctx.moveTo(cx - lwT, yFrom)
                        ctx.lineTo(cx + lwT, yFrom)
                        ctx.lineTo(cx + lwB, yTo)
                        ctx.lineTo(cx - lwB, yTo)
                        ctx.closePath()
                    }

                    // Upper sand: remaining in upper bulb, from top down by (1-prog) fraction
                    const upperH = midY - top
                    const lowerH = bottom - midY
                    const upperFill = upperH * (1 - prog)
                    const lowerFill = lowerH * prog

                    ctx.fillStyle = Shared.Palette.gilt
                    if (upperFill > 0.5) {
                        // Fill from (midY - upperFill) to midY
                        trapezoidPath(midY - upperFill, midY, true)
                        ctx.fill()
                    }
                    if (lowerFill > 0.5) {
                        trapezoidPath(bottom - lowerFill, bottom, false)
                        ctx.fill()
                    }

                    // Falling sand stream (thin vertical line) only when running and upper not empty
                    if (root.running && upperFill > 0.5 && lowerFill < lowerH - 0.5) {
                        ctx.strokeStyle = Shared.Palette.gilt
                        ctx.lineWidth = 1
                        ctx.beginPath()
                        ctx.moveTo(cx, midY + 1)
                        ctx.lineTo(cx, bottom - lowerFill)
                        ctx.stroke()
                    }
                }
                Connections {
                    target: root
                    function onRunningChanged()     { glass.requestPaint() }
                    function onRemainingMsChanged() { glass.requestPaint() }
                }
                onWidthChanged:  requestPaint()
                onHeightChanged: requestPaint()
            }

            Text {
                id: label
                text: root.formatRemaining()
                color: Shared.Palette.inkDark
                font.family: Shared.Palette.fontSerif
                font.weight: Font.DemiBold
                font.pixelSize: 22
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14

                Text {
                    id: startBtn
                    text: root.running ? "pause" : "start"
                    color: startMouse.containsMouse ? Shared.Palette.wax : Shared.Palette.burgundy
                    font.family: Shared.Palette.fontAccent
                    font.pixelSize: 14
                    MouseArea {
                        id: startMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.running ? root.pause() : root.start()
                    }
                }
                Text {
                    text: "·"
                    color: Shared.Palette.inkMedium
                    font.family: Shared.Palette.fontAccent
                    font.pixelSize: 14
                }
                Text {
                    id: resetBtn
                    text: "reset"
                    color: resetMouse.containsMouse ? Shared.Palette.wax : Shared.Palette.burgundy
                    font.family: Shared.Palette.fontAccent
                    font.pixelSize: 14
                    MouseArea {
                        id: resetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.reset()
                    }
                }
            }
        }
    }
}
