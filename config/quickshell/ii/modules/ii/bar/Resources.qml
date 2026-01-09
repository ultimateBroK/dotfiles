import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    visible: Config.options.bar.resources.enable

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            id: ramRes
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
            shown: Config.options.bar.resources.showMemory
        }

        Resource {
            id: gpuRes
            iconName: "developer_board"
            percentage: ResourceUsage.gpuUsage
            shown: ResourceUsage.gpuAvailable && (
                Config.options.bar.resources.showGpu && (
                Config.options.bar.resources.alwaysShowGpu ||
                (MprisController.activePlayer?.trackTitle == null) ||
                root.alwaysShowAllResources
                )
            )
            Layout.leftMargin: shown && ramRes.shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.gpuWarningThreshold
        }

        Resource {
            id: cpuRes
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.showCpu && (
                Config.options.bar.resources.alwaysShowCpu || 
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources
            )
            Layout.leftMargin: shown && (ramRes.shown || gpuRes.shown) ? 6 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
