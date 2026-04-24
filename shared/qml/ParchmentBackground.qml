// Parchment panel: base color + faint SVG turbulence noise overlay +
// optional foxing spots. Drop into any plasmoid's fullRepresentation.
// Palette is accessible unprefixed (same-module singleton).
import QtQuick

Rectangle {
    id: root
    property real cornerRadius: 4
    property bool showFoxing: true
    property real noiseOpacity: 0.06

    color: Palette.parchment
    radius: cornerRadius
    antialiasing: true
    clip: true
    border.color: Palette.gilt
    border.width: 0
    // Shadow — a second rect layered behind, at a slight y-offset,
    // in paperShadow. Parent must clip false; we rely on layering from
    // outside instead of from here. Callers who want shadow wrap this.

    // --- Noise overlay (inline SVG turbulence) --------------------------
    Image {
        id: noise
        anchors.fill: parent
        opacity: root.noiseOpacity
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

    // --- Foxing spots — three soft ellipses, very low opacity -----------
    Repeater {
        model: root.showFoxing ? 3 : 0
        Rectangle {
            parent: root
            property real spotSize: 14 + (index * 9) % 18
            width: spotSize
            height: spotSize
            radius: spotSize / 2
            color: Palette.foxing
            opacity: 0.10
            x: (index === 0 ? 0.12 : index === 1 ? 0.78 : 0.55) * root.width
            y: (index === 0 ? 0.82 : index === 1 ? 0.22 : 0.48) * root.height
            antialiasing: true
            visible: root.width > 120 && root.height > 80
        }
    }
}
