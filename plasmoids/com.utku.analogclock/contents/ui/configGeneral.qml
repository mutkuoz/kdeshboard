import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_mode:              modeCombo.selectedValue
    property alias cfg_showSeconds:       secondsBox.checked
    property alias cfg_useRomanNumerals:  romanBox.checked
    property alias cfg_stampLabel:        stampField.text
    property alias cfg_watchBrand:        brandField.text
    property alias cfg_watchSubtitle:     subtitleField.text

    ComboBox {
        id: modeCombo
        Kirigami.FormData.label: "Housing:"
        textRole: "text"
        valueRole: "value"
        property string selectedValue: "seal"
        model: [
            { text: "Wax seal",      value: "seal"  },
            { text: "Letter stamp",  value: "stamp" },
            { text: "Vintage watch", value: "watch" }
        ]
        function refreshIndex() {
            const idx = model.findIndex(m => m.value === selectedValue)
            if (idx >= 0 && currentIndex !== idx) currentIndex = idx
        }
        Component.onCompleted: refreshIndex()
        onSelectedValueChanged: refreshIndex()
        onActivated: selectedValue = currentValue
    }
    CheckBox { id: secondsBox; Kirigami.FormData.label: "Show seconds hand:" }
    CheckBox { id: romanBox;   Kirigami.FormData.label: "Roman numerals (seal/stamp):" }
    TextField {
        id: stampField
        Kirigami.FormData.label: "Stamp caption:"
        placeholderText: "shown on postage-stamp mode"
    }
    TextField {
        id: brandField
        Kirigami.FormData.label: "Watch brand:"
        placeholderText: "shown under 12 o'clock"
    }
    TextField {
        id: subtitleField
        Kirigami.FormData.label: "Watch subtitle:"
        placeholderText: "shown above 6 o'clock"
    }
}
