import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    implicitWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
    implicitHeight: row.implicitHeight + Kirigami.Units.smallSpacing * 2

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: root.iconName
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            opacity: root.info.onBattery ? 0.75 : 1

            SequentialAnimation on opacity {
                running: root.info.onBattery
                loops: Animation.Infinite
                OpacityAnimator { from: 1; to: 0.45; duration: 700 }
                OpacityAnimator { from: 0.45; to: 1; duration: 700 }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            QQC2.Label {
                Layout.fillWidth: true
                font.bold: true
                horizontalAlignment: Text.AlignLeft
                text: root.info.ok ? root.percentText : i18n("UPS")
                color: root.statusColor
                elide: Text.ElideRight
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: root.compactSecondaryText
                opacity: 0.75
                font.pointSize: Math.max(8, Kirigami.Theme.defaultFont.pointSize - 1)
                elide: Text.ElideRight
            }
        }
    }
}
