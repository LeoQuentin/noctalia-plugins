import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

// Bar Widget Component
Item {
  id: root

  property var pluginApi: null

  // Required properties for bar widgets
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  // Get message from settings or use manifest defaults
  readonly property string message: pluginApi?.pluginSettings?.message || pluginApi?.manifest?.metadata?.defaultSettings?.message || ""
  readonly property color bgColor: pluginApi?.pluginSettings?.backgroundColor || pluginApi?.manifest?.metadata?.defaultSettings?.backgroundColor || "transparent"

  // Bar positioning properties
  readonly property string barPosition: Settings.getBarPositionForScreen(screen.name)
  readonly property bool barIsVertical: barPosition === "left" || barPosition === "right"
  readonly property real barHeight: Style.getBarHeightForScreen(screen?.name)

  readonly property real contentWidth: barIsVertical ? root.barHeight : contentRow.implicitWidth + Style.marginL * 2
  readonly property real contentHeight: root.barHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: mouseArea.containsMouse ? Qt.lighter(root.bgColor, 1.1) : root.bgColor
    radius: !barIsVertical ? Style.radiusM : width * 0.5

    RowLayout {
      id: contentRow
      anchors.centerIn: parent
      spacing: Style.marginS

      NIcon {
        icon: "noctalia"
        applyUiScale: false
      }

      NText {
        visible: !barIsVertical
        text: root.message
        color: Color.mOnPrimary
        pointSize: Style.barFontSize
        font.weight: Font.Medium
      }
    }
  }

  // Mouse area to open panel
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      if (pluginApi) {
        Logger.i("HelloWorld", "Opening Hello World panel");
        pluginApi.openPanel(root.screen, this);
      }
    }
  }
}

