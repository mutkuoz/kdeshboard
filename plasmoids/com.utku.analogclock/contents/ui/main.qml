import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "shared" as Shared

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property string mode:             Plasmoid.configuration.mode        // "seal" | "stamp"
    property bool   showSeconds:      Plasmoid.configuration.showSeconds
    property bool   useRomanNumerals: Plasmoid.configuration.useRomanNumerals
    property string stampLabel:       Plasmoid.configuration.stampLabel

    property date currentTime: new Date()
    Timer {
        interval: root.showSeconds ? 1000 : 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.currentTime = new Date()
    }

    readonly property var romans: ["XII","I","II","III","IV","V","VI","VII","VIII","IX","X","XI"]
    readonly property var arabic: ["12","1","2","3","4","5","6","7","8","9","10","11"]

    fullRepresentation: Item {
        Layout.preferredWidth: 200
        Layout.preferredHeight: 200
        Layout.minimumWidth: 140
        Layout.minimumHeight: 140

        // ========= WAX SEAL MODE =========
        Item {
            anchors.fill: parent
            anchors.margins: 6
            visible: root.mode === "seal"

            Rectangle {
                id: sealBody
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width
                radius: width / 2
                color: Shared.Palette.wax
                antialiasing: true
                border.color: Shared.Palette.gilt
                border.width: Math.max(2, width / 60)

                // inner gilt ring
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.94
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.color: Shared.Palette.gilt
                    border.width: 1
                    opacity: 0.6
                    antialiasing: true
                }

                // subtle wax texture via foxing-style spots
                Repeater {
                    model: 5
                    Rectangle {
                        parent: sealBody
                        property real s: 6 + (index * 11) % 14
                        width: s; height: s; radius: s / 2
                        color: Qt.darker(Shared.Palette.wax, 1.08)
                        opacity: 0.35
                        antialiasing: true
                        x: sealBody.width / 2 + Math.cos(index * 1.7) * sealBody.width * 0.28 - s/2
                        y: sealBody.height / 2 + Math.sin(index * 1.7) * sealBody.height * 0.28 - s/2
                    }
                }

                ClockFace {
                    anchors.fill: parent
                    anchors.margins: parent.width * 0.10
                    numeralColor: Shared.Palette.gilt
                    tickColor:    Shared.Palette.gilt
                    hourHandColor:   Shared.Palette.parchment
                    minuteHandColor: Shared.Palette.parchment
                    secondHandColor: Shared.Palette.gilt
                    centerColor:     Shared.Palette.gilt
                    showSeconds:     root.showSeconds
                    useRomanNumerals: root.useRomanNumerals
                    currentTime:     root.currentTime
                }
            }
        }

        // ========= LETTER STAMP MODE =========
        Item {
            anchors.fill: parent
            anchors.margins: 6
            visible: root.mode === "stamp"

            // Perforated postage-stamp frame
            Item {
                id: stampFrame
                anchors.fill: parent

                // Cream base
                Rectangle {
                    id: stampBase
                    anchors.fill: parent
                    anchors.margins: 4
                    color: Qt.rgba(Shared.Palette.parchment.r, Shared.Palette.parchment.g, Shared.Palette.parchment.b, 1)
                    border.color: Shared.Palette.gilt
                    border.width: 1
                    antialiasing: true
                }

                // Inner burgundy frame
                Rectangle {
                    anchors.fill: stampBase
                    anchors.margins: 6
                    color: "transparent"
                    border.color: Shared.Palette.burgundy
                    border.width: 1
                    opacity: 0.8
                    antialiasing: true
                }

                // Perforation dots (matching ParchmentBackground "stamped" style)
                Item {
                    anchors.fill: parent
                    readonly property int hCount: Math.max(10, Math.floor(width / 16))
                    readonly property int vCount: Math.max(8, Math.floor(height / 16))
                    Repeater {
                        model: parent.hCount
                        Rectangle {
                            width: 5; height: 5; radius: 2.5
                            color: Shared.Palette.parchment
                            x: (index / parent.hCount) * stampFrame.width - 2.5
                            y: -2
                        }
                    }
                    Repeater {
                        model: parent.hCount
                        Rectangle {
                            width: 5; height: 5; radius: 2.5
                            color: Shared.Palette.parchment
                            x: (index / parent.hCount) * stampFrame.width - 2.5
                            y: stampFrame.height - 2.5
                        }
                    }
                    Repeater {
                        model: parent.vCount
                        Rectangle {
                            width: 5; height: 5; radius: 2.5
                            color: Shared.Palette.parchment
                            y: (index / parent.vCount) * stampFrame.height - 2.5
                            x: -2
                        }
                    }
                    Repeater {
                        model: parent.vCount
                        Rectangle {
                            width: 5; height: 5; radius: 2.5
                            color: Shared.Palette.parchment
                            y: (index / parent.vCount) * stampFrame.height - 2.5
                            x: stampFrame.width - 2.5
                        }
                    }
                }

                // Cancellation rings — faint arcs like a postmark
                Canvas {
                    anchors.fill: stampBase
                    opacity: 0.18
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        ctx.strokeStyle = Shared.Palette.inkDark
                        ctx.lineWidth = 1
                        for (let i = 0; i < 3; i++) {
                            ctx.beginPath()
                            ctx.arc(width * 0.22, height * 0.24, width * (0.11 + i * 0.04), 0, 2 * Math.PI)
                            ctx.stroke()
                        }
                    }
                }

                // Caption bottom
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    text: root.stampLabel
                    color: Shared.Palette.burgundy
                    font.family: Shared.Palette.fontSmallCaps
                    font.pixelSize: 9
                    font.letterSpacing: 1.6
                }

                ClockFace {
                    anchors.centerIn: stampBase
                    width: Math.min(stampBase.width, stampBase.height) * 0.78
                    height: width
                    numeralColor: Shared.Palette.inkDark
                    tickColor:    Shared.Palette.inkMedium
                    hourHandColor:   Shared.Palette.inkDark
                    minuteHandColor: Shared.Palette.inkDark
                    secondHandColor: Shared.Palette.burgundy
                    centerColor:     Shared.Palette.burgundy
                    showSeconds:     root.showSeconds
                    useRomanNumerals: root.useRomanNumerals
                    currentTime:     root.currentTime
                }
            }
        }
    }

    component ClockFace: Item {
        id: face
        property color numeralColor: Shared.Palette.inkDark
        property color tickColor:    Shared.Palette.inkMedium
        property color hourHandColor:   Shared.Palette.inkDark
        property color minuteHandColor: Shared.Palette.inkDark
        property color secondHandColor: Shared.Palette.burgundy
        property color centerColor:     Shared.Palette.burgundy
        property bool  showSeconds:      true
        property bool  useRomanNumerals: true
        property var   currentTime: new Date()

        Canvas {
            id: dial
            anchors.fill: parent
            antialiasing: true

            function drawHand(ctx, cx, cy, angle, length, width, color) {
                ctx.save()
                ctx.translate(cx, cy)
                ctx.rotate(angle)
                ctx.strokeStyle = color
                ctx.lineWidth   = width
                ctx.lineCap     = "round"
                ctx.beginPath()
                ctx.moveTo(0, 6)
                ctx.lineTo(0, -length)
                ctx.stroke()
                ctx.restore()
            }

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const cx = width / 2
                const cy = height / 2
                const r  = Math.min(cx, cy)

                // Tick marks
                for (let i = 0; i < 60; i++) {
                    const a = i * Math.PI / 30
                    const isHour = i % 5 === 0
                    const inner = r * (isHour ? 0.82 : 0.88)
                    const outer = r * 0.94
                    ctx.strokeStyle = face.tickColor
                    ctx.lineWidth = isHour ? 1.2 : 0.6
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.sin(a) * inner, cy - Math.cos(a) * inner)
                    ctx.lineTo(cx + Math.sin(a) * outer, cy - Math.cos(a) * outer)
                    ctx.stroke()
                }

                // Numerals
                ctx.fillStyle = face.numeralColor
                ctx.textAlign    = "center"
                ctx.textBaseline = "middle"
                const fontSize = Math.max(9, r * 0.16)
                ctx.font = fontSize + "px 'Cormorant Garamond'"
                const labels = face.useRomanNumerals ? root.romans : root.arabic
                for (let i = 0; i < 12; i++) {
                    const a = i * Math.PI / 6
                    const x = cx + Math.sin(a) * r * 0.70
                    const y = cy - Math.cos(a) * r * 0.70
                    ctx.fillText(labels[i], x, y)
                }

                // Hands
                const t = face.currentTime
                const s = t.getSeconds() + t.getMilliseconds() / 1000
                const m = t.getMinutes() + s / 60
                const h = (t.getHours() % 12) + m / 60

                const hourAngle   = h * Math.PI / 6
                const minuteAngle = m * Math.PI / 30
                const secondAngle = s * Math.PI / 30

                drawHand(ctx, cx, cy, hourAngle,   r * 0.52, 3,   face.hourHandColor)
                drawHand(ctx, cx, cy, minuteAngle, r * 0.72, 2,   face.minuteHandColor)
                if (face.showSeconds)
                    drawHand(ctx, cx, cy, secondAngle, r * 0.82, 1, face.secondHandColor)

                // Center pin
                ctx.fillStyle = face.centerColor
                ctx.beginPath()
                ctx.arc(cx, cy, Math.max(2.5, r * 0.035), 0, 2 * Math.PI)
                ctx.fill()
            }
            Connections {
                target: face
                function onCurrentTimeChanged()      { dial.requestPaint() }
                function onUseRomanNumeralsChanged() { dial.requestPaint() }
                function onShowSecondsChanged()      { dial.requestPaint() }
            }
            onWidthChanged:  requestPaint()
            onHeightChanged: requestPaint()
        }
    }
}
