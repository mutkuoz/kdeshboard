import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "shared" as Shared

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property int    refreshMs:          Plasmoid.configuration.refreshMs
    property string pingTarget:         Plasmoid.configuration.pingTarget
    property string netInterfaceFilter: Plasmoid.configuration.netInterfaceFilter
    property bool   showGpu:            Plasmoid.configuration.showGpu
    property bool   showPing:           Plasmoid.configuration.showPing

    // Metrics. -1 means "not available".
    property real batPct:    -1
    property string batState: ""
    property real cpuPct:    -1
    property real cpuTemp:   -1
    property real memPct:    -1
    property real diskPct:   -1
    property real gpuPct:    -1
    property real gpuTemp:   -1
    property real netRxKBs:  -1
    property real netTxKBs:  -1
    property real pingMs:    -1

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            const stdout = data["stdout"] || ""
            // Only one command, only one possible reply.
            parseReport(stdout)
            disconnectSource(sourceName)
        }
        function exec(cmd) { if (cmd) connectSource(cmd) }
    }

    function parseReport(raw) {
        const lines = raw.split("\n")
        const vals = {}
        for (const line of lines) {
            const eq = line.indexOf("=")
            if (eq > 0) vals[line.slice(0, eq)] = line.slice(eq + 1)
        }
        function num(key) {
            const v = parseFloat(vals[key])
            return isNaN(v) ? -1 : v
        }
        batPct    = num("BAT")
        batState  = vals["BAT_STATE"] || ""
        cpuPct    = num("CPU")
        cpuTemp   = num("CPU_TEMP")
        memPct    = num("MEM")
        diskPct   = num("DISK")
        gpuPct    = num("GPU")
        gpuTemp   = num("GPU_TEMP")
        netRxKBs  = num("NET_RX")
        netTxKBs  = num("NET_TX")
        pingMs    = num("PING")
    }

    function buildCommand() {
        // Interface filter: user-supplied name or default regex.
        const iface = netInterfaceFilter
            ? "^[[:space:]]*" + netInterfaceFilter.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ":"
            : "^[[:space:]]*(eth|wlan|enp|wlp|eno|ens|wlo)"
        const ping = showPing && pingTarget ? pingTarget.replace(/[^0-9A-Za-z.:-]/g, "") : ""
        // Single multi-line snapshot. Samples /proc/stat and /proc/net/dev twice with 500ms
        // interval to compute CPU% and net speed deltas within one invocation.
        return 'bash -c \'' +
            'read _ u1 n1 s1 i1 rest < /proc/stat; ' +
            'NET1=$(awk "/' + iface + '/ {r+=\\$2; t+=\\$10} END {printf(\\"%d %d\\", r, t)}" /proc/net/dev); ' +
            'sleep 0.5; ' +
            'read _ u2 n2 s2 i2 rest < /proc/stat; ' +
            'NET2=$(awk "/' + iface + '/ {r+=\\$2; t+=\\$10} END {printf(\\"%d %d\\", r, t)}" /proc/net/dev); ' +
            'idle=$((i2-i1)); total=$(((u2-u1)+(n2-n1)+(s2-s1)+idle)); ' +
            'cpu=$(( total>0 ? 100-100*idle/total : 0 )); ' +
            'read rx1 tx1 <<< "$NET1"; read rx2 tx2 <<< "$NET2"; ' +
            'rxkbs=$(( (rx2-rx1)*2/1024 )); txkbs=$(( (tx2-tx1)*2/1024 )); ' +
            'bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1); ' +
            'bs=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1); ' +
            'mem=$(free | awk "/^Mem:/ {printf(\\"%d\\", (\\$3/\\$2)*100)}"); ' +
            'disk=$(df -P / 2>/dev/null | awk "NR==2 {gsub(\\"%\\",\\"\\",\\$5); print \\$5}"); ' +
            'ctemp=$(for z in /sys/class/thermal/thermal_zone*/temp; do cat "$z" 2>/dev/null; done | sort -nr | head -n1); ' +
            '[ -n "$ctemp" ] && ctemp=$((ctemp/1000)) || ctemp=-1; ' +
            'gpu=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1); ' +
            '[ -z "$gpu" ] && gpu=-1; ' +
            'gtemp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1); ' +
            '[ -z "$gtemp" ] && gtemp=-1; ' +
            (ping
                ? 'p=$(ping -c 1 -W 1 ' + ping + ' 2>/dev/null | awk -F"/" "/^rtt/ {printf(\\"%d\\", \\$5)}"); ' +
                  '[ -z "$p" ] && p=-1; '
                : 'p=-1; ') +
            'echo "CPU=$cpu"; echo "CPU_TEMP=$ctemp"; echo "MEM=${mem:--1}"; ' +
            'echo "DISK=${disk:--1}"; echo "GPU=$gpu"; echo "GPU_TEMP=$gtemp"; ' +
            'echo "BAT=${bat:--1}"; echo "BAT_STATE=${bs:-unknown}"; ' +
            'echo "NET_RX=$rxkbs"; echo "NET_TX=$txkbs"; echo "PING=$p"' +
            '\''
    }

    Timer {
        interval: root.refreshMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: executable.exec(buildCommand())
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 340
        Layout.preferredHeight: 260
        Layout.minimumWidth: 280
        Layout.minimumHeight: 200

        Shared.ParchmentBackground {
            anchors.fill: parent
            alpha:     Plasmoid.configuration.backgroundOpacity
            edgeStyle: Plasmoid.configuration.edgeStyle
        }
        Loader { sourceComponent: Shared.Ornaments.PageCorner; anchors.top: parent.top; anchors.right: parent.right }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text {
                text: "INSTRUMENTATION"
                color: Shared.Palette.burgundy
                font.family: Shared.Palette.fontSmallCaps
                font.pixelSize: 14
                font.letterSpacing: 2.0
                Layout.leftMargin: 6
            }
            Loader { sourceComponent: Shared.Ornaments.DoubleRule; Layout.fillWidth: true }

            GridLayout {
                columns: 3
                rowSpacing: 2
                columnSpacing: 4
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignCenter

                Gauge { value: root.cpuPct;  maxValue: 100;  unit: "%";  label: "cpu";       ringColor: Shared.Palette.burgundy }
                Gauge { value: root.cpuTemp; maxValue: 100;  unit: "°C"; label: "cpu temp";  ringColor: Shared.Palette.wax; warnThreshold: 75 }
                Gauge { value: root.memPct;  maxValue: 100;  unit: "%";  label: "memory";    ringColor: Shared.Palette.burgundy }

                Gauge {
                    value: root.showGpu ? root.gpuPct : -1
                    maxValue: 100; unit: "%"; label: "gpu"
                    ringColor: Shared.Palette.burgundy
                }
                Gauge {
                    value: root.showGpu ? root.gpuTemp : -1
                    maxValue: 100; unit: "°C"; label: "gpu temp"
                    ringColor: Shared.Palette.wax; warnThreshold: 80
                }
                Gauge {
                    value: root.diskPct; maxValue: 100; unit: "%"; label: "disk"
                    ringColor: Shared.Palette.burgundy; warnThreshold: 85
                }

                Gauge {
                    value: root.batPct; maxValue: 100; unit: "%"
                    label: root.batState ? root.batState.toLowerCase() : "battery"
                    ringColor: root.batState === "Charging" ? Shared.Palette.burgundy : Shared.Palette.wax
                    warnThreshold: 20
                    invertWarning: true
                }

                // Composite Network cell (rx + tx)
                Item {
                    implicitWidth: 78
                    implicitHeight: 82
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 10
                            spacing: 2
                            Text { text: "↓"; color: Shared.Palette.burgundy; font.family: Shared.Palette.fontSerif; font.pixelSize: 14 }
                            Text {
                                text: root.netRxKBs >= 0 ? formatKB(root.netRxKBs) : "—"
                                color: Shared.Palette.inkDark
                                font.family: Shared.Palette.fontSerif
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 2
                            Text { text: "↑"; color: Shared.Palette.wax; font.family: Shared.Palette.fontSerif; font.pixelSize: 14 }
                            Text {
                                text: root.netTxKBs >= 0 ? formatKB(root.netTxKBs) : "—"
                                color: Shared.Palette.inkDark
                                font.family: Shared.Palette.fontSerif
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                        }
                        Text {
                            text: "kb/s · net"
                            Layout.alignment: Qt.AlignHCenter
                            color: Shared.Palette.inkMedium
                            font.family: Shared.Palette.fontSmallCaps
                            font.pixelSize: 12
                            font.letterSpacing: 1.2
                        }
                    }
                }

                Gauge {
                    value: root.showPing ? root.pingMs : -1
                    maxValue: 200; unit: "ms"; label: "ping"
                    ringColor: Shared.Palette.wax; warnThreshold: 60
                }
            }
        }
    }

    function formatKB(kb) {
        if (kb >= 1024) return (kb / 1024).toFixed(1) + "m"
        return Math.round(kb).toString()
    }
}
