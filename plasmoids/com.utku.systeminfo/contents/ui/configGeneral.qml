import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_refreshMs:          refreshSpin.value
    property alias cfg_pingTarget:         pingField.text
    property alias cfg_netInterfaceFilter: netField.text
    property alias cfg_showGpu:            gpuBox.checked
    property alias cfg_showPing:           pingBox.checked
    property alias cfg_backgroundOpacity:  opacitySlider.value
    property alias cfg_edgeStyle:          edgeCombo.selectedValue

    SpinBox {
        id: refreshSpin
        Kirigami.FormData.label: "Refresh (ms):"
        from: 500
        to: 30000
        stepSize: 500
    }
    TextField {
        id: pingField
        Kirigami.FormData.label: "Ping target:"
        placeholderText: "1.1.1.1"
    }
    TextField {
        id: netField
        Kirigami.FormData.label: "Net interface filter:"
        placeholderText: "empty = eth*/wlan*/enp*/wlp* auto"
    }
    CheckBox { id: gpuBox;  Kirigami.FormData.label: "Show GPU gauges:" }
    CheckBox { id: pingBox; Kirigami.FormData.label: "Show ping gauge:" }

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
