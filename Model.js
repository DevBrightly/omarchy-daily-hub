.pragma library

function pad(n) { return String(n).padStart(2, "0") }

function dayKey(date) {
  var d = date || new Date()
  return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
}

function clean(text) {
  return String(text || "").replace(/\s+/g, " ").trim().slice(0, 280)
}

function uid() {
  return Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 8)
}

function emptyState(date, focusSeconds) {
  return {
    version: 1,
    date: date,
    tasks: [],
    focus: {
      mode: "focus",
      remaining: focusSeconds,
      running: false,
      endAt: 0,
      sessions: 0
    },
    archive: {}
  }
}

function normalize(raw, date, focusSeconds) {
  var parsed
  try { parsed = raw ? JSON.parse(raw) : null } catch (e) { parsed = null }
  if (!parsed || typeof parsed !== "object") return emptyState(date, focusSeconds)
  parsed.version = 1
  parsed.tasks = Array.isArray(parsed.tasks) ? parsed.tasks : []
  parsed.archive = parsed.archive && typeof parsed.archive === "object" ? parsed.archive : {}
  parsed.focus = parsed.focus && typeof parsed.focus === "object" ? parsed.focus : {}
  parsed.focus.mode = parsed.focus.mode === "break" ? "break" : "focus"
  parsed.focus.remaining = Math.max(0, Number(parsed.focus.remaining) || focusSeconds)
  parsed.focus.running = parsed.focus.running === true
  parsed.focus.endAt = Math.max(0, Number(parsed.focus.endAt) || 0)
  parsed.focus.sessions = Math.max(0, Number(parsed.focus.sessions) || 0)
  return rollDay(parsed, date, focusSeconds)
}

function rollDay(state, date, focusSeconds) {
  if (state.date === date) return state
  var next = JSON.parse(JSON.stringify(state))
  if (state.date) {
    var s = stats(state.tasks)
    next.archive[state.date] = { done: s.done, total: s.total, focusSessions: state.focus.sessions || 0 }
  }
  next.date = date
  next.tasks = state.tasks.filter(function(t) { return !t.done }).map(function(t) {
    return { id: t.id || uid(), text: clean(t.text), done: false, priority: t.priority === true, carried: (t.carried || 0) + 1 }
  })
  next.focus = { mode: "focus", remaining: focusSeconds, running: false, endAt: 0, sessions: 0 }
  return next
}

function addTask(state, text, priority) {
  var value = clean(text)
  if (!value) return state
  var next = JSON.parse(JSON.stringify(state))
  next.tasks.push({ id: uid(), text: value, done: false, priority: priority === true, carried: 0 })
  return next
}

function toggleTask(state, id) {
  var next = JSON.parse(JSON.stringify(state))
  next.tasks.forEach(function(t) { if (t.id === id) t.done = !t.done })
  return next
}

function removeTask(state, id) {
  var next = JSON.parse(JSON.stringify(state))
  next.tasks = next.tasks.filter(function(t) { return t.id !== id })
  return next
}

function togglePriority(state, id) {
  var next = JSON.parse(JSON.stringify(state))
  next.tasks.forEach(function(t) { if (t.id === id) t.priority = !t.priority })
  return next
}

function clearCompleted(state) {
  var next = JSON.parse(JSON.stringify(state))
  next.tasks = next.tasks.filter(function(t) { return !t.done })
  return next
}

function stats(tasks) {
  var list = Array.isArray(tasks) ? tasks : []
  var done = 0
  var priorityTotal = 0
  var priorityDone = 0
  list.forEach(function(t) {
    if (t.done) done++
    if (t.priority) { priorityTotal++; if (t.done) priorityDone++ }
  })
  return { total: list.length, done: done, ratio: list.length ? done / list.length : 0,
    priorityTotal: priorityTotal, priorityDone: priorityDone }
}

function dayFraction(now, startHour, endHour) {
  var d = now || new Date()
  var start = new Date(d.getFullYear(), d.getMonth(), d.getDate(), startHour, 0, 0).getTime()
  var end = new Date(d.getFullYear(), d.getMonth(), d.getDate(), endHour, 0, 0).getTime()
  if (end <= start) end += 86400000
  return Math.max(0, Math.min(1, (d.getTime() - start) / (end - start)))
}

function clock(seconds) {
  var n = Math.max(0, Math.ceil(Number(seconds) || 0))
  return pad(Math.floor(n / 60)) + ":" + pad(n % 60)
}

function duration(ms) {
  var minutes = Math.floor(Math.max(0, Number(ms) || 0) / 60000)
  var hours = Math.floor(minutes / 60)
  var mins = minutes % 60
  return hours > 0 ? hours + "h " + mins + "m" : mins + "m"
}
