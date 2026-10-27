const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

function loadModel() {
  const source = fs
    .readFileSync(path.join(__dirname, "..", "Model.js"), "utf8")
    .replace(/^\.pragma library\s*/, "");
  const context = {
    Array,
    Date,
    JSON,
    Math,
    Number,
    Object,
    String,
    isFinite,
  };

  vm.createContext(context);
  vm.runInContext(source, context, { filename: "Model.js" });
  return context;
}

module.exports = { loadModel };
