import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_mode:              modeCombo.selectedValue
    property alias cfg_showSeconds:       secondsBox.checked
    property alias cfg_useRomanNumerals:  romanBox.checked
    property alias cfg_stampLabel:        stampField.text

    ComboBox {
        id: modeCombo
        Kirigami.FormData.label: "Housing:"
        textRole: "text"
        valueRole: "value"
        property string selectedValue: "seal"
        model: [
            { text: "Wax seal",     value: "seal"  },
            { text: "Letter stamp", value: "stamp" }
        ]
        Component.onCompleted: {
            const idx = model.findIndex(m => m.value === selectedValue)
            currentIndex = idx >= 0 ? idx : 0
        }
        onActivated: selectedValue = currentValue
    }
    CheckBox { id: secondsBox; Kirigami.FormData.label: "Show seconds hand:" }
    CheckBox { id: romanBox;   Kirigami.FormData.label: "Roman numerals:" }
    TextField {
        id: stampField
        Kirigami.FormData.label: "Stamp caption:"
        placeholderText: "shown on postage-stamp mode"
    }
}
