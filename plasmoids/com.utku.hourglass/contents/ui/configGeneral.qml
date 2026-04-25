import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_durationMinutes:   durSpin.value
    property alias cfg_completionCommand: cmdField.text
    property alias cfg_autoRepeat:        repeatBox.checked
    property alias cfg_backgroundOpacity: opacitySlider.value
    property alias cfg_edgeStyle:         edgeCombo.selectedValue

    SpinBox {
        id: durSpin
        Kirigami.FormData.label: "Duration (minutes):"
        from: 1
        to: 720
    }
    TextField {
        id: cmdField
        Kirigami.FormData.label: "On completion:"
        placeholderText: "e.g. paplay /usr/share/sounds/freedesktop/stereo/complete.oga"
    }
    CheckBox {
        id: repeatBox
        Kirigami.FormData.label: "Auto-repeat when done:"
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
