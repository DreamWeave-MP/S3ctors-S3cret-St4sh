import os
import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parent
REPOSITORY = ROOT.parents[1]
SERVER = os.environ.get('LUA_LANGUAGE_SERVER', 'lua-language-server')
EXPECTED = {
    'cases/global_interfaces.lua': {
        ('__OMW_CONTEXT_ERROR_global_cannot_use_openmw_interfaces_AnimationController__', 'undefined-global'),
        ('__OMW_CONTEXT_ERROR_global_cannot_use_openmw_interfaces_AI__', 'undefined-global'),
        ('__OMW_CONTEXT_ERROR_global_cannot_use_openmw_interfaces_Camera__', 'undefined-global'),
        ('__OMW_CONTEXT_ERROR_global_cannot_use_openmw_interfaces_MWUI__', 'undefined-global'),
        ('__OMW_CONTEXT_ERROR_global_cannot_use_openmw_interfaces_UI__', 'undefined-global'),
        ('__OMW_CONTEXT_ERROR_global_cannot_use_openmw_interfaces_SkillProgression__', 'undefined-global'),
        ('__OMW_CONTEXT_ERROR_global_cannot_use_openmw_interfaces_Controls__', 'undefined-global'),
        ('__OMW_CONTEXT_ERROR_global_cannot_use_openmw_interfaces_GamepadControls__', 'undefined-global'),
    },
    'cases/local_interfaces.lua': {
        ('__OMW_CONTEXT_ERROR_local_cannot_use_openmw_interfaces_Activation__', 'undefined-global'),
        ('__OMW_CONTEXT_ERROR_local_cannot_use_openmw_interfaces_Camera__', 'undefined-global'),
        ('__OMW_CONTEXT_ERROR_local_cannot_use_openmw_interfaces_MWUI__', 'undefined-global'),
        ('__OMW_CONTEXT_ERROR_local_cannot_use_openmw_interfaces_UI__', 'undefined-global'),
        ('__OMW_CONTEXT_ERROR_local_cannot_use_openmw_interfaces_Projectiles__', 'undefined-global'),
    },
    'cases/player_interfaces.lua': {
        ('__OMW_CONTEXT_ERROR_player_cannot_use_openmw_interfaces_Activation__', 'undefined-global'),
        ('__OMW_CONTEXT_ERROR_player_cannot_use_openmw_interfaces_AI__', 'undefined-global'),
        ('__OMW_CONTEXT_ERROR_player_cannot_use_openmw_interfaces_Projectiles__', 'undefined-global'),
        ('MyMod', 'param-type-mismatch'),
    },
    'cases/menu_interfaces.lua': {
        ('__OMW_CONTEXT_ERROR_menu_cannot_use_openmw_interfaces_Activation__', 'undefined-global'),
        ('__OMW_CONTEXT_ERROR_menu_cannot_use_openmw_interfaces_Combat__', 'undefined-global'),
        ('__OMW_CONTEXT_ERROR_menu_cannot_use_openmw_interfaces_Projectiles__', 'undefined-global'),
        ('__OMW_CONTEXT_ERROR_menu_cannot_use_openmw_interfaces_UI__', 'undefined-global'),
    },
}

DIAGNOSTIC = re.compile(
    r'^(?P<path>.+?):(?P<line>\d+):(?P<column>\d+) .*?\((?P<code>[^)]+)\)$'
)
POISON = re.compile(r'Undefined global `(?P<name>__OMW_CONTEXT_ERROR_[^`]+)`')


def normalize_path(path):
    candidate = Path(path)
    if not candidate.is_absolute():
        candidate = REPOSITORY / candidate
    try:
        return candidate.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return candidate.as_posix()


def parse_diagnostics(output):
    diagnostics = []
    for raw_line in output.splitlines():
        line = re.sub(r'\x1b\[[0-9;]*m', '', raw_line).strip()
        match = DIAGNOSTIC.match(line)
        if not match:
            continue

        poison = POISON.search(line)
        diagnostics.append(
            (
                normalize_path(match.group('path')),
                int(match.group('line')),
                int(match.group('column')),
                poison.group('name') if poison else 'MyMod' if match.group('code') == 'param-type-mismatch' else None,
                match.group('code'),
            )
        )
    return diagnostics


def main():
    try:
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
            cwd=REPOSITORY,
            timeout=float(os.environ.get('LUA_LANGUAGE_SERVER_TIMEOUT', '120')),
        )
    except FileNotFoundError as error:
        raise SystemExit(f'LuaLS executable not found: {SERVER}') from error
    except subprocess.TimeoutExpired as error:
        raise SystemExit(f'LuaLS timed out after {error.timeout} seconds') from error

    output = result.stdout + result.stderr
    diagnostics = parse_diagnostics(output)
    found = {
        (path, name, code)
        for path, _line, _column, name, code in diagnostics
        if name is not None
    }
    expected = {
        (path, name, code)
        for path, entries in EXPECTED.items()
        for name, code in entries
    }

    if result.returncode == 0:
        raise SystemExit('LuaLS unexpectedly accepted the invalid interface uses')
    if found != expected:
        raise SystemExit(f'expected {sorted(expected)}, found {sorted(found)}\n{output}')

    unexpected = [
        diagnostic
        for diagnostic in diagnostics
        if diagnostic[3] is None or (diagnostic[0], diagnostic[3], diagnostic[4]) not in expected
    ]
    if unexpected:
        raise SystemExit(f'unexpected LuaLS diagnostics: {unexpected}\n{output}')

    print('LuaLS context integration fixture passed')


if __name__ == '__main__':
    main()
