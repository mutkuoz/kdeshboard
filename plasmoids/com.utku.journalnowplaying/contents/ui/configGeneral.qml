import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_preferredPlayer: playerField.text
    property alias cfg_showAlbumArt:    artBox.checked

    TextField {
        id: playerField
        Kirigami.FormData.label: "Preferred player:"
        placeholderText: "e.g. spotify; empty = auto"
    }
    CheckBox {
        id: artBox
        Kirigami.FormData.label: "Show album art:"
    }
}
