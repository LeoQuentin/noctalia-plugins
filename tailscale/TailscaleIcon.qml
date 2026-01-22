import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.Commons
import qs.Widgets

Item {
  id: root

  property real pointSize: Style.fontSizeL
  property bool applyUiScale: true
  property color color: Color.mOnSurface

  implicitWidth: Math.max(1, applyUiScale ? root.pointSize * Style.uiScaleRatio : root.pointSize)
  implicitHeight: Math.max(1, applyUiScale ? root.pointSize * Style.uiScaleRatio : root.pointSize)

  Image {
    id: iconImage
    anchors.fill: parent
    source: Qt.resolvedUrl("icons/tailscale.svg")
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true

    layer.enabled: true
    layer.effect: MultiEffect {
      colorization: 1.0
      colorizationColor: root.color
    }
  }
}
