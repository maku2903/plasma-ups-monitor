import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

ColumnLayout {
    id: root

    property alias cfg_upsName: upsNameField.text
    property alias cfg_refreshSeconds: refreshSpin.value

    spacing: Kirigami.Units.largeSpacing

    ListModel {
        id: detectedUpsModel
    }

    function extractPayload(data) {
        const namedKeys = ["stdout", "output", "data", "text"]
        for (let i = 0; i < namedKeys.length; ++i) {
            const value = data[namedKeys[i]]
            if (typeof value === "string" && value.length > 0) {
                return value
            }
        }

        for (const key in data) {
            const value = data[key]
            if (typeof value === "string" && value.length > 0) {
                return value
            }
        }

        return ""
    }

    function setDetectedUps(payload) {
        detectedUpsModel.clear()

        const lines = payload.split(/\r?\n/)
        for (let i = 0; i < lines.length; ++i) {
            const name = lines[i].trim()
            if (!name.length) {
                continue
            }
            detectedUpsModel.append({
                value: name + "@localhost",
                label: name + "@localhost"
            })
        }

        detectedUpsCombo.currentIndex = -1
        for (let i = 0; i < detectedUpsModel.count; ++i) {
            if (detectedUpsModel.get(i).value === upsNameField.text) {
                detectedUpsCombo.currentIndex = i
                break
            }
        }
    }

    readonly property string detectCommand: "/bin/sh -lc 'upsc -l 2>/dev/null'"

    P5Support.DataSource {
        id: detectSource
        engine: "executable"
        connectedSources: [root.detectCommand]

        onNewData: function(sourceName, data) {
            if (sourceName !== root.detectCommand) {
                return
            }
            root.setDetectedUps(root.extractPayload(data))
        }
    }

    QQC2.Label {
        text: i18n("UPS name")
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        QQC2.ComboBox {
            id: detectedUpsCombo
            Layout.fillWidth: true
            model: detectedUpsModel
            textRole: "label"
            enabled: detectedUpsModel.count > 0
            displayText: currentIndex >= 0 ? currentText : i18n("Detected local UPS")

            onActivated: {
                if (currentIndex >= 0) {
                    upsNameField.text = detectedUpsModel.get(currentIndex).value
                }
            }
        }

        QQC2.Button {
            text: i18n("Refresh")
            onClicked: {
                detectSource.connectedSources = []
                detectSource.connectedSources = [root.detectCommand]
            }
        }
    }

    QQC2.Label {
        Layout.fillWidth: true
        text: detectedUpsModel.count > 0
            ? i18n("Choose a detected local UPS or enter a custom NUT target below.")
            : i18n("No local UPS detected. Enter a custom NUT target below, for example eaton@localhost.")
        opacity: 0.7
        wrapMode: Text.WordWrap
    }

    QQC2.TextField {
        id: upsNameField
        Layout.fillWidth: true
        placeholderText: "eaton@localhost"

        onTextChanged: {
            detectedUpsCombo.currentIndex = -1
            for (let i = 0; i < detectedUpsModel.count; ++i) {
                if (detectedUpsModel.get(i).value === text) {
                    detectedUpsCombo.currentIndex = i
                    break
                }
            }
        }
    }

    QQC2.Label {
        text: i18n("Refresh interval (seconds)")
    }

    QQC2.SpinBox {
        id: refreshSpin
        from: 3
        to: 3600
        editable: true
    }

    Item {
        Layout.fillHeight: true
    }
}
