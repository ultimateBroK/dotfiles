import QtQuick
import qs.modules.common
import qs.modules.common.functions
import QtQuick.Layouts

Rectangle {
    Layout.topMargin: Appearance.rounding.large
    Layout.bottomMargin: Appearance.rounding.large
    Layout.fillHeight: true
    implicitWidth: 1
    color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.3)
}