import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_use24h:      use24hBox.checked
    property alias cfg_showSeconds: secondsBox.checked
    property alias cfg_locale:      localeField.text

    CheckBox {
        id: use24hBox
        Kirigami.FormData.label: "24-hour clock:"
    }
    CheckBox {
        id: secondsBox
        Kirigami.FormData.label: "Show seconds:"
    }
    TextField {
        id: localeField
        Kirigami.FormData.label: "Locale (empty = system):"
        placeholderText: "e.g. en-GB, tr-TR"
    }
}
