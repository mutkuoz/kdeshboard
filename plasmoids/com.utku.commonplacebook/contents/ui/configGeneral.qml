import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_quotesFile:        pathField.text
    property alias cfg_rotationMinutes:   rotSpin.value
    property alias cfg_clickToCycle:      clickBox.checked
    property alias cfg_backgroundOpacity: opacitySlider.value
    property alias cfg_edgeStyle:         edgeCombo.selectedValue

    TextField {
        id: pathField
        Kirigami.FormData.label: "Quotes file:"
        placeholderText: "~/notes/quotes.txt (empty = built-in)"
    }
    SpinBox {
        id: rotSpin
        Kirigami.FormData.label: "Rotation (minutes):"
        from: 1
        to: 1440
    }
    CheckBox {
        id: clickBox
        Kirigami.FormData.label: "Click to cycle:"
    }
    RowLayout {
        Kirigami.FormData.label: "Background opacity:"
        Slider {
            id: opacitySlider
            from: 0.10
            to: 1.00
            stepSize: 0.05
            Layout.fillWidth: true
        }
        Label { text: Math.round(opacitySlider.value * 100) + "%" }
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
        Component.onCompleted: {
            const idx = model.findIndex(m => m.value === selectedValue)
            currentIndex = idx >= 0 ? idx : 0
        }
        onActivated: selectedValue = currentValue
    }
    Label {
        text: "Quotes file format: one quote per line, pipe-separated:\n" +
              "    quote text | attribution"
        color: Kirigami.Theme.disabledTextColor
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
