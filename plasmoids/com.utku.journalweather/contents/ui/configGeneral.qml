import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_cityName:       cityField.text
    property alias cfg_refreshMinutes: refreshSpin.value
    property alias cfg_units:          unitsField.text

    TextField {
        id: cityField
        Kirigami.FormData.label: "City:"
        placeholderText: "Istanbul"
    }
    SpinBox {
        id: refreshSpin
        Kirigami.FormData.label: "Refresh (minutes):"
        from: 5
        to: 240
    }
    TextField {
        id: unitsField
        Kirigami.FormData.label: "Units:"
        placeholderText: "metric or imperial"
    }
}
