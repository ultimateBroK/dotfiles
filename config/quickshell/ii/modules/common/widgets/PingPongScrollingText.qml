import QtQuick
import qs.modules.common
import qs.modules.common.widgets

/**
 * Text component với hiệu ứng scrolling ping-pong (đảo chiều)
 * - Lần 1: chạy từ 0% đến 100% (xuôi)
 * - Lần 2: chạy từ 100% về 0% (ngược lại)
 * - Lần 3: quay lại từ 0% đến 100%, và lặp lại
 */
Item {
    id: root
    property string text: ""
    property color color: Appearance.colors.colOnLayer1
    property int fontPixelSize: Appearance.font.pixelSize.normal
    property int animationDuration: 4000 // Thời gian cho mỗi chiều (ms)
    property int pauseDuration: 500 // Thời gian dừng ở đầu/cuối (ms)
    property bool autoStart: true // Tự động bắt đầu animation khi text thay đổi
    
    clip: true
    implicitHeight: scrollingText.implicitHeight
    
    // Kiểm tra xem text có bị overflow không
    readonly property bool needsScrolling: width > 0 && textMetrics.width > width
    
    // Text metrics để đo độ dài text
    TextMetrics {
        id: textMetrics
        font.pixelSize: root.fontPixelSize
        text: root.text
    }
    
    // Text hiển thị
    StyledText {
        id: scrollingText
        anchors.verticalCenter: parent.verticalCenter
        x: root.needsScrolling ? textX : 0
        width: root.needsScrolling ? textMetrics.width : (root.width > 0 ? root.width : implicitWidth)
        color: root.color
        font.pixelSize: root.fontPixelSize
        text: root.text
        horizontalAlignment: Text.AlignLeft
        
        property real textX: 0 // Vị trí X của text để scroll
    }
    
    // Sequential animation cho ping-pong effect
    SequentialAnimation {
        id: pingPongAnimation
        running: root.needsScrolling && root.autoStart && root.text !== ""
        loops: Animation.Infinite
        
        // Dừng ở đầu (0%)
        PauseAnimation {
            duration: root.pauseDuration
        }
        
        // Chạy từ 0% đến 100% (xuôi) - smooth easing
        PropertyAnimation {
            target: scrollingText
            property: "textX"
            from: 0
            to: -(textMetrics.width - root.width)
            duration: root.animationDuration
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.25, 0.1, 0.25, 1.0] // Smooth ease-in-out
        }
        
        // Dừng ở cuối (100%)
        PauseAnimation {
            duration: root.pauseDuration
        }
        
        // Chạy từ 100% về 0% (ngược lại) - smooth easing
        PropertyAnimation {
            target: scrollingText
            property: "textX"
            from: -(textMetrics.width - root.width)
            to: 0
            duration: root.animationDuration
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.25, 0.1, 0.25, 1.0] // Smooth ease-in-out
        }
    }
    
    // Reset và restart animation khi text hoặc width thay đổi
    onTextChanged: {
        pingPongAnimation.stop()
        scrollingText.textX = 0
        if (root.needsScrolling && root.autoStart && root.text !== "") {
            pingPongAnimation.start()
        }
    }
    
    onWidthChanged: {
        pingPongAnimation.stop()
        scrollingText.textX = 0
        if (root.needsScrolling && root.autoStart && root.text !== "") {
            pingPongAnimation.start()
        }
    }
}

