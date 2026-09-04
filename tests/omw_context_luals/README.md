# OpenMW context LuaLS fixture

Run from the repository root:

```sh
python3 tests/omw_context_luals/check.py
```

The fixture owns its workspace root so the relative plugin and library paths
resolve against the fixture rather than against whichever directory LuaLS is
asked to check. The invalid interface accesses are intentional; the checker
expects their Cod3x context diagnostics and rejects unrelated diagnostics.

Cod3x does not validate context compatibility between arbitrary user modules.
LuaLS may process an importing file before the imported module, and its plugin
API has no reliable post-resolution diagnostic hook for this rule.
