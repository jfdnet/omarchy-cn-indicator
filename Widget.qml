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
  property bool menuOpen: false

  readonly property string layoutLabel: {
    if (root.imeState === 2) return "中"
    if (root.imeState === 0) return "—"
    return "EN"
  }

  readonly property string tooltip: {
    if (root.imeState === 2) return "中文 · 点击切换 · 右键菜单"
    if (root.imeState === 0) return "输入法未运行 · 右键可重启"
    return "English · 点击切换 · 右键菜单"
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

  function restartFcitx5() {
    root.menuOpen = false
    // 官方姿势(见 omarchy-fcitx5.service 注释): 裸 fcitx5(dbus 激活)占着总线时,
    // 直接 restart 会触发 Restart=always 循环(omarchy#15739 的竞态)。必须先停官方
    // unit、清掉游离实例, 再干净启动 unit(带 --disable notificationitem 与会话 env)。
    Quickshell.execDetached(["bash", "-c",
      "systemctl --user stop omarchy-fcitx5.service; " +
      "pkill -x fcitx5 2>/dev/null; sleep 1; " +
      "systemctl --user start omarchy-fcitx5.service"])
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
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) {
        root.menuOpen = !root.menuOpen
      } else {
        root.toggle()
      }
    }
  }

  // 右键菜单: 仿 bar/widgets/Tray.qml 的 PopupCard 模式
  PopupCard {
    id: menuCard
    anchorItem: button
    owner: button
    bar: root.bar
    open: root.menuOpen
    contentWidth: menuCard.fittedContentWidth(Style.space(220))
    contentHeight: menuCard.fittedContentHeight(menuColumn.implicitHeight)

    onOpenChanged: if (!open) root.menuOpen = false

    Column {
      id: menuColumn
      anchors.fill: parent
      spacing: Style.space(4)

      Rectangle {
        id: restartRow
        width: parent.width
        height: Style.spacing.controlHeight
        radius: Style.space(6)
        color: restartHover.hovered ? Style.hoverFillFor(ShellColor.popups.text, ShellColor.popups.text) : "transparent"

        Text {
          anchors.left: parent.left
          anchors.leftMargin: Style.space(10)
          anchors.verticalCenter: parent.verticalCenter
          text: "重启 Fcitx5"
          color: ShellColor.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          renderType: Text.NativeRendering
        }

        HoverHandler { id: restartHover }
        TapHandler {
          onTapped: root.restartFcitx5()
        }
      }
    }
  }
}
