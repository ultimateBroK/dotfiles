import QtQuick
import qs.modules.common
import qs.modules.common.widgets

/**
 * Text component with a ping-pong scrolling effect
 * - Pass 1: scrolls from start (0%) to end (100%)
 * - Pass 2: scrolls back from end (100%) to start (0%)
 * - Pass 3+: repeats the same pattern infinitely
 */
Item {
    id: root
    property string text: ""
    property color color: Appearance.colors.colOnLayer1
    property int fontPixelSize: Appearance.font.pixelSize.normal
    property bool outlineEnabled: false
    property color outlineColor: ColorUtils.transparentize(Appearance.m3colors.m3shadow, 0.35)
    property int animationDuration: 4000 // Duration for each direction (ms)
    property int pauseDuration: 500 // Pause duration at each edge (ms)
    property bool autoStart: true // Automatically start animation when text changes
    property bool centerStaticText: false // Center text when it doesn't need to scroll
    
    clip: true
    implicitHeight: scrollingText.implicitHeight
    
    // Real content width (max between TextMetrics and paintedWidth to avoid inconsistencies)
    readonly property real contentWidth: Math.max(textMetrics.width, scrollingText.paintedWidth)

    // Check whether the text overflows the available width
    readonly property bool needsScrolling: width > 0 && contentWidth > width
    
    // Text metrics to estimate text length (used together with paintedWidth)
    TextMetrics {
        id: textMetrics
        font.pixelSize: root.fontPixelSize
        text: root.text
    }
    
    // Rendered text
    StyledText {
        id: scrollingText
        anchors.verticalCenter: parent.verticalCenter
        // Snap to integer pixels to avoid subpixel blur on high-contrast wallpapers.
        x: root.needsScrolling ? Math.round(textX) : 0
        width: root.needsScrolling ? root.contentWidth : (root.width > 0 ? root.width : implicitWidth)
        color: root.color
        font.pixelSize: root.fontPixelSize
        text: root.text
        outlineEnabled: root.outlineEnabled
        outlineColor: root.outlineColor
        nativeRendering: root.outlineEnabled && root.needsScrolling
        horizontalAlignment: (root.needsScrolling || !root.centerStaticText) ? Text.AlignLeft : Text.AlignHCenter
        
        property real textX: 0 // X position used for scrolling
    }
    
    // Sequential animation implementing the ping-pong effect
    SequentialAnimation {
        id: pingPongAnimation
        running: root.needsScrolling && root.autoStart && root.text !== ""
        loops: Animation.Infinite
        
        // Pause at the start (0%)
        PauseAnimation {
            duration: root.pauseDuration
        }
        
        // Scroll forward from 0% to 100% with smooth easing
        PropertyAnimation {
            target: scrollingText
            property: "textX"
            from: 0
            to: -Math.round(root.contentWidth - root.width)
            duration: root.animationDuration
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.25, 0.1, 0.25, 1.0] // Smooth ease-in-out
        }
        
        // Pause at the end (100%)
        PauseAnimation {
            duration: root.pauseDuration
        }
        
        // Scroll backward from 100% to 0% with smooth easing
        PropertyAnimation {
            target: scrollingText
            property: "textX"
            from: -Math.round(root.contentWidth - root.width)
            to: 0
            duration: root.animationDuration
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.25, 0.1, 0.25, 1.0] // Smooth ease-in-out
        }
    }
    
    // Reset and restart the animation when text or width changes
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

