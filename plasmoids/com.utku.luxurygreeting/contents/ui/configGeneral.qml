import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_userName:       userNameField.text
    property alias cfg_birthday:       birthdayField.text
    property alias cfg_phrasePoolSeed: seedSpin.value

    TextField {
        id: userNameField
        Kirigami.FormData.label: "Your name:"
    }
    TextField {
        id: birthdayField
        Kirigami.FormData.label: "Birthday (MM-DD):"
        placeholderText: "e.g. 07-14 — leave empty to disable"
    }
    SpinBox {
        id: seedSpin
        Kirigami.FormData.label: "Phrase seed:"
        from: 0
        to: 999
    }
}
