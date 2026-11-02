const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const panel = fs.readFileSync(path.join(__dirname, "..", "Panel.qml"), "utf8");

test("quick capture has explicit completion and cancellation actions", () => {
  assert.match(panel, /function completeCapture\(\)/);
  assert.match(panel, /if \(!store \|\| !capturedText\) return/);
  assert.match(panel, /store\.addTask\(capturedText, addPriority, addStage, ""\)/);
  assert.match(panel, /function cancelCapture\(\)/);
  assert.match(panel, /onAccepted: root\.completeCapture\(\)/);
  assert.match(panel, /Keys\.priority: Keys\.BeforeItem/);
  assert.match(panel, /event\.key === Qt\.Key_Escape/);
  assert.match(panel, /root\.cancelCapture\(\)/);
});

test("closing the panel clears an abandoned quick-capture draft", () => {
  assert.match(panel, /function close\(\) \{\s*taskInput\.text = ""\s*controller\.hide\(\)/);
});
