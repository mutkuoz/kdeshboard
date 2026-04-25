import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "shared" as Shared

PlasmoidItem {
    id: root


    property real ts: (Plasmoid.configuration.textScale && Plasmoid.configuration.textScale > 0) ? Plasmoid.configuration.textScale : 1.25
    preferredRepresentation: fullRepresentation

    property string quotesFile:       Plasmoid.configuration.quotesFile
    property int    rotationMinutes:  Plasmoid.configuration.rotationMinutes
    property bool   clickToCycle:     Plasmoid.configuration.clickToCycle

    property var pool: []
    property int index: 0

    readonly property var builtinPool: [
        { q: "We are what we repeatedly do. Excellence, then, is not an act, but a habit.", a: "Aristotle (paraphrased)" },
        { q: "The unexamined life is not worth living.", a: "Socrates" },
        { q: "To improve is to change; to be perfect is to change often.", a: "Churchill" },
        { q: "It is not the critic who counts.", a: "Roosevelt" },
        { q: "Measure twice, cut once.", a: "carpenter's proverb" },
        { q: "Patience is bitter, but its fruit is sweet.", a: "Rousseau" },
        { q: "The best time to plant a tree was twenty years ago. The second best time is now.", a: "Chinese proverb" },
        { q: "Amor fati.", a: "Nietzsche" },
        { q: "A ship in harbor is safe, but that is not what ships are built for.", a: "Shedd" },
        { q: "Festina lente.", a: "Augustus — make haste, slowly" },
        { q: "Perfection is achieved, not when there is nothing more to add, but when there is nothing left to take away.", a: "Saint-Exupéry" },
        { q: "What we think, we become.", a: "Buddha (attrib.)" },
        { q: "Simplicity is the ultimate sophistication.", a: "da Vinci (attrib.)" },
        { q: "Man is the measure of all things.", a: "Protagoras" },
        { q: "Memento mori.", a: "Roman tradition" },
        { q: "Fortune favors the bold.", a: "Virgil" },
        { q: "He who has a why to live for can bear almost any how.", a: "Nietzsche" },
        { q: "There is no substitute for hard work.", a: "Edison" },
        { q: "The man who moves a mountain begins by carrying away small stones.", a: "Confucius" },
        { q: "It always seems impossible until it's done.", a: "Mandela" }
    ]

    function expandPath(p) {
        if (p.startsWith("~/")) return executable.homeDir + "/" + p.slice(2)
        return p
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        property string homeDir: ""

        onNewData: function(sourceName, data) {
            const stdout = data["stdout"] || ""
            if (sourceName.indexOf("echo $HOME") !== -1) {
                homeDir = stdout.replace(/\n$/, "")
                if (root.quotesFile) refreshFile()
            } else if (sourceName.indexOf("cat ") === 0) {
                parseQuotesText(stdout)
            }
            disconnectSource(sourceName)
        }
        function exec(cmd) { if (cmd) connectSource(cmd) }
    }

    function parseQuotesText(text) {
        const lines = text.split("\n").map(s => s.trim()).filter(s => s.length > 0 && !s.startsWith("#"))
        const parsed = []
        for (const line of lines) {
            const pipe = line.indexOf("|")
            if (pipe >= 0) {
                const q = line.slice(0, pipe).trim()
                const a = line.slice(pipe + 1).trim()
                if (q) parsed.push({ q: q, a: a })
            } else {
                parsed.push({ q: line, a: "" })
            }
        }
        if (parsed.length > 0) {
            pool = parsed
            index = index % pool.length
        } else {
            pool = builtinPool
            index = index % pool.length
        }
    }

    function refreshFile() {
        if (!quotesFile || !executable.homeDir) return
        const p = expandPath(quotesFile).replace(/'/g, "'\\''")
        executable.exec("cat '" + p + "' 2>/dev/null")
    }

    function cycle() {
        if (pool.length === 0) return
        index = (index + 1) % pool.length
    }

    Timer {
        interval: Math.max(60000, root.rotationMinutes * 60 * 1000)
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: cycle()
    }

    Component.onCompleted: {
        pool = builtinPool
        // Seed by day-of-year so different widgets drift in sync across restarts.
        const d = new Date()
        const start = new Date(d.getFullYear(), 0, 1)
        const doy = Math.floor((d - start) / 86400000)
        index = doy % builtinPool.length
        // Kick off file read if configured.
        if (quotesFile) executable.exec("echo $HOME")
    }

    onQuotesFileChanged: {
        if (!quotesFile) {
            pool = builtinPool
            index = 0
        } else if (!executable.homeDir) {
            executable.exec("echo $HOME")
        } else {
            refreshFile()
        }
    }

    fullRepresentation: Item {
        id: frame
        Layout.preferredWidth: 380
        Layout.preferredHeight: 170
        Layout.minimumWidth: 260
        Layout.minimumHeight: 120

        Shared.ParchmentBackground {
            anchors.fill: parent
            alpha:     Plasmoid.configuration.backgroundOpacity > 0 ? Plasmoid.configuration.backgroundOpacity : 1.0
            edgeStyle: Plasmoid.configuration.edgeStyle || "rounded"
        }
        Loader { sourceComponent: Shared.Ornaments.PageCorner; anchors.top: parent.top; anchors.right: parent.right }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "COMMONPLACE"
                    color: Shared.Palette.burgundy
                    font.family: Shared.Palette.fontSmallCaps
                    font.pixelSize: 14 * root.ts
                    font.letterSpacing: 2.0
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: pool.length > 0 ? (index + 1) + "/" + pool.length : ""
                    color: Shared.Palette.inkMedium
                    font.family: Shared.Palette.fontSmallCaps
                    font.pixelSize: 12 * root.ts
                    font.letterSpacing: 1.2
                }
            }
            Loader { sourceComponent: Shared.Ornaments.DoubleRule; Layout.fillWidth: true }

            Text {
                id: quoteText
                text: "“" + (pool.length > 0 ? pool[index].q : "") + "”"
                color: Shared.Palette.inkDark
                font.family: Shared.Palette.fontSerif
                font.italic: true
                font.pixelSize: 16 * root.ts
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: Text.AlignVCenter
                Layout.topMargin: 6

                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            Text {
                text: pool.length > 0 && pool[index].a ? "— " + pool[index].a : ""
                color: Shared.Palette.wax
                font.family: Shared.Palette.fontAccent
                font.pixelSize: 13 * root.ts
                horizontalAlignment: Text.AlignRight
                Layout.fillWidth: true
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.clickToCycle
            cursorShape: root.clickToCycle ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                quoteText.opacity = 0.0
                root.cycle()
                quoteText.opacity = 1.0
            }
        }
    }
}
