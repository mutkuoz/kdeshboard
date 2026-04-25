import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_itemsText:         itemsArea.text
    property alias cfg_iconSize:          iconSizeSpin.value
    property alias cfg_columns:           columnsSpin.value
    property alias cfg_showLabels:        labelsBox.checked
    property alias cfg_backgroundOpacity: opacitySlider.value
    property alias cfg_textScale:         textScaleSlider.value
    property alias cfg_edgeStyle:         edgeCombo.selectedValue

    SpinBox {
        id: iconSizeSpin
        Kirigami.FormData.label: "Icon size:"
        from: 16
        to: 96
        stepSize: 4
    }
    SpinBox {
        id: columnsSpin
        Kirigami.FormData.label: "Columns:"
        from: 1
        to: 8
    }
    CheckBox {
        id: labelsBox
        Kirigami.FormData.label: "Show labels:"
    }

    Label {
        text: "Items (one per line, pipe-separated):  label | icon | command"
        Layout.fillWidth: true
    }
    Label {
        text: "Icon names follow the freedesktop spec (e.g. utilities-terminal).\n" +
              "Run  kdialog --geticon  or browse  /usr/share/icons/  to find names."
        color: Kirigami.Theme.disabledTextColor
        wrapMode: Text.WordWrap
        font.pixelSize: 11
        Layout.fillWidth: true
    }
    ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: 200
        Layout.preferredWidth: 460
        TextArea {
            id: itemsArea
            wrapMode: TextArea.NoWrap
            font.family: "monospace"
            placeholderText: "Files|system-file-manager|dolphin"
        }
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
