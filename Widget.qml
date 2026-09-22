import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "io.github.jfdnet.cn-indicator"

  // fcitx5-remote: 0 closed, 1 latin/inactive, 2 active (Chinese)
  property int imeState: 1

  readonly property string layoutLabel: {
    if (root.imeState === 2) return "中"
    if (root.imeState === 0) return "—"
    return "EN"
  }

  readonly property string tooltip: {
    if (root.imeState === 2) return "中文 · 点击切换"
    if (root.imeState === 0) return "输入法未运行"
    return "English · 点击切换"
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!queryProc.running) queryProc.running = true
  }

  function toggle() {
    Quickshell.execDetached(["fcitx5-remote", "-t"])
    refreshSoon.restart()
  }

  Component.onCompleted: refresh()

  Process {
    id: queryProc
    command: ["fcitx5-remote"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var s = parseInt(String(text || "").trim(), 10)
        root.imeState = (s === 0 || s === 1 || s === 2) ? s : 0
      }
    }
  }

  Timer {
    interval: 700
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    id: refreshSoon
    interval: 120
    onTriggered: root.refresh()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.layoutLabel
    fontSize: Style.font.caption
    horizontalMargin: 6
    tooltipText: root.tooltip
    onPressed: function() { root.toggle() }
  }
}
