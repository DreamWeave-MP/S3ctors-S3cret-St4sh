import { strict as assert } from "node:assert";
import { parseDiagnostics } from "../tools/tools/luals-check-openmw.ts";

const ansi = "\u001b[34m";
const reset = "\u001b[0m";
const warning = "\u001b[33mWarning\u001b[0m";
const code = "\u001b[35m(undefined-global)\u001b[0m";

const output = [
  `${ansi}tests/omw_context_luals/cases/global_interfaces.lua:11:37${reset} [${warning}] Undefined global \`__OMW_CONTEXT_ERROR_global_cannot_use_openmw_interfaces_AnimationController__\`. ${code}`,
  "    local interfaces = require 'openmw.interfaces'",
  `${ansi}tests/omw_context_luals/cases/player_interfaces.lua:17:48${reset} [${warning}] Cannot assign integer to parameter string.",
  "- integer cannot match string",
  "- Type number cannot match string \u001b[35m(param-type-mismatch)\u001b[0m",
  "    local result = interfaces.MyMod.doThing(42)",
].join("\n");

const diagnostics = parseDiagnostics(output, "", process.cwd());

assert.equal(diagnostics.length, 2);
assert.deepEqual(
  diagnostics.map(({ file, line, column, code: diagnosticCode, category }) => ({ file, line, column, code: diagnosticCode, category })),
  [
    {
      file: "tests/omw_context_luals/cases/global_interfaces.lua",
      line: 11,
      column: 37,
      code: "undefined-global",
      category: "contextPluginDiagnostics",
    },
    {
      file: "tests/omw_context_luals/cases/player_interfaces.lua",
      line: 17,
      column: 48,
      code: "param-type-mismatch",
      category: "annotationIssues",
    },
  ],
);

console.log("LuaLS diagnostic parser test passed");
