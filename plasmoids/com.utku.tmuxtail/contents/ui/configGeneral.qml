import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_tmuxTarget:        targetField.text
    property alias cfg_lineCount:         linesSpin.value
    property alias cfg_refreshMs:         refreshSpin.value
    property alias cfg_attachCommand:     attachField.text
    property alias cfg_backgroundOpacity: opacitySlider.value
    property alias cfg_edgeStyle:         edgeCombo.selectedValue

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
    RowLayout {
        Kirigami.FormData.label: "Background opacity:"
        Layout.preferredWidth: 280
        Slider {
            id: opacitySlider
            from: 0.10
            to: 1.00
            stepSize: 0.05
            Layout.fillWidth: true
            Layout.preferredWidth: 200
        }
        Label {
            text: Math.round(opacitySlider.value * 100) + "%"
            Layout.preferredWidth: 36
        }
    }
    ComboBox {
        id: edgeCombo
        Kirigami.FormData.label: "Edge style:"
        textRole: "text"
        valueRole: "value"
        property string selectedValue: "rounded"
        model: [
            { text: "Rounded",  value: "rounded"  },
            { text: "Ripped",   value: "ripped"   },
            { text: "Deckle",   value: "deckle"   },
            { text: "Stamped",  value: "stamped"  },
            { text: "Embossed", value: "embossed" }
        ]
        function refreshIndex() {
            const idx = model.findIndex(m => m.value === selectedValue)
            if (idx >= 0 && currentIndex !== idx) currentIndex = idx
        }
        Component.onCompleted: refreshIndex()
        onSelectedValueChanged: refreshIndex()
        onActivated: selectedValue = currentValue
    }
}
