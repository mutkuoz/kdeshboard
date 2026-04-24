import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_filePath:       pathField.text
    property alias cfg_showCompleted:  showCompletedBox.checked
    property alias cfg_sectionFilter:  filterField.text
    property alias cfg_refreshMs:      refreshSpin.value

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
}
