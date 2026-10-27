import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.devbrightly.daily-hub"
  manageIpc: false
  property var anchorItem: null
  property var hostWidget: null
  property var store: null
  property int screenGoalHours: 8
  readonly property var barIdentity: hostWidget || root
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color accent: bar ? bar.foreground : Color.accent
  readonly property string family: bar ? bar.fontFamily : Style.font.family
  property bool addPriority: false

  function open() { controller.show() }
  function close() { controller.hide() }
  function toggle() { if (opened) close(); else open() }
  function switchPanel(direction) { return bar && typeof bar.switchPanelFrom === "function" ? bar.switchPanelFrom(barIdentity, direction) : false }

  implicitWidth: 0
  implicitHeight: 0

  KeyboardPanel {
    id: popup
    anchorItem: root.anchorItem
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: popup.fittedContentWidth(Style.space(430))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: taskInput.activeFocus || reminderText.activeFocus || reminderMinutes.activeFocus
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(text) {
        if (text === "a") taskInput.forceActiveFocus()
        else if (text === "f" && root.store) root.store.toggleFocus()
        else if (text === "r" && root.store) root.store.resetFocus()
        else if (text === "c" && root.store) root.store.clearCompleted()
      }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        Row {
          width: parent.width
          spacing: Style.space(12)
          Column {
            width: parent.width - focusHero.width - parent.spacing
            spacing: Style.space(3)
            Text { width: parent.width; text: Qt.formatDate(root.store ? root.store.now : new Date(), "dddd, d MMMM"); color: root.fg; font.family: root.family; font.pixelSize: Style.font.title; font.bold: true; elide: Text.ElideRight }
            Text { width: parent.width; text: root.store && root.store.stats.total ? root.store.stats.done + " of " + root.store.stats.total + " tasks complete" : "Plan a calm, focused day"; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.62); font.family: root.family; font.pixelSize: Style.font.bodySmall }
            Text { width: parent.width; text: root.store ? Math.round(root.store.dayFraction * 100) + "% of your day has passed" : ""; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.48); font.family: root.family; font.pixelSize: Style.font.caption }
          }
          Text {
            id: focusHero
            anchors.verticalCenter: parent.verticalCenter
            text: root.store ? root.store.pomodoroText : "25:00"
            color: root.fg
            font.family: root.family
            font.pixelSize: Style.font.displayLarge
            font.bold: true
          }
        }

        Item {
          width: parent.width; height: Style.space(8)
          Rectangle { anchors.fill: parent; radius: height / 2; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12) }
          Rectangle { height: parent.height; width: parent.width * (root.store ? root.store.stats.ratio : 0); radius: height / 2; color: root.accent; Behavior on width { NumberAnimation { duration: 220 } } }
        }

        Row {
          width: parent.width
          spacing: Style.space(8)
          ActionButton { text: root.store && root.store.dailyData.focus.running ? "Pause" : "Start focus"; glyph: root.store && root.store.dailyData.focus.running ? "󰏤" : "󰐊"; onTriggered: if (root.store) root.store.toggleFocus() }
          ActionButton { text: "Reset"; glyph: "󰑐"; onTriggered: if (root.store) root.store.resetFocus() }
          ActionButton { text: root.store && root.store.dailyData.focus.mode === "break" ? "Focus" : "Break"; glyph: "󰒲"; onTriggered: if (root.store) root.store.switchFocusMode() }
          Text { anchors.verticalCenter: parent.verticalCenter; text: root.store ? root.store.dailyData.focus.sessions + " sessions" : ""; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.55); font.family: root.family; font.pixelSize: Style.font.caption }
        }

        PanelSeparator { foreground: root.fg }

        Item {
          width: parent.width; implicitHeight: taskHeader.implicitHeight
          PanelSectionHeader { id: taskHeader; anchors.left: parent.left; text: "TODAY"; foreground: root.fg; fontFamily: root.family }
          Text { anchors.right: parent.right; text: root.store ? root.store.stats.priorityDone + "/" + root.store.stats.priorityTotal + " priorities" : ""; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.5); font.family: root.family; font.pixelSize: Style.font.caption }
        }

        Column {
          width: parent.width
          spacing: Style.space(3)
          Repeater {
            model: root.store ? root.store.tasks : []
            TaskRow { required property var modelData; width: column.width; task: modelData }
          }
          Text { visible: !root.store || root.store.tasks.length === 0; text: "Nothing here yet — add your first task below."; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.48); font.family: root.family; font.pixelSize: Style.font.bodySmall }
        }

        Row {
          width: parent.width; spacing: Style.space(8)
          TextField {
            id: taskInput
            width: parent.width - priorityButton.width - parent.spacing
            foreground: root.fg; accent: root.accent
            placeholderText: root.addPriority ? "Add a priority…" : "Add a task…"
            onAccepted: { if (root.store && text.trim()) root.store.addTask(text, root.addPriority); text = "" }
          }
          Rectangle {
            id: priorityButton
            width: Style.space(42); height: taskInput.height; radius: Style.cornerRadius
            color: root.addPriority ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22) : Style.hoverFillFor(root.fg, root.fg)
            border.width: 1; border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.15)
            Text { anchors.centerIn: parent; text: "★"; color: root.addPriority ? root.accent : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.55); font.pixelSize: Style.font.body }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.addPriority = !root.addPriority }
          }
        }

        PanelSeparator { foreground: root.fg }
        PanelSectionHeader { text: "WELLBEING"; foreground: root.fg; fontFamily: root.family }
        Row {
          width: parent.width; spacing: Style.space(10)
          MetricCard { width: (parent.width - parent.spacing) / 2; title: "SCREEN TIME"; value: root.store ? root.store.screenLabel : "0m"; detail: root.screenGoalHours > 0 ? "Guide: " + root.screenGoalHours + "h" : "No daily guide"; ratio: root.screenGoalHours > 0 && root.store ? Math.min(1, root.store.screenTimeMs / (root.screenGoalHours * 3600000)) : 0 }
          MetricCard { width: (parent.width - parent.spacing) / 2; title: "REMINDERS"; value: root.store ? String(root.store.reminders.length) : "0"; detail: root.store && root.store.reminders.length ? root.store.reminders[0].label + " · " + root.store.reminders[0].remaining : "Nothing outstanding"; ratio: 0 }
        }

        Row {
          width: parent.width; spacing: Style.space(8)
          TextField { id: reminderMinutes; width: Style.space(74); foreground: root.fg; accent: root.accent; placeholderText: "min"; validator: IntValidator { bottom: 1; top: 1440 } }
          TextField { id: reminderText; width: parent.width - reminderMinutes.width - remindButton.width - parent.spacing * 2; foreground: root.fg; accent: root.accent; placeholderText: "Reminder message"; onAccepted: remindButton.trigger() }
          ActionButton {
            id: remindButton; text: "Set"; glyph: "󰢌"
            function trigger() {
              var mins = parseInt(reminderMinutes.text, 10)
              if (!isFinite(mins) || mins < 1) return
              Util.execArgv(["omarchy-reminder", String(mins), reminderText.text.trim()])
              reminderMinutes.text = ""; reminderText.text = ""
              reminderRefresh.restart()
            }
            onTriggered: trigger()
          }
          Timer { id: reminderRefresh; interval: 500; onTriggered: if (root.store) root.store.refreshReminders() }
        }

        Text { width: parent.width; text: "a add · f start/pause · r reset · c clear completed"; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.38); font.family: root.family; font.pixelSize: Style.font.caption; elide: Text.ElideRight }
      }
    }
  }

  component ActionButton: Rectangle {
    id: action
    property string text: ""
    property string glyph: ""
    signal triggered()
    implicitWidth: labelRow.implicitWidth + Style.space(18)
    implicitHeight: Style.spacing.popupRowHeight
    radius: Style.cornerRadius
    color: hover.containsMouse ? Style.hoverFillFor(root.fg, root.fg) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.07)
    Row {
      id: labelRow
      anchors.centerIn: parent
      spacing: Style.space(6)
      Text {
        text: action.glyph
        color: root.fg
        font.family: Style.font.icon
        font.pixelSize: Style.font.body
      }
      Text {
        text: action.text
        color: root.fg
        font.family: root.family
        font.pixelSize: Style.font.bodySmall
        font.bold: true
      }
    }
    MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: action.triggered() }
  }

  component TaskRow: Item {
    id: row
    property var task: null
    implicitHeight: Style.spacing.popupRowHeight
    Rectangle { anchors.fill: parent; radius: Style.cornerRadius; color: hover.containsMouse ? Style.hoverFillFor(root.fg, root.fg) : "transparent" }
    MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton; cursorShape: Qt.PointingHandCursor; onClicked: function(mouse) { if (!root.store || !row.task) return; if (mouse.button === Qt.RightButton) root.store.togglePriority(row.task.id); else root.store.toggleTask(row.task.id) } }
    Rectangle { id: check; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: Style.space(16); height: width; radius: row.task && row.task.priority ? width / 2 : Style.space(3); color: row.task && row.task.done ? root.accent : "transparent"; border.width: 1; border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.55); Text { anchors.centerIn: parent; visible: row.task && row.task.done; text: "✓"; color: Color.popups.background; font.pixelSize: Style.font.caption; font.bold: true } }
    Text { anchors.left: check.right; anchors.leftMargin: Style.space(9); anchors.right: remove.left; anchors.verticalCenter: parent.verticalCenter; text: (row.task && row.task.priority ? "★  " : "") + (row.task ? row.task.text : ""); color: root.fg; opacity: row.task && row.task.done ? 0.42 : 1; font.family: root.family; font.pixelSize: Style.font.body; font.strikeout: row.task && row.task.done; elide: Text.ElideRight }
    Text { id: remove; visible: hover.containsMouse; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: "󰆴"; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.55); font.family: Style.font.icon; font.pixelSize: Style.font.body; MouseArea { anchors.fill: parent; anchors.margins: -Style.space(8); cursorShape: Qt.PointingHandCursor; onClicked: if (root.store && row.task) root.store.removeTask(row.task.id) } }
  }

  component MetricCard: Rectangle {
    property string title: ""
    property string value: ""
    property string detail: ""
    property real ratio: 0
    implicitHeight: Style.space(82)
    radius: Style.cornerRadius
    color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06)
    Column {
      anchors.fill: parent
      anchors.margins: Style.space(10)
      spacing: Style.space(3)
      Text {
        text: parent.parent.title
        color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.48)
        font.family: root.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }
      Text {
        text: parent.parent.value
        color: root.fg
        font.family: root.family
        font.pixelSize: Style.font.title
        font.bold: true
      }
      Text {
        width: parent.width
        text: parent.parent.detail
        color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.52)
        font.family: root.family
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
    }
    Rectangle { visible: parent.ratio > 0; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: Style.space(3); radius: height / 2; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1); Rectangle { height: parent.height; width: parent.width * parent.parent.ratio; radius: height / 2; color: root.accent } }
  }
}
