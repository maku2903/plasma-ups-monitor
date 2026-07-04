pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: fullRoot

    anchors.fill: parent
    implicitWidth: Kirigami.Units.gridUnit * 24
    implicitHeight: Kirigami.Units.gridUnit * 15
    Layout.minimumWidth: Kirigami.Units.gridUnit * 20
    Layout.minimumHeight: Kirigami.Units.gridUnit * 12

    readonly property bool compactHeightMode: height < Kirigami.Units.gridUnit * 12
    readonly property bool sideBySideHeader: width >= Kirigami.Units.gridUnit * 24 && width > height * 1.45
    readonly property int metricColumns: width >= Kirigami.Units.gridUnit * 24 ? 4 : 2
    readonly property int sideHeaderWidth: Kirigami.Units.gridUnit * 14
    readonly property real batteryPercentValue: Number(root.info.batteryPercent)
    readonly property real clampedBatteryPercent: Number.isFinite(batteryPercentValue) ? Math.max(0, Math.min(100, batteryPercentValue)) : 0
    readonly property int batteryCardHeight: compactHeightMode ? Kirigami.Units.gridUnit * 4 : Kirigami.Units.gridUnit * 5
    readonly property color batteryFillColor: Qt.hsva((clampedBatteryPercent / 100) * 0.33, 0.78, 0.92, 1)
    readonly property color batteryValueColor: {
        if (!root.info.onBattery) {
            return root.statusColor
        }
        return clampedBatteryPercent <= 35 ? "#f5f7fa" : "#11161c"
    }
    readonly property color batteryLabelColor: root.info.onBattery ? batteryValueColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.75)
    readonly property color batteryOutlineColor: clampedBatteryPercent <= 35 ? Qt.rgba(0, 0, 0, 0.32) : Qt.rgba(1, 1, 1, 0.18)

    Component {
        id: batteryCardComponent

        Rectangle {
            radius: Kirigami.Units.smallSpacing
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.14)
            clip: true

            Rectangle {
                visible: root.info.onBattery
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * (fullRoot.clampedBatteryPercent / 100)
                color: fullRoot.batteryFillColor
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                spacing: 2

                QQC2.Label {
                    Layout.fillWidth: true
                    text: i18n("Battery")
                    color: fullRoot.batteryLabelColor
                }

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: root.percentText
                    color: fullRoot.batteryValueColor
                    font.pointSize: fullRoot.compactHeightMode ? Kirigami.Theme.defaultFont.pointSize + 10 : Kirigami.Theme.defaultFont.pointSize + 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    style: root.info.onBattery ? Text.Outline : Text.Normal
                    styleColor: fullRoot.batteryOutlineColor
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: fullRoot.compactHeightMode ? Kirigami.Units.smallSpacing : Kirigami.Units.largeSpacing

        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: fullRoot.compactHeightMode ? Kirigami.Units.smallSpacing : Kirigami.Units.largeSpacing

            QQC2.Frame {
                Layout.fillWidth: true
                Layout.minimumWidth: fullRoot.sideBySideHeader ? fullRoot.sideHeaderWidth : -1
                Layout.preferredWidth: fullRoot.sideBySideHeader ? fullRoot.sideHeaderWidth : -1
                Layout.preferredHeight: fullRoot.sideBySideHeader ? fullRoot.batteryCardHeight : -1

                RowLayout {
                    anchors.fill: parent
                    spacing: fullRoot.compactHeightMode ? Kirigami.Units.smallSpacing : Kirigami.Units.largeSpacing

                    Kirigami.Icon {
                        source: root.iconName
                        Layout.preferredWidth: fullRoot.compactHeightMode ? Kirigami.Units.iconSizes.large : Kirigami.Units.iconSizes.huge
                        Layout.preferredHeight: fullRoot.compactHeightMode ? Kirigami.Units.iconSizes.large : Kirigami.Units.iconSizes.huge
                        opacity: root.info.onBattery ? 0.8 : 1

                        SequentialAnimation on opacity {
                            running: root.info.onBattery
                            loops: Animation.Infinite
                            OpacityAnimator { from: 1; to: 0.45; duration: 700 }
                            OpacityAnimator { from: 0.45; to: 1; duration: 700 }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: root.info.ok ? root.info.model : i18n("UPS Monitor")
                            font.pointSize: fullRoot.compactHeightMode ? Kirigami.Theme.defaultFont.pointSize + 1 : Kirigami.Theme.defaultFont.pointSize + 3
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: root.statusLine
                            color: root.statusColor
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: root.info.ok ? root.info.upsName : root.lastError
                            opacity: 0.75
                            wrapMode: Text.WordWrap
                            maximumLineCount: fullRoot.compactHeightMode ? 1 : 2
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Loader {
                visible: fullRoot.sideBySideHeader
                Layout.fillWidth: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 10
                Layout.preferredHeight: fullRoot.batteryCardHeight
                sourceComponent: batteryCardComponent
            }
        }

        Loader {
            visible: !fullRoot.sideBySideHeader
            Layout.fillWidth: true
            Layout.preferredHeight: fullRoot.batteryCardHeight
            sourceComponent: batteryCardComponent
        }

        QQC2.Frame {
            visible: root.hasAlarm
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 2

                QQC2.Label {
                    Layout.fillWidth: true
                    text: i18n("Alarm")
                    opacity: 0.7
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.info.alarm
                    color: Kirigami.Theme.negativeTextColor
                    font.bold: true
                    wrapMode: Text.WordWrap
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: fullRoot.metricColumns
            columnSpacing: fullRoot.compactHeightMode ? Kirigami.Units.smallSpacing : Kirigami.Units.largeSpacing
            rowSpacing: fullRoot.compactHeightMode ? Kirigami.Units.smallSpacing : Kirigami.Units.largeSpacing

            QQC2.Frame {
                Layout.fillWidth: true
                Layout.minimumWidth: fullRoot.metricColumns === 4 ? Kirigami.Units.gridUnit * 5 : Kirigami.Units.gridUnit * 7

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: i18n("Power")
                        opacity: 0.7
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: root.powerText
                        font.bold: true
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            QQC2.Frame {
                Layout.fillWidth: true
                Layout.minimumWidth: fullRoot.metricColumns === 4 ? Kirigami.Units.gridUnit * 5 : Kirigami.Units.gridUnit * 7

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: i18n("Voltage")
                        opacity: 0.7
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: root.voltageText
                        font.bold: true
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            QQC2.Frame {
                Layout.fillWidth: true
                Layout.minimumWidth: fullRoot.metricColumns === 4 ? Kirigami.Units.gridUnit * 5 : Kirigami.Units.gridUnit * 7

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: i18n("Runtime")
                        opacity: 0.7
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: root.runtimeTextValue
                        font.bold: true
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            QQC2.Frame {
                Layout.fillWidth: true
                Layout.minimumWidth: fullRoot.metricColumns === 4 ? Kirigami.Units.gridUnit * 5 : Kirigami.Units.gridUnit * 7

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: i18n("Load")
                        opacity: 0.7
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: root.loadText
                        font.bold: true
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }

        QQC2.Frame {
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 2

                QQC2.Label {
                    Layout.fillWidth: true
                    text: i18n("Last power loss")
                    opacity: 0.7
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.lastPowerLossText
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }

            Item {
                id: refreshIndicator
                Layout.preferredWidth: Kirigami.Units.gridUnit * 1.45
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.45
                opacity: 0.5

                Canvas {
                    id: refreshCanvas
                    anchors.fill: parent
                    antialiasing: true

                    onPaint: {
                        const ctx = getContext("2d")
                        const w = width
                        const h = height
                        const lineWidth = Math.max(1.5, Math.min(w, h) * 0.09)
                        const radius = (Math.min(w, h) - lineWidth) / 2
                        const cx = w / 2
                        const cy = h / 2
                        const start = -Math.PI / 2
                        const end = start + (Math.PI * 2 * root.countdownProgress)

                        ctx.reset()
                        ctx.clearRect(0, 0, w, h)

                        ctx.beginPath()
                        ctx.arc(cx, cy, radius, 0, Math.PI * 2, false)
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08)
                        ctx.lineWidth = lineWidth
                        ctx.stroke()

                        if (root.countdownProgress > 0) {
                            ctx.beginPath()
                            ctx.arc(cx, cy, radius, start, end, false)
                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.28)
                            ctx.lineWidth = lineWidth
                            ctx.lineCap = "round"
                            ctx.stroke()
                        }
                    }

                    Connections {
                        target: root
                        function onCountdownProgressChanged() {
                            refreshCanvas.requestPaint()
                        }
                    }
                }

                QQC2.Label {
                    anchors.centerIn: parent
                    text: String(root.countdownSecondsRemaining)
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize - 2
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.62)
                }
            }
        }
    }
}
