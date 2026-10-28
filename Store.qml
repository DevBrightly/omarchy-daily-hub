import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

Item {
  id: root

  property int dayStartHour: 8
  property int dayEndHour: 22
  property int focusMinutes: 25
  property int breakMinutes: 5

  readonly property string dataDir: Quickshell.env("HOME") + "/.local/share/br-daily-hub"
  readonly property string statePath: dataDir + "/state.json"
  readonly property string screenPath: Quickshell.env("HOME") + "/.local/share/omarchy-screentime/history.json"
  property string todayKey: Model.dayKey(new Date())
  property date now: new Date()
  property var dailyData: Model.emptyState(todayKey, focusMinutes * 60)
  property bool ready: false
  property bool directoryReady: false
  property bool writePending: false
  property bool initialReadComplete: false
  property double screenTimeMs: 0
  property var reminders: []

  readonly property var tasks: dailyData.tasks || []
  readonly property var stats: Model.stats(tasks)
  readonly property real dayFraction: Model.dayFraction(now, dayStartHour, dayEndHour)
  readonly property string pomodoroText: Model.clock(dailyData.focus.remaining)
  readonly property string screenLabel: Model.duration(screenTimeMs)

  signal focusFinished(string mode)

  function cloneState() { return JSON.parse(JSON.stringify(dailyData)) }
  function persist() {
    if (!directoryReady) { writePending = true; return }
    writePending = false
    stateFile.setText(JSON.stringify(dailyData, null, 2) + "\n")
  }
  function mutate(next) { dailyData = next; persist() }
  function addTask(text, priority, stage, description) { mutate(Model.addTask(dailyData, text, priority, stage, description)) }
  function toggleTask(id) { mutate(Model.toggleTask(dailyData, id)) }
  function removeTask(id) { mutate(Model.removeTask(dailyData, id)) }
  function togglePriority(id) { mutate(Model.togglePriority(dailyData, id)) }
  function updateTask(id, text, description) { mutate(Model.updateTask(dailyData, id, text, description)) }
  function moveTask(id, stage) { mutate(Model.moveTask(dailyData, id, stage)) }
  function reorderTask(id, direction) { mutate(Model.reorderTask(dailyData, id, direction)) }
  function clearCompleted() { mutate(Model.clearCompleted(dailyData)) }

  function setFocusRunning(running) {
    var next = cloneState()
    next.focus.running = running
    next.focus.endAt = running ? Date.now() + next.focus.remaining * 1000 : 0
    mutate(next)
  }
  function toggleFocus() { setFocusRunning(!dailyData.focus.running) }
  function resetFocus() {
    var next = cloneState()
    next.focus.running = false
    next.focus.endAt = 0
    next.focus.remaining = (next.focus.mode === "break" ? breakMinutes : focusMinutes) * 60
    mutate(next)
  }
  function switchFocusMode() {
    var next = cloneState()
    next.focus.mode = next.focus.mode === "focus" ? "break" : "focus"
    next.focus.running = false
    next.focus.endAt = 0
    next.focus.remaining = (next.focus.mode === "break" ? breakMinutes : focusMinutes) * 60
    mutate(next)
  }
  function focusTick() {
    if (!dailyData.focus.running) return
    var next = cloneState()
    next.focus.remaining = Math.max(0, Math.ceil((next.focus.endAt - Date.now()) / 1000))
    if (next.focus.remaining <= 0) {
      var finishedMode = next.focus.mode
      if (finishedMode === "focus") next.focus.sessions = (next.focus.sessions || 0) + 1
      next.focus.mode = finishedMode === "focus" ? "break" : "focus"
      next.focus.remaining = (next.focus.mode === "break" ? breakMinutes : focusMinutes) * 60
      next.focus.running = false
      next.focus.endAt = 0
      dailyData = next
      persist()
      focusFinished(finishedMode)
    } else {
      dailyData = next
    }
  }

  function refreshState() {
    if (!directoryReady || stateReader.running) return
    stateReader.running = true
  }

  function adopt(raw, persistMigration) {
    dailyData = Model.normalize(raw, todayKey, focusMinutes * 60)
    if (dailyData.focus.running && dailyData.focus.endAt > 0) {
      var next = cloneState()
      next.focus.remaining = Math.max(0, Math.ceil((next.focus.endAt - Date.now()) / 1000))
      dailyData = next
    }
    ready = true
    if (persistMigration) persist()
  }

  function refreshScreenTime() { screenReader.running = false; screenReader.running = true }
  function refreshReminders() { reminderReader.running = false; reminderReader.running = true }

  Timer { interval: 1000; repeat: true; running: true; onTriggered: {
    root.now = new Date()
    root.focusTick()
    var key = Model.dayKey(root.now)
    if (key !== root.todayKey) {
      root.todayKey = key
      root.dailyData = Model.rollDay(root.dailyData, key, root.focusMinutes * 60)
      root.persist(); root.refreshScreenTime()
    }
  } }
  Timer { interval: 30000; repeat: true; running: true; onTriggered: root.refreshReminders() }
  Timer { interval: 60000; repeat: true; running: true; onTriggered: root.refreshScreenTime() }
  Timer { id: stateSync; interval: 80; repeat: false; onTriggered: root.refreshState() }

  FileView {
    id: stateFile
    path: root.statePath
    preload: false
    atomicWrites: true
    watchChanges: true
    printErrors: false
    onFileChanged: if (root.initialReadComplete) stateSync.restart()
  }
  FileView { path: root.screenPath; preload: false; watchChanges: true; printErrors: false; onFileChanged: root.refreshScreenTime() }

  Process {
    id: ensureDir
    command: ["mkdir", "-p", root.dataDir]
    onExited: { root.directoryReady = true; stateReader.running = true }
  }
  Process {
    id: stateReader
    command: ["sh", "-c", "[ -e \"$1\" ] || exit 3; [ \"$(wc -c < \"$1\")\" -le 1048576 ] || exit 4; exec head -c 1048576 -- \"$1\"", "sh", root.statePath]
    stdout: StdioCollector { id: stateOut; waitForEnd: true }
    onExited: function(code) {
      var firstRead = !root.initialReadComplete
      root.adopt(code === 0 ? stateOut.text : "", firstRead)
      root.initialReadComplete = true
    }
  }
  Process {
    id: screenReader
    command: ["sh", "-c", "[ -e \"$1\" ] || exit 3; [ \"$(wc -c < \"$1\")\" -le 4194304 ] || exit 4; exec head -c 4194304 -- \"$1\"", "sh", root.screenPath]
    stdout: StdioCollector { id: screenOut; waitForEnd: true }
    onExited: function(code) {
      if (code !== 0) { root.screenTimeMs = 0; return }
      try {
        var parsed = JSON.parse(screenOut.text)
        var day = parsed.days && parsed.days[root.todayKey] ? parsed.days[root.todayKey] : null
        root.screenTimeMs = day ? Number(day.total || 0) : 0
      } catch (e) { root.screenTimeMs = 0 }
    }
  }
  Process {
    id: reminderReader
    command: ["omarchy-reminder", "show", "--json"]
    stdout: StdioCollector { id: reminderOut; waitForEnd: true }
    onExited: function(code) {
      if (code !== 0) { root.reminders = []; return }
      try { root.reminders = JSON.parse(reminderOut.text).reminders || [] } catch (e) { root.reminders = [] }
    }
  }

  Component.onCompleted: { ensureDir.running = true; refreshScreenTime(); refreshReminders() }
}
