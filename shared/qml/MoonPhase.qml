// MoonPhase: computes current phase index (0..7) and draws it with QtQuick.Shapes.
// 0=new, 1=waxing crescent, 2=first quarter, 3=waxing gibbous,
// 4=full, 5=waning gibbous, 6=third quarter, 7=waning crescent.
// Palette is accessible unprefixed (same-module singleton).
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property real size: 28
    property color ink: Palette.inkDark
    property int phase: currentPhase()
    implicitWidth: size
    implicitHeight: size

    function currentPhase() {
        const now = new Date()
        const julian = now.getTime() / 86400000 + 2440587.5
        const age = ((julian - 2451549.5) % 29.53059 + 29.53059) % 29.53059
        return Math.floor((age / 29.53059) * 8) % 8
    }

    // Recompute at midnight via a timer.
    Timer {
        interval: 60 * 60 * 1000  // 1h; cheap enough to just check hourly
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.phase = root.currentPhase()
    }

    Shape {
        anchors.fill: parent
        antialiasing: true

        // Full moon disk as base outline
        ShapePath {
            strokeColor: root.ink
            strokeWidth: 1
            fillColor: "transparent"
            startX: root.size / 2; startY: 0
            PathArc {
                x: root.size / 2; y: root.size
                radiusX: root.size / 2; radiusY: root.size / 2
                direction: PathArc.Clockwise
            }
            PathArc {
                x: root.size / 2; y: 0
                radiusX: root.size / 2; radiusY: root.size / 2
                direction: PathArc.Clockwise
            }
        }

        // Phase fill — a filled shape whose geometry depends on `phase`.
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: root.phase === 0 ? "transparent" : root.ink
            startX: root.size / 2; startY: 0
            // Right half
            PathArc {
                x: root.size / 2; y: root.size
                radiusX: root.size / 2; radiusY: root.size / 2
                direction: (root.phase >= 1 && root.phase <= 3) || root.phase === 4
                           ? PathArc.Clockwise
                           : PathArc.Counterclockwise
            }
            // Terminator (inner arc) — ellipse with radiusX proportional to phase offset from full
            // Map: 0->full-dark-side radius=R, 1->3R/4, 2->R/2, 3->R/4, 4->0 (full), 5->R/4, 6->R/2, 7->3R/4
            PathArc {
                x: root.size / 2; y: 0
                radiusX: {
                    const r = root.size / 2
                    const offsets = [r, 3*r/4, r/2, r/4, 0, r/4, r/2, 3*r/4]
                    return offsets[root.phase]
                }
                radiusY: root.size / 2
                direction: (root.phase >= 1 && root.phase <= 3)
                           ? PathArc.Counterclockwise
                           : PathArc.Clockwise
            }
        }
    }
}
