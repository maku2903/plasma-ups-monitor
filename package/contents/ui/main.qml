import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.icon: iconName
    Plasmoid.title: info.ok && info.model ? info.model : i18n("UPS Monitor")

    implicitWidth: Kirigami.Units.gridUnit * 24
    implicitHeight: Kirigami.Units.gridUnit * 15
    Layout.minimumWidth: Kirigami.Units.gridUnit * 20
    Layout.minimumHeight: Kirigami.Units.gridUnit * 12

    readonly property string helperPath: String(Qt.resolvedUrl("../scripts/nut-status.sh")).replace(/^file:\/\//, "")
    readonly property int refreshSeconds: Math.max(3, Number(Plasmoid.configuration.refreshSeconds || 10))
    readonly property string upsName: String(Plasmoid.configuration.upsName || "eaton@localhost")
    readonly property string sourceCommand: "/bin/sh -lc " + shellQuote(shellQuote(helperPath) + " " + shellQuote(upsName))
    readonly property real countdownProgress: {
        const totalMs = refreshSeconds * 1000
        if (totalMs <= 0) {
            return 0
        }
        return Math.max(0, Math.min(1, (refreshDeadlineMs - currentTimeMs) / totalMs))
    }
    readonly property int countdownSecondsRemaining: Math.max(0, Math.ceil((refreshDeadlineMs - currentTimeMs) / 1000))

    property string lastError: ""
    property double currentTimeMs: Date.now()
    property double refreshDeadlineMs: Date.now() + (refreshSeconds * 1000)
    property var info: ({
        ok: false,
        upsName: upsName,
        model: "",
        status: "",
        onBattery: false,
        batteryPercent: null,
        powerWatts: null,
        outputVoltage: null,
        runtimeSeconds: null,
        loadPercent: null,
        alarm: "",
        lastPowerLoss: "",
        error: ""
    })

    property bool hasAlarm: info.ok && !!info.alarm && String(info.alarm).length > 0
    property bool isCharging: info.ok && hasStatusToken("CHRG")
    property string iconName: {
        if (!info.ok) {
            return "battery-missing"
        }

        const percent = Number(info.batteryPercent)
        let level = "missing"
        if (Number.isFinite(percent)) {
            if (percent >= 90) {
                level = "100"
            } else if (percent >= 70) {
                level = "080"
            } else if (percent >= 50) {
                level = "060"
            } else if (percent >= 30) {
                level = "040"
            } else if (percent >= 10) {
                level = "020"
            } else {
                level = "000"
            }
        }

        if (isCharging) {
            return "battery-" + level + "-charging"
        }

        return "battery-" + level
    }

    property color statusColor: {
        if (!info.ok) {
            return Kirigami.Theme.neutralTextColor
        }
        if (hasAlarm) {
            return Kirigami.Theme.negativeTextColor
        }
        if (info.onBattery) {
            return Kirigami.Theme.neutralTextColor
        }
        return Kirigami.Theme.positiveTextColor
    }

    property string percentText: formatPercent(info.batteryPercent)
    property string powerText: formatNumber(info.powerWatts, "W", 0)
    property string voltageText: formatNumber(info.outputVoltage, "V", 0)
    property string runtimeTextValue: formatRuntime(info.runtimeSeconds)
    property string loadText: formatNumber(info.loadPercent, "%", 0)
    property string lastPowerLossText: info.ok && info.lastPowerLoss ? info.lastPowerLoss : i18n("Never")
    property string compactSecondaryText: {
        if (!info.ok) {
            return i18n("No data")
        }
        if (hasAlarm) {
            return info.alarm
        }
        return powerText
    }
    property string statusLine: {
        if (!info.ok) {
            return i18n("Unavailable")
        }
        if (hasAlarm) {
            if (info.onBattery) {
                return i18n("Alarm • On battery")
            }
            return isCharging ? i18n("Alarm • Charging") : i18n("Alarm")
        }
        if (info.onBattery) {
            return i18n("Running on battery")
        }
        if (isCharging) {
            return i18n("Online • Charging")
        }
        return i18n("Online")
    }

    toolTipMainText: Plasmoid.title
    toolTipSubText: {
        if (!info.ok) {
            return lastError
        }
        if (hasAlarm) {
            return i18nc("@info:tooltip", "%1, %2, last power loss: %3", statusLine, info.alarm, lastPowerLossText)
        }
        return i18nc("@info:tooltip", "%1, %2 remaining, last power loss: %3", statusLine, runtimeTextValue, lastPowerLossText)
    }

    switchWidth: -1
    switchHeight: -1
    compactRepresentation: CompactRepresentation { }
    fullRepresentation: FullRepresentation { }
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation

    onRefreshSecondsChanged: refreshDeadlineMs = Date.now() + (refreshSeconds * 1000)

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: root.currentTimeMs = Date.now()
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'"
    }

    function commandLine() {
        return sourceCommand
    }

    function statusTokens() {
        return String(info.status || "").trim().split(/\s+/).filter(Boolean)
    }

    function hasStatusToken(token) {
        return statusTokens().indexOf(token) >= 0
    }

    function formatPercent(value) {
        if (value === null || value === undefined || value === "") {
            return i18n("N/A")
        }
        return i18nc("@item:intext battery percent", "%1%", Number(value).toFixed(0))
    }

    function formatNumber(value, unit, decimals) {
        if (value === null || value === undefined || value === "") {
            return i18n("N/A")
        }
        return Number(value).toFixed(decimals) + " " + unit
    }

    function formatRuntime(seconds) {
        const total = Number(seconds)
        if (!Number.isFinite(total) || total <= 0) {
            return i18n("N/A")
        }

        const hours = Math.floor(total / 3600)
        const minutes = Math.floor((total % 3600) / 60)

        if (hours > 0) {
            if (minutes > 0) {
                return i18nc("@item:intext runtime", "%1 h %2 min", hours, minutes)
            }
            return i18nc("@item:intext runtime", "%1 h", hours)
        }

        return i18nc("@item:intext runtime", "%1 min", Math.max(1, minutes))
    }

    function extractPayload(data) {
        const namedKeys = ["stdout", "output", "data", "text"]
        for (let i = 0; i < namedKeys.length; ++i) {
            const value = data[namedKeys[i]]
            if (typeof value === "string" && value.trim().length > 0) {
                return value
            }
        }

        for (const key in data) {
            const value = data[key]
            if (typeof value === "string" && value.trim().startsWith("{")) {
                return value
            }
        }

        return ""
    }

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        interval: root.refreshSeconds * 1000
        connectedSources: [root.sourceCommand]

        onNewData: function(sourceName, data) {
            if (sourceName !== root.sourceCommand) {
                return
            }

            const payload = root.extractPayload(data)

            if (!payload.length) {
                root.lastError = i18n("No data returned by helper")
                root.info = {
                    ok: false,
                    upsName: root.upsName,
                    model: "",
                    status: "",
                    onBattery: false,
                    batteryPercent: null,
                    powerWatts: null,
                    outputVoltage: null,
                    runtimeSeconds: null,
                    loadPercent: null,
                    alarm: "",
                    lastPowerLoss: "",
                    error: root.lastError
                }
                root.refreshDeadlineMs = Date.now() + (root.refreshSeconds * 1000)
                return
            }

            try {
                const parsed = JSON.parse(payload)
                root.info = parsed
                root.lastError = parsed.ok ? "" : (parsed.error || i18n("Unknown UPS error"))
                root.refreshDeadlineMs = Date.now() + (root.refreshSeconds * 1000)
            } catch (error) {
                root.lastError = i18n("Invalid helper output")
                root.info = {
                    ok: false,
                    upsName: root.upsName,
                    model: "",
                    status: "",
                    onBattery: false,
                    batteryPercent: null,
                    powerWatts: null,
                    outputVoltage: null,
                    runtimeSeconds: null,
                    loadPercent: null,
                    alarm: "",
                    lastPowerLoss: "",
                    error: String(error)
                }
                root.refreshDeadlineMs = Date.now() + (root.refreshSeconds * 1000)
            }
        }
    }

    Connections {
        target: Plasmoid
        function onConfigurationChanged() {
            execSource.connectedSources = [root.sourceCommand]
        }
    }
}
