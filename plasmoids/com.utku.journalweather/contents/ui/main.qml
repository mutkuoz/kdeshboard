import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "shared" as Shared

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property string cityName:    Plasmoid.configuration.cityName
    property int    refreshMinutes: Plasmoid.configuration.refreshMinutes
    property string units:       Plasmoid.configuration.units

    property real   lat: 0
    property real   lon: 0
    property bool   havePosition: false
    property string line1: ""
    property string line2: ""
    property string line3: ""
    property bool   silent: false

    readonly property var windCompass: [
        "from the north","from the north-northeast","from the northeast","from the east-northeast",
        "from the east","from the east-southeast","from the southeast","from the south-southeast",
        "from the south","from the south-southwest","from the southwest","from the west-southwest",
        "from the west","from the west-northwest","from the northwest","from the north-northwest"
    ]

    readonly property var wmoCodes: ({
        0: "clear", 1: "mostly clear", 2: "a little cloud", 3: "overcast",
        45: "foggy", 48: "foggy",
        51: "a drizzle", 53: "a drizzle", 55: "a drizzle",
        56: "freezing drizzle", 57: "freezing drizzle",
        61: "rain", 63: "rain", 65: "rain",
        66: "freezing rain", 67: "freezing rain",
        71: "snow", 73: "snow", 75: "snow",
        77: "snow grains",
        80: "showers", 81: "showers", 82: "showers",
        85: "snow showers", 86: "snow showers",
        95: "a thunderstorm", 96: "a thunderstorm with hail", 99: "a thunderstorm with hail"
    })

    function windProse(speed, dirDeg) {
        const compass = windCompass[Math.round(((dirDeg % 360) / 22.5)) % 16]
        let adj
        if (speed < 2) adj = "still, no wind to speak of"
        else if (speed < 8) adj = "a gentle wind " + compass
        else if (speed < 15) adj = "a steady wind " + compass
        else if (speed < 25) adj = "a stiff wind " + compass
        else if (speed < 40) adj = "a hard wind " + compass
        else adj = "a gale " + compass
        return adj
    }

    function precipProse(p) {
        if (p == null) return "no rain in hand"
        if (p < 10) return "no rain in hand"
        if (p < 30) return "a slim chance of rain"
        if (p < 60) return "rain likely"
        return "rain in earnest"
    }

    function weatherProse(code) { return wmoCodes[code] || "weather unclear" }

    function unitSuffix() { return units === "imperial" ? "°F" : "°C" }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            const stdout = data["stdout"] || ""
            const exit = data["exit code"]
            // Route by URL substring — both endpoints have unique paths so
            // we don't need to embed routing markers in the command.
            if (sourceName.indexOf("geocoding-api") !== -1) {
                try {
                    const body = stdout.slice(stdout.indexOf("{"))
                    const json = JSON.parse(body)
                    if (json.results && json.results.length > 0) {
                        root.lat = json.results[0].latitude
                        root.lon = json.results[0].longitude
                        root.havePosition = true
                        fetchForecast()
                    } else {
                        setSilent()
                    }
                } catch (e) { console.warn("geocoding parse:", e); setSilent() }
            } else if (sourceName.indexOf("api.open-meteo.com/v1/forecast") !== -1) {
                try {
                    const body = stdout.slice(stdout.indexOf("{"))
                    const json = JSON.parse(body)
                    const cur = json.current
                    const daily = json.daily
                    const tempUnit = unitSuffix()
                    const curLine = Math.round(cur.temperature_2m) + tempUnit + ", "
                                  + weatherProse(cur.weather_code) + ", "
                                  + windProse(cur.wind_speed_10m, cur.wind_direction_10m) + "."
                    const dayNames = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
                    const now = new Date()
                    const tomorrowIdx = 1, dayAfterIdx = 2
                    const tHi = Math.round(daily.temperature_2m_max[tomorrowIdx])
                    const tCode = daily.weather_code[tomorrowIdx]
                    const tPrecip = daily.precipitation_probability_max[tomorrowIdx]
                    const dHi = Math.round(daily.temperature_2m_max[dayAfterIdx])
                    const dCode = daily.weather_code[dayAfterIdx]
                    const dPrecip = daily.precipitation_probability_max[dayAfterIdx]
                    const dayAfter = new Date(now.getTime() + 2 * 86400000)
                    root.line1 = curLine
                    root.line2 = "Tomorrow — " + weatherProse(tCode) + ", high " + tHi + tempUnit
                               + ", " + precipProse(tPrecip) + "."
                    root.line3 = dayNames[dayAfter.getDay()] + " — " + weatherProse(dCode)
                               + ", high " + dHi + tempUnit + ", " + precipProse(dPrecip) + "."
                    root.silent = false
                } catch (e) { console.warn("forecast parse:", e); setSilent() }
            }
            disconnectSource(sourceName)
        }
        function exec(cmd) { if (cmd) connectSource(cmd) }
    }

    function setSilent() {
        silent = true
        line1 = "— the almanac is silent. —"
        line2 = ""
        line3 = ""
    }

    function fetchGeocode() {
        const url = "https://geocoding-api.open-meteo.com/v1/search?count=1&name="
                    + encodeURIComponent(cityName)
        executable.exec("curl -sS --max-time 10 " + shellQuote(url))
    }

    function fetchForecast() {
        if (!havePosition) return
        const u = units === "imperial" ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : ""
        const url = "https://api.open-meteo.com/v1/forecast"
                  + "?latitude=" + lat + "&longitude=" + lon
                  + "&current=temperature_2m,weather_code,wind_speed_10m,wind_direction_10m"
                  + "&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max"
                  + "&timezone=auto&forecast_days=3" + u
        executable.exec("curl -sS --max-time 10 " + shellQuote(url))
    }

    function shellQuote(s) { return "'" + s.replace(/'/g, "'\\''") + "'" }

    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        property int elapsedMin: 9999
        onTriggered: {
            if (!havePosition) { fetchGeocode(); return }
            if (elapsedMin >= root.refreshMinutes) {
                elapsedMin = 0
                fetchForecast()
            } else {
                elapsedMin += 1
            }
        }
    }

    onCityNameChanged: {
        havePosition = false
        line1 = line2 = line3 = ""
        fetchGeocode()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 400
        Layout.preferredHeight: 140
        Layout.minimumWidth: 280
        Layout.minimumHeight: 100

        Shared.ParchmentBackground {
            anchors.fill: parent
            alpha:     Plasmoid.configuration.backgroundOpacity
            edgeStyle: Plasmoid.configuration.edgeStyle
        }
        Loader { sourceComponent: Shared.Ornaments.PageCorner; anchors.top: parent.top; anchors.right: parent.right }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 2

            Text {
                text: root.cityName
                color: Shared.Palette.burgundy
                font.family: Shared.Palette.fontSmallCaps
                font.pixelSize: 15
                font.letterSpacing: 1.6
            }
            Loader { sourceComponent: Shared.Ornaments.DoubleRule; Layout.fillWidth: true; Layout.topMargin: 2 }

            Text {
                text: root.line1
                color: root.silent ? Shared.Palette.inkMedium : Shared.Palette.inkDark
                font.family: Shared.Palette.fontAccent
                font.pixelSize: 16
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.topMargin: 4
            }
            Text {
                visible: !root.silent && root.line2.length > 0
                text: root.line2
                color: Shared.Palette.inkMedium
                font.family: Shared.Palette.fontAccent
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Text {
                visible: !root.silent && root.line3.length > 0
                text: root.line3
                color: Shared.Palette.inkMedium
                font.family: Shared.Palette.fontAccent
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
