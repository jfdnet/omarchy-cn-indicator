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

  // shibumi 等第三方栏在 bar.visualTokens 上发布样式令牌; 有则自绘 pill 原生融入,
  // 无则走官方 WidgetButton(默认样式随宿主)。两路径共用同一交互逻辑。
  readonly property var vt: (root.bar && root.bar.visualTokens) || null
  readonly property var buttonAnchor: root.vt ? shibumiPill : button

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

  implicitWidth: root.vt
    ? shibumiPill.implicitWidth
    : button.implicitWidth
  implicitHeight: root.vt
    ? shibumiPill.implicitHeight
    : button.implicitHeight

  function refresh() {
    if (!queryProc.running) queryProc.running = true
  }

  function toggle() {
    Quickshell.execDetached(["fcitx5-remote", "-t"])
    refreshSoon.restart()
  }

  function handlePress(buttonCode) {
    if (buttonCode === Qt.RightButton) {
      menuCard.open = !menuCard.open
    } else {
      root.toggle()
    }
  }

  function restartFcitx5() {
    menuCard.open = false
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

  // ── 官方栏路径 ──
  WidgetButton {
    id: button
    visible: !root.vt
    anchors.centerIn: parent
    bar: root.bar
    text: root.layoutLabel
    tooltipText: root.tooltip
    useActiveColor: false
    onPressed: function(buttonCode) { root.handlePress(buttonCode) }
  }

  // ── shibumi 栏路径: 按令牌自绘 pill ──
  Rectangle {
    id: shibumiPill
    visible: !!root.vt
    anchors.centerIn: parent
    implicitWidth: label.implicitWidth + root.vt.pillPaddingX * 2
    implicitHeight: root.vt.pillHeight
    width: implicitWidth
    height: implicitHeight
    radius: root.vt.pillRadius
    color: pillMouse.containsMouse
      ? (root.imeState === 2 ? root.vt.fillActive : root.vt.fillHover)
      : root.vt.pill
    border.width: root.vt.pillBorderWidth
    border.color: root.vt.pillBorder

    Text {
      id: label
      anchors.centerIn: parent
      text: root.layoutLabel
      color: root.imeState === 2 ? root.vt.ink : root.vt.sumiHi
      font.family: root.vt.fontFamily
      font.pixelSize: root.vt.captionSize
      renderType: Text.NativeRendering
    }

    MouseArea {
      id: pillMouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onPressed: function(mouse) { root.handlePress(mouse.button) }
    }
  }

  // ── 右键菜单(两路径共用) ──
  PopupCard {
    id: menuCard
    anchorItem: root.buttonAnchor
    bar: root.bar
    contentWidth: menuCard.fittedContentWidth(Style.space(220))
    contentHeight: menuCard.fittedContentHeight(menuColumn.implicitHeight)

    // shibumi 皮: 负外扩覆盖官方卡片的底色/圆角/边框(padding 环 + 边框环)
    Rectangle {
      visible: !!root.vt
      anchors.centerIn: parent
      width: parent.width + (menuCard.padding + 3) * 2
      height: parent.height + (menuCard.padding + 3) * 2
      radius: root.vt.panelRadius
      color: root.vt.panelBackground
      border.width: root.vt.panelBorderWidth
      border.color: root.vt.panelBorder
    }

    Column {
      id: menuColumn
      width: parent.width
      spacing: Style.space(4)

      Rectangle {
        id: restartRow
        width: parent.width
        height: Style.spacing.controlHeight
        radius: root.vt ? root.vt.tileRadius : Style.space(6)
        color: restartHover.hovered
          ? (root.vt ? root.vt.fillHover
             : Style.hoverFillFor(ShellColor.popups.text, ShellColor.popups.text))
          : "transparent"

        Text {
          anchors.left: parent.left
          anchors.leftMargin: Style.space(10)
          anchors.verticalCenter: parent.verticalCenter
          text: "重启 Fcitx5"
          color: root.vt ? root.vt.ink : ShellColor.popups.text
          font.family: root.vt ? root.vt.fontFamily : Style.font.family
          font.pixelSize: root.vt ? root.vt.labelSize : Style.font.body
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
