import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar as Bar

MouseArea {
    id: root
    property bool alwaysShowAllResources: false
    implicitHeight: columnLayout.implicitHeight
    implicitWidth: columnLayout.implicitWidth
    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    visible: Config.options.bar.resources.enable

    ColumnLayout {
        id: columnLayout
        spacing: 10
        anchors.fill: parent

        Resource {
            Layout.alignment: Qt.AlignHCenter
            visible: Config.options.bar.resources.showMemory
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            visible: Config.options.bar.resources.showGpu && ResourceUsage.gpuAvailable
            iconName: "developer_board"
            percentage: ResourceUsage.gpuUsage
            warningThreshold: Config.options.bar.resources.gpuWarningThreshold
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            visible: Config.options.bar.resources.showCpu
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

    }

    Bar.ResourcesPopup {
        hoverTarget: root
    }
}
