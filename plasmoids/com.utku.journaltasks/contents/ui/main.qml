import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "shared" as Shared

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property string filePath: Plasmoid.configuration.filePath
    property bool   showCompleted: Plasmoid.configuration.showCompleted
    property string sectionFilter: Plasmoid.configuration.sectionFilter
    property int    refreshMs: Plasmoid.configuration.refreshMs
    property string fileContent: ""
    property int    lastMtime: 0

    ListModel { id: entries }

    function expandPath(p) {
        if (p.startsWith("~/"))
            return executable.homeDir + "/" + p.slice(2)
        return p
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        property string homeDir: ""

        onNewData: function(sourceName, data) {
            const stdout = (data["stdout"] || "").replace(/\n$/, "")
            const exitCode = data["exit code"]
            if (sourceName.indexOf("echo $HOME") !== -1) {
                homeDir = stdout
            } else if (sourceName.indexOf("stat -c") !== -1) {
                const mtime = parseInt(stdout, 10) || 0
                if (mtime !== root.lastMtime) {
                    root.lastMtime = mtime
                    executable.exec("cat " + quote(root.expandPath(root.filePath)))
                }
            } else if (sourceName.startsWith("cat ")) {
                if (exitCode === 0) {
                    root.fileContent = stdout
                    rebuildModel()
                } else {
                    entries.clear()
                    entries.append({ kind: "error", text: "— the page is blank. —" })
                }
            }
            disconnectSource(sourceName)
        }
        function exec(cmd) { if (cmd) connectSource(cmd) }
    }

    function quote(s) { return "'" + s.replace(/'/g, "'\\''") + "'" }

    function rebuildModel() {
        entries.clear()
        const lines = root.fileContent.split("\n")
        const filters = root.sectionFilter
            .split(",").map(s => s.trim().toLowerCase()).filter(s => s.length > 0)
        let inFilteredSection = (filters.length === 0)

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            const headerMatch = line.match(/^(#{1,3})\s+(.+)$/)
            if (headerMatch) {
                const title = headerMatch[2]
                inFilteredSection = (filters.length === 0) ||
                    filters.includes(title.toLowerCase())
                if (inFilteredSection)
                    entries.append({ kind: "header", text: title, indent: 0, lineIndex: i, checked: false })
                continue
            }
            if (!inFilteredSection) continue

            const taskMatch = line.match(/^(\s*)- \[( |x|X)\]\s+(.*)$/)
            if (taskMatch) {
                const depth = Math.floor(taskMatch[1].length / 2)
                const done = taskMatch[2].toLowerCase() === "x"
                if (!done || root.showCompleted)
                    entries.append({ kind: "task", text: taskMatch[3], indent: depth,
                                     lineIndex: i, checked: done })
                continue
            }
            if (line.trim().length > 0)
                entries.append({ kind: "body", text: line, indent: 0, lineIndex: i, checked: false })
        }
    }

    function toggleLine(lineIndex, newChecked) {
        const lines = root.fileContent.split("\n")
        const line = lines[lineIndex]
        const replaced = line.replace(/^(\s*- \[)( |x|X)(\]\s+.*)$/,
            (_, pre, _old, post) => pre + (newChecked ? "x" : " ") + post)
        lines[lineIndex] = replaced
        const newContent = lines.join("\n")
        root.fileContent = newContent
        const expanded = root.expandPath(root.filePath)
        executable.exec("printf '%s' " + quote(newContent) + " > " + quote(expanded))
        rebuildModel()
    }

    function appendTask(body) {
        if (!body.trim()) return
        const lines = root.fileContent.split("\n")
        let insertAt = lines.length
        // Find last section header (top-level) and insert after its items.
        let lastHeader = -1
        for (let i = 0; i < lines.length; i++)
            if (/^#{1,3}\s/.test(lines[i])) lastHeader = i
        if (lastHeader >= 0) {
            let j = lastHeader + 1
            while (j < lines.length && !/^#{1,3}\s/.test(lines[j])) j++
            insertAt = j
        }
        const newLine = "- [ ] " + body.trim()
        lines.splice(insertAt, 0, newLine)
        const newContent = lines.join("\n").replace(/\n*$/, "\n")
        root.fileContent = newContent
        executable.exec("printf '%s' " + quote(newContent) + " > " + quote(root.expandPath(root.filePath)))
        rebuildModel()
    }

    Timer {
        interval: root.refreshMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!executable.homeDir) {
                executable.exec("echo $HOME")
            } else {
                executable.exec("stat -c %Y " + quote(root.expandPath(root.filePath)))
            }
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 420
        Layout.preferredHeight: 360
        Layout.minimumWidth: 280
        Layout.minimumHeight: 180

        Shared.ParchmentBackground {
            anchors.fill: parent
            alpha:     Plasmoid.configuration.backgroundOpacity
            edgeStyle: Plasmoid.configuration.edgeStyle
        }
        Loader { sourceComponent: Shared.Ornaments.PageCorner; anchors.top: parent.top; anchors.right: parent.right }

        // Gilt margin rule on the left
        Rectangle {
            x: 24
            y: 10
            width: 1
            height: parent.height - 20
            color: Shared.Palette.gilt
            opacity: 0.40
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 4

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: listView
                    model: entries
                    spacing: 2
                    delegate: Item {
                        width: listView.width
                        implicitHeight: loader.item ? loader.item.implicitHeight : 0

                        Loader {
                            id: loader
                            width: parent.width
                            sourceComponent: {
                                if (model.kind === "header") return headerCmp
                                if (model.kind === "task")   return taskCmp
                                if (model.kind === "body")   return bodyCmp
                                return errorCmp
                            }
                        }

                        Component {
                            id: headerCmp
                            Column {
                                spacing: 2
                                Text {
                                    text: model.text.toUpperCase()
                                    color: Shared.Palette.burgundy
                                    font.family: Shared.Palette.fontSmallCaps
                                    font.pixelSize: 13
                                    font.letterSpacing: 1.4
                                    leftPadding: 24
                                    topPadding: 8
                                }
                                Loader {
                                    sourceComponent: Shared.Ornaments.DoubleRule
                                    width: parent.width - 24
                                    x: 24
                                }
                            }
                        }
                        Component {
                            id: taskCmp
                            TaskItem {
                                checked: model.checked
                                body: model.text
                                indent: model.indent
                                onToggled: root.toggleLine(model.lineIndex, !model.checked)
                            }
                        }
                        Component {
                            id: bodyCmp
                            Text {
                                text: model.text
                                color: Shared.Palette.inkMedium
                                font.family: Shared.Palette.fontSerif
                                font.pixelSize: 13
                                font.italic: true
                                leftPadding: 24
                                wrapMode: Text.WordWrap
                            }
                        }
                        Component {
                            id: errorCmp
                            Text {
                                text: model.text
                                color: Shared.Palette.inkMedium
                                font.family: Shared.Palette.fontAccent
                                font.pixelSize: 14
                                leftPadding: 24
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                spacing: 6

                Text {
                    text: "❧"
                    color: Shared.Palette.gilt
                    font.family: Shared.Palette.fontSerif
                    font.pixelSize: 14
                }
                TextField {
                    id: addField
                    Layout.fillWidth: true
                    placeholderText: "a new entry…"
                    font.family: Shared.Palette.fontAccent
                    font.pixelSize: 14
                    color: Shared.Palette.inkDark
                    background: null
                    onAccepted: {
                        root.appendTask(text)
                        text = ""
                    }
                }
            }
        }
    }
}
