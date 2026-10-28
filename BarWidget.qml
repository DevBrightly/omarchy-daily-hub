import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.devbrightly.daily-hub"

  readonly property int dayStart: Number(setting("dayStart", 8))
  readonly property int dayEnd: Number(setting("dayEnd", 22))
  readonly property int focusMinutes: Number(setting("focusMinutes", 25))
  readonly property int breakMinutes: Number(setting("breakMinutes", 5))
  readonly property int screenGoalHours: Number(setting("screenGoalHours", 8))
  readonly property bool showLabel: setting("showLabel", true) === true
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }
  function inject() {
    var p = panelLoader.item
    if (!p) return
    p.bar = root.bar; p.settings = root.settings; p.anchorItem = button; p.hostWidget = root; p.store = store
    p.screenGoalHours = root.screenGoalHours
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: inject()
  onSettingsChanged: inject()

  Store {
    id: store
    dayStartHour: root.dayStart
    dayEndHour: root.dayEnd
    focusMinutes: root.focusMinutes
    breakMinutes: root.breakMinutes
    onFocusFinished: function(mode) {
      Util.execArgv(["omarchy-notification-send", "--app-name", "Daily Hub", mode === "focus" ? "Focus complete" : "Break complete", mode === "focus" ? "Time to take a short break." : "Ready for another focus session?"])
    }
  }

  Loader { id: panelLoader; active: true; source: Qt.resolvedUrl("Panel.qml"); visible: false; onLoaded: { root.inject(); Qt.callLater(root.inject) } }

  IpcHandler {
    target: "io.github.devbrightly.daily-hub"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.togglePanel() }
    function add(text: string): void { store.addTask(text, false) }
    function focus(): void { store.toggleFocus() }
    function status(): string { return store.stats.done + "/" + store.stats.total + " · " + store.pomodoroText + " · " + store.screenLabel }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    horizontalMargin: 7
    fixedWidth: root.vertical ? -1 : Math.round(content.implicitWidth + Style.spaceReal(7) * 2)
    tooltipText: "Daily Hub · " + store.stats.done + "/" + store.stats.total + " done · " + store.pomodoroText + " · " + store.screenLabel + " screen time"
    onPressed: function(b) { if (b === Qt.MiddleButton) store.toggleFocus(); else root.togglePanel() }

    Row {
      id: content
      anchors.centerIn: parent
      spacing: Style.space(6)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: store.dailyData.focus.running ? "󰔟" : "󰄬"
        color: root.bar ? root.bar.barForeground : Color.foreground
        font.family: Style.font.icon
        font.pixelSize: Style.bar.iconSize || Style.font.body
      }
      Text {
        visible: root.showLabel && !root.vertical
        anchors.verticalCenter: parent.verticalCenter
        text: store.dailyData.focus.running ? store.pomodoroText : (store.stats.total ? store.stats.done + "/" + store.stats.total : "Today")
        color: root.bar ? root.bar.barForeground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.bodySmall
      }
    }
  }
}
