pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.bar.weather

import Quickshell
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root

    implicitWidth: Appearance.sizes.verticalBarWidth
    implicitHeight: content.implicitHeight

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    onPressed: {
        if (mouse.button === Qt.RightButton) {
            Weather.getData();
            Quickshell.execDetached([
                "notify-send",
                Translation.tr("Weather"),
                Translation.tr("Refreshing (manually triggered)"),
                "-a",
                "Shell",
            ])
            mouse.accepted = false
        }
    }

    ColumnLayout {
        id: content
        anchors.centerIn: parent
        spacing: 2

        MaterialSymbol {
            fill: 0
            text: Icons.getWeatherIcon(Weather.data.weatherCode, Weather.data.isDay) ?? "cloud"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            Layout.alignment: Qt.AlignHCenter
        }
    }

    WeatherPopup {
        id: weatherPopup
        hoverTarget: root
    }
}
