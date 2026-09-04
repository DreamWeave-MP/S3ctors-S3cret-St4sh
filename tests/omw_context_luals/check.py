import os
import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parent
SERVER = os.environ.get('LUA_LANGUAGE_SERVER', 'lua-language-server')
EXPECTED = {
    '__OMW_CONTEXT_ERROR_global_cannot_use_openmw_interfaces_AnimationController__',
    '__OMW_CONTEXT_ERROR_local_cannot_use_openmw_interfaces_Activation__',
    '__OMW_CONTEXT_ERROR_player_cannot_use_openmw_interfaces_Projectiles__',
}


def main():
    result = subprocess.run(
        [
            SERVER,
            '--force-accept-workspace',
            f'--configpath={ROOT / ".luarc.json"}',
            f'--check={ROOT}',
            '--checklevel=Information',
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    output = result.stdout + result.stderr
    found = set(re.findall(r'Undefined global `(__OMW_CONTEXT_ERROR_[^`]+)`', output))

    if result.returncode == 0:
        raise SystemExit('LuaLS unexpectedly accepted the invalid interface uses')
    if found != EXPECTED:
        raise SystemExit(f'expected {sorted(EXPECTED)}, found {sorted(found)}\n{output}')
    if output.count('(param-type-mismatch)') != 1:
        raise SystemExit(f'expected one preserved downstream interface type\n{output}')
    if 'exp-in-action' in output or 'syntax error' in output:
        raise SystemExit(f'fixture contains an unintended syntax diagnostic\n{output}')

    print('LuaLS context integration fixture passed')


if __name__ == '__main__':
    main()
