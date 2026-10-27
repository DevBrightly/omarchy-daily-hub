const test = require("node:test");
const assert = require("node:assert/strict");
const { loadModel } = require("./helpers");

const DATE = "2026-10-27";
const NEXT_DATE = "2026-10-28";
const FOCUS_SECONDS = 25 * 60;

test("migrates version 1 tasks without losing user data", () => {
  const model = loadModel();
  const legacy = {
    version: 1,
    date: DATE,
    tasks: [{ id: "legacy", text: " Existing task ", done: false, priority: true, carried: 2 }],
    focus: { mode: "focus", remaining: FOCUS_SECONDS, sessions: 1 },
    archive: {},
  };

  const state = model.normalize(JSON.stringify(legacy), DATE, FOCUS_SECONDS);

  assert.equal(state.version, 2);
  assert.equal(state.tasks[0].id, "legacy");
  assert.equal(state.tasks[0].text, "Existing task");
  assert.equal(state.tasks[0].stage, "today");
  assert.equal(state.tasks[0].description, "");
  assert.equal(state.tasks[0].carried, 2);
  assert.equal(state.focus.sessions, 1);
});

test("enforces a maximum of three Big 3 priorities", () => {
  const model = loadModel();
  let state = model.emptyState(DATE, FOCUS_SECONDS);

  for (const title of ["One", "Two", "Three", "Four"]) {
    state = model.addTask(state, title, true, "today", "");
  }

  assert.equal(model.stats(state.tasks).priorityTotal, 3);
  assert.equal(state.tasks.find((task) => task.text === "Four").priority, false);
});

test("moves tasks between Today and Later and clears invalid state", () => {
  const model = loadModel();
  let state = model.addTask(model.emptyState(DATE, FOCUS_SECONDS), "Plan release", true, "today", "");
  const id = state.tasks[0].id;

  state = model.toggleTask(state, id);
  state = model.moveTask(state, id, "later");

  assert.equal(state.tasks[0].stage, "later");
  assert.equal(state.tasks[0].priority, false);
  assert.equal(state.tasks[0].done, false);
  assert.equal(state.tasks[0].completedAt, 0);

  state = model.moveTask(state, id, "today");
  assert.equal(state.tasks[0].stage, "today");
});

test("carries unfinished Today tasks but not Later tasks", () => {
  const model = loadModel();
  let state = model.emptyState(DATE, FOCUS_SECONDS);
  state = model.addTask(state, "Today task", false, "today", "");
  state = model.addTask(state, "Backlog task", false, "later", "");

  const rolled = model.rollDay(state, NEXT_DATE, FOCUS_SECONDS);

  assert.equal(rolled.tasks.find((task) => task.text === "Today task").carried, 1);
  assert.equal(rolled.tasks.find((task) => task.text === "Backlog task").carried, 0);
  assert.equal(rolled.archive[DATE].total, 1);
});

test("archives completed Today tasks and removes them after rollover", () => {
  const model = loadModel();
  let state = model.addTask(model.emptyState(DATE, FOCUS_SECONDS), "Ship it", true, "today", "");
  state = model.toggleTask(state, state.tasks[0].id);

  assert.equal(state.tasks[0].done, true);
  assert.ok(state.tasks[0].completedAt > 0);

  const rolled = model.rollDay(state, NEXT_DATE, FOCUS_SECONDS);
  assert.equal(rolled.tasks.length, 0);
  assert.equal(rolled.archive[DATE].done, 1);
  assert.equal(rolled.archive[DATE].priorityDone, 1);
});

test("edits descriptions and reorders tasks without changing identity", () => {
  const model = loadModel();
  let state = model.emptyState(DATE, FOCUS_SECONDS);
  state = model.addTask(state, "First", false, "today", "");
  state = model.addTask(state, "Second", false, "today", "");
  const secondId = state.tasks[1].id;

  state = model.updateTask(state, secondId, "Updated second", "Useful context");
  state = model.reorderTask(state, secondId, -1);

  assert.equal(state.tasks[0].id, secondId);
  assert.equal(state.tasks[0].text, "Updated second");
  assert.equal(state.tasks[0].description, "Useful context");
});

test("normalizes malformed persisted state safely", () => {
  const model = loadModel();
  const state = model.normalize("not json", DATE, FOCUS_SECONDS);

  assert.equal(state.version, 2);
  assert.deepEqual(Array.from(state.tasks), []);
  assert.equal(state.focus.remaining, FOCUS_SECONDS);
});
