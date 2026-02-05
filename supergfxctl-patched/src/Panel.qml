/*
 * SPDX-FileCopyrightText: 2025 cod3ddot@proton.me
 *
 * SPDX-License-Identifier: MIT
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Services.Noctalia

Item {
    id: root

    // Plugin API (injected by PluginPanelSlot)
    property QtObject pluginApi: null
    readonly property QtObject pluginCore: pluginApi?.mainInstance

    // SmartPanel properties (required for panel behavior)
    readonly property Rectangle geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    readonly property int contentPreferredWidth: 420 * Style.uiScaleRatio
    readonly property int contentPreferredHeight: 170 * Style.uiScaleRatio

    property int confirmingMode: Main.SGFXMode.None

    anchors.fill: parent

    component GPUButton: Rectangle {
        id: gpuButton

        required property int mode

        readonly property bool _current: mode === root.pluginCore?.mode
        readonly property bool _pending: mode === root.pluginCore?.pendingMode
        readonly property bool _supported: root.pluginCore?.isModeSupported(mode) ?? false

        readonly property bool _hovered: mouse.hovered

        readonly property bool _enabled: {
            const available = root.pluginCore?.available && !root.pluginCore?.busy;
            return available && _supported;
        }

        readonly property bool _interactive: {
            // make sure that we can only switch back to current mode
            // this is useful because it allows us to "cancel"
            // the switch
            // TODO: investigate how supergfxctl behaves after switching back and
            // forth without performing necessary steps (pending action) to apply the mode switch
            const active = _current && root.pluginCore?.pendingMode === Main.SGFXMode.None;

            return _enabled && !_pending && !active;
        }

        readonly property color textColor: {
            // instead of using _enabled
            // retain text color if busy
            // lower opacity will signal the button is currently disabled
            if (!root.pluginCore?.available || !_supported) {
                return Color.mOutline;
            }

            if (_hovered) {
                return Color.mTertiary;
            }

            if (_pending) {
                return Color.mOnTertiary;
            }

            if (_current) {
                return Color.mOnPrimary;
            }

            return Color.mPrimary;
        }

        readonly property color backgroundColor: {
            // retain background color if busy
            // opacity will signal the button is currently disabled
            if (!root.pluginCore?.available || !_supported) {
                return Qt.lighter(Color.mSurfaceVariant, 1.2);
            }

            if (_hovered) {
                return "transparent";
            }

            if (_current) {
                return Color.mPrimary;
            }

            if (_pending) {
                return Color.mTertiary;
            }

            // non-current default
            return "transparent";
        }

        readonly property color borderColor: {
            if (!_enabled) {
                return Color.mOutline;
            }

            if (_pending || _hovered) {
                return Color.mTertiary;
            }

            return Color.mPrimary;
        }

        readonly property ColorAnimation animationBehaviour: ColorAnimation {
            duration: Style.animationFast
            easing.type: Easing.OutCubic
        }

        Layout.fillWidth: true
        implicitWidth: contentRow.implicitWidth + (Style.marginL * 2)
        implicitHeight: contentRow.implicitHeight + (Style.marginL * 2)

        radius: Style.iRadiusS
        color: backgroundColor
        border.width: Style.borderM
        border.color: borderColor

        opacity: _enabled ? 1.0 : 0.6

        Behavior on color {
            animation: gpuButton.animationBehaviour
        }

        Behavior on border.color {
            animation: gpuButton.animationBehaviour
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: Style.marginXS

            // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIcon.qml
            NIcon {
                icon: root.pluginCore?.getModeIcon(mode) ?? ""
                pointSize: Style.fontSizeL
                color: gpuButton.textColor

                Behavior on color {
                    animation: gpuButton.animationBehaviour
                }
            }

            // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NText.qml
            NText {
                text: root.pluginCore?.getModeLabel(mode) ?? ""
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightBold
                color: gpuButton.textColor

                Behavior on color {
                    animation: gpuButton.animationBehaviour
                }
            }
        }

        TapHandler {
            enabled: gpuButton._interactive
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: root.confirmingMode = gpuButton.mode
        }

        HoverHandler {
            id: mouse
            enabled: gpuButton._interactive
            cursorShape: Qt.PointingHandCursor
        }
    }

    component Header: NBox {
        id: header

        Layout.fillWidth: true
        Layout.preferredHeight: headerRow.implicitHeight + Style.marginM * 2

        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIcon.qml
            NIcon {
                icon: root.pluginCore?.getModeIcon(pluginCore?.mode) ?? ""
                pointSize: Style.fontSizeXXL
                color: Color.mPrimary
            }

            // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NText.qml
            NText {
                Layout.fillWidth: true
                text: root.pluginApi?.tr("gpu") ?? ""
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightBold
                color: Color.mOnSurface
            }

            // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIconButton.qml
            NIconButton {
                icon: root.pluginCore?.getActionIcon(root.pluginCore?.pendingAction) ?? ""
                tooltipText: root.pluginCore?.getActionLabel(root.pluginCore?.pendingAction) ?? ""
                baseSize: Style.baseWidgetSize * 0.8
                visible: root.pluginCore?.hasPendingAction ?? false
                // TODO: why does screen simply work here?
                // shouldnt we call pluginApi.withCurrentScreen?
                onClicked: PanelService.getPanel("sessionMenuPanel", screen)?.toggle()
            }

            // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIconButton.qml
            NIconButton {
                id: refreshButton
                icon: "refresh"
                tooltipText: I18n.tr("tooltips.refresh")
                baseSize: Style.baseWidgetSize * 0.8
                enabled: root.pluginCore?.available && !root.pluginCore?.busy
                onClicked: root.pluginCore?.refresh()

                RotationAnimation {
                    id: rotationAnimator
                    target: refreshButton
                    property: "rotation"
                    to: 360
                    duration: 2000
                    loops: Animation.Infinite
                    running: root.pluginCore?.busy
                }
            }

            // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIconButton.qml
            NIconButton {
                icon: "close"
                tooltipText: I18n.tr("tooltips.close")
                baseSize: Style.baseWidgetSize * 0.8
                onClicked: root.pluginApi?.withCurrentScreen(screen => {
                    root.pluginApi?.closePanel(screen);
                })
            }
        }
    }

    Rectangle {
        id: panelContainer
        x: Style.marginM
        y: Style.marginM
        color: "transparent"

        ColumnLayout {
            spacing: Style.marginM

            Header {}

            RowLayout {
                spacing: Style.marginM

                GPUButton {
                    mode: Main.SGFXMode.Integrated
                }
                GPUButton {
                    mode: Main.SGFXMode.Hybrid
                }
                GPUButton {
                    mode: Main.SGFXMode.AsusMuxDgpu
                }
            }

            RowLayout {
                spacing: Style.marginM

                GPUButton {
                    mode: Main.SGFXMode.AsusEgpu
                }
                GPUButton {
                    mode: Main.SGFXMode.Vfio
                }
            }
        }
    }

    // Confirmation overlay
    Rectangle {
        id: confirmOverlay

        readonly property int targetAction: {
            if (root.confirmingMode === Main.SGFXMode.None) return Main.SGFXAction.Nothing;
            return root.pluginCore?.getRequiredAction(root.confirmingMode) ?? Main.SGFXAction.Nothing;
        }

        anchors.fill: parent
        z: 10
        color: Qt.rgba(0, 0, 0, 0.5)
        visible: opacity > 0
        opacity: root.confirmingMode !== Main.SGFXMode.None ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        // Click background to cancel
        TapHandler {
            onTapped: root.confirmingMode = Main.SGFXMode.None
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - Style.marginL * 4
            height: confirmLayout.implicitHeight + Style.marginL * 2
            radius: Style.iRadiusS
            color: Color.mSurface
            border.width: Style.borderM
            border.color: Color.mPrimary

            // Block clicks from passing through
            TapHandler { }

            ColumnLayout {
                id: confirmLayout
                anchors.centerIn: parent
                width: parent.width - Style.marginL * 2
                spacing: Style.marginM

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Style.marginXS

                    NIcon {
                        icon: root.pluginCore?.getModeIcon(root.confirmingMode) ?? ""
                        pointSize: Style.fontSizeXXL
                        color: Color.mPrimary
                    }

                    NText {
                        text: `Switch to ${root.pluginCore?.getModeLabel(root.confirmingMode) ?? ""}?`
                        pointSize: Style.fontSizeL
                        font.weight: Style.fontWeightBold
                        color: Color.mOnSurface
                    }
                }

                NText {
                    visible: confirmOverlay.targetAction !== Main.SGFXAction.Nothing
                    Layout.alignment: Qt.AlignHCenter
                    text: `Requires ${root.pluginCore?.getActionLabel(confirmOverlay.targetAction) ?? ""}`
                    pointSize: Style.fontSizeM
                    color: Color.mOutline
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Style.marginM

                    // Cancel button
                    Rectangle {
                        implicitWidth: cancelText.implicitWidth + Style.marginL * 2
                        implicitHeight: cancelText.implicitHeight + Style.marginM * 2
                        radius: Style.iRadiusS
                        color: cancelHover.hovered ? Qt.lighter(Color.mSurfaceVariant, 1.1) : "transparent"
                        border.width: Style.borderM
                        border.color: cancelHover.hovered ? Color.mPrimary : Color.mOutline

                        Behavior on color {
                            ColorAnimation { duration: Style.animationFast; easing.type: Easing.OutCubic }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: Style.animationFast; easing.type: Easing.OutCubic }
                        }

                        NText {
                            id: cancelText
                            anchors.centerIn: parent
                            text: "Cancel"
                            pointSize: Style.fontSizeM
                            color: Color.mOnSurface
                        }

                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: root.confirmingMode = Main.SGFXMode.None
                        }

                        HoverHandler {
                            id: cancelHover
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    // Confirm button
                    Rectangle {
                        implicitWidth: switchContent.implicitWidth + Style.marginL * 2
                        implicitHeight: switchContent.implicitHeight + Style.marginM * 2
                        radius: Style.iRadiusS
                        color: switchHover.hovered ? Color.mTertiary : Color.mPrimary

                        Behavior on color {
                            ColorAnimation { duration: Style.animationFast; easing.type: Easing.OutCubic }
                        }

                        RowLayout {
                            id: switchContent
                            anchors.centerIn: parent
                            spacing: Style.marginXS

                            NIcon {
                                icon: root.pluginCore?.getModeIcon(root.confirmingMode) ?? ""
                                pointSize: Style.fontSizeM
                                color: switchHover.hovered ? Color.mOnTertiary : Color.mOnPrimary

                                Behavior on color {
                                    ColorAnimation { duration: Style.animationFast; easing.type: Easing.OutCubic }
                                }
                            }

                            NText {
                                text: "Switch"
                                pointSize: Style.fontSizeM
                                font.weight: Style.fontWeightBold
                                color: switchHover.hovered ? Color.mOnTertiary : Color.mOnPrimary

                                Behavior on color {
                                    ColorAnimation { duration: Style.animationFast; easing.type: Easing.OutCubic }
                                }
                            }
                        }

                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: {
                                root.pluginCore?.setMode(root.confirmingMode);
                                root.confirmingMode = Main.SGFXMode.None;
                            }
                        }

                        HoverHandler {
                            id: switchHover
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }
}
