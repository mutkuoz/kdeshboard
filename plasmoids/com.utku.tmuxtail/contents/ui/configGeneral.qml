import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_tmuxTarget:    targetField.text
    property alias cfg_lineCount:     linesSpin.value
    property alias cfg_refreshMs:     refreshSpin.value
    property alias cfg_attachCommand: attachField.text

    TextField {
        id: targetField
        Kirigami.FormData.label: "tmux target:"
        placeholderText: "session:window[.pane]"
    }
    SpinBox {
        id: linesSpin
        Kirigami.FormData.label: "Lines to capture:"
        from: 1
        to: 200
    }
    SpinBox {
        id: refreshSpin
        Kirigami.FormData.label: "Refresh (ms):"
        from: 500
        to: 60000
        stepSize: 500
    }
    TextField {
        id: attachField
        Kirigami.FormData.label: "On double-click:"
        placeholderText: "konsole -e tmux attach -t <session>"
    }
}
