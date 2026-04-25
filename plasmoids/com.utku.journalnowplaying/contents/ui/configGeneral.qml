import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_preferredPlayer:   playerField.text
    property alias cfg_showAlbumArt:      artBox.checked
    property alias cfg_backgroundOpacity: opacitySlider.value
    property alias cfg_textScale:         textScaleSlider.value
    property alias cfg_edgeStyle:         edgeCombo.selectedValue

    TextField {
        id: playerField
        Kirigami.FormData.label: "Preferred player:"
        placeholderText: "e.g. spotify; empty = auto"
    }
    CheckBox {
        id: artBox
        Kirigami.FormData.label: "Show album art:"
    }
    RowLayout {
        Kirigami.FormData.label: "Text size:"
        Layout.preferredWidth: 280
        Slider {
            id: textScaleSlider
            from: 0.7
            to: 2.0
            stepSize: 0.05
            Layout.fillWidth: true
            Layout.preferredWidth: 200
        }
        Label {
            text: Math.round(textScaleSlider.value * 100) + "%"
            Layout.preferredWidth: 36
        }
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
