import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_filePath:          pathField.text
    property alias cfg_showCompleted:     showCompletedBox.checked
    property alias cfg_sectionFilter:     filterField.text
    property alias cfg_refreshMs:         refreshSpin.value
    property alias cfg_backgroundOpacity: opacitySlider.value
    property alias cfg_edgeStyle:         edgeCombo.selectedValue

    TextField {
        id: pathField
        Kirigami.FormData.label: "Tasks file:"
        placeholderText: "~/notes/tasks.md"
    }
    CheckBox {
        id: showCompletedBox
        Kirigami.FormData.label: "Show completed:"
    }
    TextField {
        id: filterField
        Kirigami.FormData.label: "Section filter (comma-separated):"
        placeholderText: "empty = show all"
    }
    SpinBox {
        id: refreshSpin
        Kirigami.FormData.label: "Refresh (ms):"
        from: 500
        to: 60000
        stepSize: 500
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
}
