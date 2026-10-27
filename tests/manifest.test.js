const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const root = path.join(__dirname, "..");
const manifest = JSON.parse(fs.readFileSync(path.join(root, "manifest.json"), "utf8"));

test("manifest has the marketplace-required metadata", () => {
  assert.equal(manifest.schemaVersion, 1);
  assert.equal(manifest.id, "io.github.devbrightly.daily-hub");
  assert.match(manifest.version, /^\d+\.\d+\.\d+$/);

  for (const field of ["name", "author", "description", "license"]) {
    assert.equal(typeof manifest[field], "string");
    assert.ok(manifest[field].trim(), `${field} must not be empty`);
  }
});

test("every declared plugin kind has an existing entry point", () => {
  const keys = {
    "bar-widget": "barWidget",
    panel: "panel",
    overlay: "overlay",
    menu: "menu",
    service: "service",
    bar: "bar",
  };

  for (const kind of manifest.kinds) {
    const key = keys[kind];
    assert.ok(key, `unsupported plugin kind: ${kind}`);
    assert.ok(manifest.entryPoints[key], `missing entry point for ${kind}`);
    assert.ok(fs.existsSync(path.join(root, manifest.entryPoints[key])), `entry point does not exist: ${manifest.entryPoints[key]}`);
  }
});

test("repository contains no symbolic links", () => {
  function inspect(directory) {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      if (entry.name === ".git") continue;
      const target = path.join(directory, entry.name);
      assert.equal(entry.isSymbolicLink(), false, `symbolic link is not marketplace-safe: ${target}`);
      if (entry.isDirectory()) inspect(target);
    }
  }

  inspect(root);
});
