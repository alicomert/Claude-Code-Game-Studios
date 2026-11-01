"""Run only upstream Godot unit scripts in a disposable copy; no Python service/model.
Usage: python -B tests/tooling/autopilot-godot/check_godot.py --godot ABSOLUTE_EXE
No dependency installation; settings and game files are isolated. This is NOT a full playtest.
"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[3]
VENDOR = ROOT / 'tools/vendor/autopilot-godot/plugin/godot'


def main():
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    args = parser.parse_args()
    exe = str(Path(args.godot).resolve(strict=True))
    with tempfile.TemporaryDirectory(prefix='sector9-autopilot-') as tmp:
        tmp = Path(tmp)
        game = tmp / 'game'
        shutil.copytree(VENDOR / 'tests/game', game)
        shutil.copytree(VENDOR / 'addons/autopilot', game / 'addons/autopilot')
        # Prevent test imports or editor plugin setup from finding personal settings/keys.
        env = {k: v for k, v in os.environ.items() if not k.startswith('AUTOPILOT_')}
        for key in ('LOCALAPPDATA', 'APPDATA', 'HOME', 'USERPROFILE', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME'):
            env[key] = str(tmp / 'profile')
        (tmp / 'profile').mkdir()
        def run(arguments):
            r = subprocess.run([exe, '--headless', '--path', str(game)] + arguments,
                               env=env, capture_output=True, text=True, errors='replace', timeout=180)
            output = r.stdout + r.stderr
            print(output, flush=True)
            errors = ('SCRIPT ERROR', 'Parse Error', '\nERROR:')
            return r.returncode == 0 and not any(e in output for e in errors), output
        ok, _ = run(['--import'])
        if not ok:
            return 1
        for name in ('units.gd', 'dock_units.gd'):
            settings = tmp / name.replace('.gd', '')
            settings.mkdir()
            for key in ('LOCALAPPDATA', 'APPDATA', 'HOME', 'USERPROFILE', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'UNITS_DIR'):
                env[key] = str(settings)
            ok, output = run(['--script', str(VENDOR / 'tests' / name)])
            if not ok or 'checks passed' not in output:
                return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
