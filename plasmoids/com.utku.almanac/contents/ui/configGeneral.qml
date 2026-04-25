import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_upcomingLabel:     labelField.text
    property alias cfg_upcomingDate:      dateField.text
    property alias cfg_hemisphere:        hemiCombo.selectedValue
    property alias cfg_backgroundOpacity: opacitySlider.value
    property alias cfg_edgeStyle:         edgeCombo.selectedValue

    TextField {
        id: labelField
        Kirigami.FormData.label: "Upcoming event label:"
        placeholderText: "e.g. 'my birthday'"
    }
    TextField {
        id: dateField
        Kirigami.FormData.label: "Event date (MM-DD):"
        placeholderText: "e.g. 07-14"
    }
    ComboBox {
        id: hemiCombo
        Kirigami.FormData.label: "Hemisphere:"
        textRole: "text"
        valueRole: "value"
        property string selectedValue: "north"
        model: [
            { text: "Northern", value: "north" },
            { text: "Southern", value: "south" }
        ]
        function refreshIndex() {
            const idx = model.findIndex(m => m.value === selectedValue)
            if (idx >= 0 && currentIndex !== idx) currentIndex = idx
        }
        Component.onCompleted: refreshIndex()
        onSelectedValueChanged: refreshIndex()
        onActivated: selectedValue = currentValue
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
