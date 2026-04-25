import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

RippleButton {
    Layout.fillHeight: true
    implicitWidth: implicitHeight - topInset - bottomInset
    buttonRadius: Appearance.rounding.large

    background.implicitHeight: 50
}