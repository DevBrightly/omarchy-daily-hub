.pragma library

function pad(n) { return String(n).padStart(2, "0") }

function dayKey(date) {
  var d = date || new Date()
  return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
}

function clean(text, limit) {
  return String(text || "").replace(/\s+/g, " ").trim().slice(0, limit || 280)
}

function uid() {
  return Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 8)
}

function clone(value) { return JSON.parse(JSON.stringify(value)) }

function emptyState(date, focusSeconds) {
  return {
    version: 2,
    date: date,
    tasks: [],
    focus: { mode: "focus", remaining: focusSeconds, running: false, endAt: 0, sessions: 0 },
    archive: {}
  }
}

function normalizeTask(task, index) {
  var source = task && typeof task === "object" ? task : {}
  return {
    id: clean(source.id, 100) || uid(),
    text: clean(source.text),
    description: clean(source.description, 1000),
    done: source.done === true,
    priority: source.priority === true,
    stage: source.stage === "later" ? "later" : "today",
    carried: Math.max(0, Number(source.carried) || 0),
    order: isFinite(Number(source.order)) ? Number(source.order) : index,
    createdAt: Math.max(0, Number(source.createdAt) || Date.now()),
    completedAt: Math.max(0, Number(source.completedAt) || 0)
  }
}

function normalize(raw, date, focusSeconds) {
  var parsed
  try { parsed = raw ? JSON.parse(raw) : null } catch (e) { parsed = null }
  if (!parsed || typeof parsed !== "object") return emptyState(date, focusSeconds)
  parsed.version = 2
  parsed.tasks = (Array.isArray(parsed.tasks) ? parsed.tasks : []).map(normalizeTask)
  parsed.archive = parsed.archive && typeof parsed.archive === "object" ? parsed.archive : {}
  parsed.focus = parsed.focus && typeof parsed.focus === "object" ? parsed.focus : {}
  parsed.focus.mode = parsed.focus.mode === "break" ? "break" : "focus"
  parsed.focus.remaining = Math.max(0, Number(parsed.focus.remaining) || focusSeconds)
  parsed.focus.running = parsed.focus.running === true
  parsed.focus.endAt = Math.max(0, Number(parsed.focus.endAt) || 0)
  parsed.focus.sessions = Math.max(0, Number(parsed.focus.sessions) || 0)
  enforceBigThree(parsed.tasks)
  return rollDay(parsed, date, focusSeconds)
}

function enforceBigThree(tasks) {
  var count = 0
  tasks.slice().sort(function(a, b) { return a.order - b.order }).forEach(function(task) {
    if (task.stage !== "today" || !task.priority) return
    count++
    if (count > 3) task.priority = false
  })
}

function rollDay(state, date, focusSeconds) {
  if (state.date === date) return state
  var next = clone(state)
  if (state.date) {
    var s = stats(state.tasks)
    next.archive[state.date] = { done: s.done, total: s.total, priorityDone: s.priorityDone, focusSessions: state.focus.sessions || 0 }
  }
  next.date = date
  next.tasks = state.tasks.filter(function(task) {
    return task.stage === "later" || !task.done
  }).map(function(task, index) {
    var normalized = normalizeTask(task, index)
    normalized.done = false
    normalized.completedAt = 0
    if (normalized.stage === "today") normalized.carried += 1
    return normalized
  })
  next.focus = { mode: "focus", remaining: focusSeconds, running: false, endAt: 0, sessions: 0 }
  return next
}

function priorityCount(tasks, exceptId) {
  return tasks.filter(function(task) {
    return task.id !== exceptId && task.stage === "today" && task.priority
  }).length
}

function addTask(state, text, priority, stage, description) {
  var value = clean(text)
  if (!value) return state
  var next = clone(state)
  var target = stage === "later" ? "later" : "today"
  var isPriority = priority === true && target === "today" && priorityCount(next.tasks) < 3
  next.tasks.push({
    id: uid(), text: value, description: clean(description, 1000), done: false,
    priority: isPriority, stage: target, carried: 0, order: next.tasks.length,
    createdAt: Date.now(), completedAt: 0
  })
  return next
}

function toggleTask(state, id) {
  var next = clone(state)
  next.tasks.forEach(function(task) {
    if (task.id !== id) return
    task.done = !task.done
    task.completedAt = task.done ? Date.now() : 0
  })
  return next
}

function removeTask(state, id) {
  var next = clone(state)
  next.tasks = next.tasks.filter(function(task) { return task.id !== id })
  return next
}

function togglePriority(state, id) {
  var next = clone(state)
  next.tasks.forEach(function(task) {
    if (task.id !== id || task.stage !== "today") return
    if (task.priority) task.priority = false
    else if (priorityCount(next.tasks, id) < 3) task.priority = true
  })
  return next
}

function updateTask(state, id, text, description) {
  var value = clean(text)
  if (!value) return state
  var next = clone(state)
  next.tasks.forEach(function(task) {
    if (task.id === id) { task.text = value; task.description = clean(description, 1000) }
  })
  return next
}

function moveTask(state, id, stage) {
  var target = stage === "later" ? "later" : "today"
  var next = clone(state)
  next.tasks.forEach(function(task) {
    if (task.id !== id) return
    task.stage = target
    task.done = false
    task.completedAt = 0
    if (target === "later") task.priority = false
  })
  return next
}

function reorderTask(state, id, direction) {
  var next = clone(state)
  var current = -1
  for (var i = 0; i < next.tasks.length; i++) if (next.tasks[i].id === id) current = i
  if (current < 0) return state
  var task = next.tasks[current]
  var candidates = []
  for (var j = 0; j < next.tasks.length; j++) if (next.tasks[j].stage === task.stage) candidates.push(j)
  var position = candidates.indexOf(current)
  var targetPosition = position + (direction < 0 ? -1 : 1)
  if (targetPosition < 0 || targetPosition >= candidates.length) return state
  var other = candidates[targetPosition]
  var swap = next.tasks[current].order
  next.tasks[current].order = next.tasks[other].order
  next.tasks[other].order = swap
  next.tasks.sort(function(a, b) { return a.order - b.order })
  next.tasks.forEach(function(item, index) { item.order = index })
  return next
}

function clearCompleted(state) {
  var next = clone(state)
  next.tasks = next.tasks.filter(function(task) { return !task.done })
  return next
}

function stats(tasks) {
  var list = (Array.isArray(tasks) ? tasks : []).filter(function(task) { return task.stage !== "later" })
  var done = 0
  var priorityTotal = 0
  var priorityDone = 0
  list.forEach(function(task) {
    if (task.done) done++
    if (task.priority) { priorityTotal++; if (task.done) priorityDone++ }
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
