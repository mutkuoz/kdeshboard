import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "shared" as Shared

PlasmoidItem {
    id: root


    property real ts: (Plasmoid.configuration.textScale && Plasmoid.configuration.textScale > 0) ? Plasmoid.configuration.textScale : 1.25
    preferredRepresentation: fullRepresentation

    property string mode:             Plasmoid.configuration.mode        // "seal" | "stamp" | "watch"
    property bool   showSeconds:      Plasmoid.configuration.showSeconds
    property bool   useRomanNumerals: Plasmoid.configuration.useRomanNumerals
    property string stampLabel:       Plasmoid.configuration.stampLabel
    property string watchBrand:       Plasmoid.configuration.watchBrand
    property string watchSubtitle:    Plasmoid.configuration.watchSubtitle

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
                    font.pixelSize: 12 * root.ts
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

        // ========= VINTAGE WATCH MODE =========
        Item {
            anchors.fill: parent
            anchors.margins: 4
            visible: root.mode === "watch"

            Item {
                id: watchCase
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width

                // Outer gilt bezel (slight gradient feel via two rings)
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.darker(Shared.Palette.gilt, 1.15)
                    antialiasing: true
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: width / 2
                    color: Shared.Palette.gilt
                    antialiasing: true
                }

                // Dial — everything is rendered on this Canvas so updates stay cheap
                Canvas {
                    id: watchDial
                    anchors.fill: parent
                    anchors.margins: 8
                    antialiasing: true

                    function moonPhase(d) {
                        const julian = d.getTime() / 86400000 + 2440587.5
                        const age = ((julian - 2451549.5) % 29.53059 + 29.53059) % 29.53059
                        return age / 29.53059   // 0..1 fraction of cycle
                    }

                    function drawDauphine(ctx, angle, tipLen, baseLen, halfW, color, outlineColor) {
                        // Elongated diamond: base at -baseLen (behind pivot), tip at +tipLen (outward).
                        // angle: 0 = up (12 o'clock), clockwise +.
                        ctx.save()
                        ctx.rotate(angle)
                        ctx.beginPath()
                        ctx.moveTo(0, -tipLen)        // tip (pointing to 12)
                        ctx.lineTo(halfW,  -tipLen * 0.18)
                        ctx.lineTo(0,  baseLen)       // tail
                        ctx.lineTo(-halfW, -tipLen * 0.18)
                        ctx.closePath()
                        ctx.fillStyle = color
                        ctx.fill()
                        if (outlineColor) {
                            ctx.strokeStyle = outlineColor
                            ctx.lineWidth = 0.6
                            ctx.stroke()
                        }
                        ctx.restore()
                    }

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        const cx = width / 2
                        const cy = height / 2
                        const r  = Math.min(cx, cy)

                        // Dial face — cream with a subtle radial highlight.
                        const grad = ctx.createRadialGradient(cx, cy - r * 0.25, r * 0.1, cx, cy, r)
                        grad.addColorStop(0, Qt.lighter(Shared.Palette.parchment, 1.08))
                        grad.addColorStop(1, Shared.Palette.parchment)
                        ctx.fillStyle = grad
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                        ctx.fill()

                        // Inner hairline ring (ink)
                        ctx.strokeStyle = Shared.Palette.inkDark
                        ctx.lineWidth = 0.6
                        ctx.globalAlpha = 0.5
                        ctx.beginPath()
                        ctx.arc(cx, cy, r * 0.92, 0, 2 * Math.PI)
                        ctx.stroke()
                        ctx.globalAlpha = 1.0

                        // Minute track — 60 tiny ink dots just inside the hairline ring
                        ctx.fillStyle = Shared.Palette.inkDark
                        for (let i = 0; i < 60; i++) {
                            const a = i * Math.PI / 30 - Math.PI / 2
                            const rx = cx + Math.cos(a) * r * 0.885
                            const ry = cy + Math.sin(a) * r * 0.885
                            const dot = i % 5 === 0 ? 1.4 : 0.7
                            ctx.beginPath()
                            ctx.arc(rx, ry, dot, 0, 2 * Math.PI)
                            ctx.fill()
                        }

                        // Applied hour batons — gilt-colored slim indices; larger at 12/3/6/9
                        for (let i = 0; i < 12; i++) {
                            const a = i * Math.PI / 6 - Math.PI / 2
                            const cardinal = i % 3 === 0
                            const len = r * (cardinal ? 0.16 : 0.11)
                            const outer = r * 0.84
                            const inner = outer - len
                            const thick = cardinal ? 2.5 : 1.4
                            ctx.strokeStyle = Qt.darker(Shared.Palette.gilt, 1.1)
                            ctx.lineCap = "round"
                            ctx.lineWidth = thick
                            ctx.beginPath()
                            ctx.moveTo(cx + Math.cos(a) * outer, cy + Math.sin(a) * outer)
                            ctx.lineTo(cx + Math.cos(a) * inner, cy + Math.sin(a) * inner)
                            ctx.stroke()
                        }

                        // Brand, just under 12
                        ctx.fillStyle = Shared.Palette.inkDark
                        ctx.textAlign    = "center"
                        ctx.textBaseline = "middle"
                        ctx.font = "600 " + Math.max(11, r * 0.11) + "px 'Cormorant SC'"
                        if (root.watchBrand) ctx.fillText(root.watchBrand, cx, cy - r * 0.42)
                        ctx.font = "italic " + Math.max(9, r * 0.09) + "px 'Cormorant Garamond'"
                        ctx.fillStyle = Shared.Palette.burgundy
                        if (root.watchSubtitle) ctx.fillText(root.watchSubtitle, cx, cy - r * 0.27)

                        // Moon-phase complication — circular aperture at ~6 o'clock.
                        const mcx = cx
                        const mcy = cy + r * 0.40
                        const mr  = r * 0.17

                        // Aperture frame
                        ctx.fillStyle = Qt.rgba(0.09, 0.10, 0.18, 1)     // navy night
                        ctx.beginPath()
                        ctx.arc(mcx, mcy, mr, 0, 2 * Math.PI)
                        ctx.fill()
                        ctx.strokeStyle = Qt.darker(Shared.Palette.gilt, 1.2)
                        ctx.lineWidth = 1
                        ctx.stroke()

                        // Starfield — six small gilt stars sprinkled in the night
                        ctx.fillStyle = Qt.rgba(Shared.Palette.gilt.r, Shared.Palette.gilt.g, Shared.Palette.gilt.b, 0.85)
                        const stars = [
                            [-0.55, -0.30], [ 0.48, -0.42], [-0.25,  0.45],
                            [ 0.60,  0.10], [ 0.15, -0.55], [-0.62,  0.18]
                        ]
                        for (const s of stars) {
                            ctx.beginPath()
                            ctx.arc(mcx + s[0] * mr, mcy + s[1] * mr, 0.7, 0, 2 * Math.PI)
                            ctx.fill()
                        }

                        // Moon disc — position slides horizontally with phase.
                        // phase 0..1 → x offset: -1 (new, hidden left) → 0 (full, centered) → +1 (new, hidden right).
                        // Aperture clips with a circular path; moon is slightly smaller than the aperture.
                        const phase = moonPhase(root.currentTime)
                        // Position on a full rotation: 0..0.5 = moon traveling right (waxing), 0.5..1 = traveling right through full to new again (waning).
                        // Translate phase to offset in [-1.5 .. 1.5], where |offset| > 1 hides the moon entirely.
                        const offset = (phase < 0.5 ? (phase * 4 - 1) : ((phase - 0.5) * 4 + 1))
                        const moonR = mr * 0.68
                        const moonX = mcx + offset * mr * 0.95
                        const moonY = mcy - mr * 0.05

                        ctx.save()
                        ctx.beginPath()
                        ctx.arc(mcx, mcy, mr - 1, 0, 2 * Math.PI)
                        ctx.clip()
                        // Moon body
                        const mGrad = ctx.createRadialGradient(moonX - moonR * 0.3, moonY - moonR * 0.3,
                                                               moonR * 0.15, moonX, moonY, moonR)
                        mGrad.addColorStop(0, Qt.lighter(Shared.Palette.parchment, 1.05))
                        mGrad.addColorStop(1, Qt.darker(Shared.Palette.parchment, 1.12))
                        ctx.fillStyle = mGrad
                        ctx.beginPath()
                        ctx.arc(moonX, moonY, moonR, 0, 2 * Math.PI)
                        ctx.fill()
                        // Three dim craters
                        ctx.fillStyle = Qt.rgba(0, 0, 0, 0.10)
                        const craters = [[-0.25, -0.15, 0.18], [0.18, 0.05, 0.12], [-0.05, 0.28, 0.10]]
                        for (const c of craters) {
                            ctx.beginPath()
                            ctx.arc(moonX + c[0] * moonR, moonY + c[1] * moonR, c[2] * moonR, 0, 2 * Math.PI)
                            ctx.fill()
                        }
                        ctx.restore()

                        // ---- Hands ----
                        const t = root.currentTime
                        const secs = t.getSeconds() + t.getMilliseconds() / 1000
                        const mins = t.getMinutes() + secs / 60
                        const hrs  = (t.getHours() % 12) + mins / 60
                        const hourAngle   = hrs  * Math.PI / 6
                        const minuteAngle = mins * Math.PI / 30
                        const secondAngle = secs * Math.PI / 30

                        ctx.save()
                        ctx.translate(cx, cy)
                        drawDauphine(ctx, hourAngle,   r * 0.52, r * 0.12, r * 0.05,
                                     Shared.Palette.inkDark, Shared.Palette.gilt)
                        drawDauphine(ctx, minuteAngle, r * 0.74, r * 0.14, r * 0.035,
                                     Shared.Palette.inkDark, Shared.Palette.gilt)
                        if (root.showSeconds) {
                            ctx.save()
                            ctx.rotate(secondAngle)
                            ctx.strokeStyle = Shared.Palette.burgundy
                            ctx.lineWidth = 1.2
                            ctx.lineCap = "round"
                            ctx.beginPath()
                            ctx.moveTo(0, r * 0.15)
                            ctx.lineTo(0, -r * 0.80)
                            ctx.stroke()
                            // Counterweight disc
                            ctx.fillStyle = Shared.Palette.burgundy
                            ctx.beginPath()
                            ctx.arc(0, r * 0.13, r * 0.032, 0, 2 * Math.PI)
                            ctx.fill()
                            ctx.restore()
                        }
                        ctx.restore()

                        // Center pin
                        ctx.fillStyle = Qt.darker(Shared.Palette.gilt, 1.1)
                        ctx.beginPath()
                        ctx.arc(cx, cy, r * 0.038, 0, 2 * Math.PI)
                        ctx.fill()
                        ctx.strokeStyle = Shared.Palette.inkDark
                        ctx.lineWidth = 0.6
                        ctx.stroke()
                    }
                    Connections {
                        target: root
                        function onCurrentTimeChanged()   { watchDial.requestPaint() }
                        function onShowSecondsChanged()   { watchDial.requestPaint() }
                        function onWatchBrandChanged()    { watchDial.requestPaint() }
                        function onWatchSubtitleChanged() { watchDial.requestPaint() }
                    }
                    onWidthChanged:  requestPaint()
                    onHeightChanged: requestPaint()
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
                const fontSize = Math.max(12, r * 0.18)
                ctx.font = "600 " + fontSize + "px 'Cormorant Garamond'"
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
