# Godot-only extraction — Sector 9

Source: https://github.com/ramenvr/autopilot
Pinned revision: `48966d174939487cc759fdf8560f2bed6e717676`.

This is a development/test source snapshot, NOT an installed or production-ready service.

## Included / modified

- Godot addon and its test game/tests; common Python package and resource files.
- Unity/Unreal plugins and engine adapter `.py` files excluded.
- Modified `autopilot/engines/__init__.py`: only Godot registered; explicit unsupported engines raise ValueError. Missing engine defaults to Godot.
- All other upstream files remain byte-identical (see UPSTREAM.json). Its hashes refer to ORIGINAL upstream bytes, including the modified registry's original hash.
- Apache-2.0 LICENSE and bundled font OFL licenses retained. Upstream README and pyproject describe the original multi-engine distribution; this document describes this extraction.

## Not installed / not hardened

No dependencies installed, no global service, no accounts linked, no model requests, no changes to the game's project.godot. Optional agent/account code remains for dependency compatibility; this is not a minimal standalone runtime.

IMPORTANT: Upstream sharing defaults are still ON. Merely extracting the files DOES NOT disable sharing. Before any service/editor activation, explicitly configure sharing OFF in isolated preferences and CLI (`--playtest-share=0`), review model data flow, use loopback and authentication, and obtain approval. Do not enable the dock yet. Built-in setup/service code can install/start/replace a service; it was not enabled in the real project.

The reflection API can invoke functions and change properties, including engine singletons. Use only trusted local test services. Do not ship the autoload in production exports. Internal state manipulation is not player-input acceptance evidence.

## Offline checks (from worktree root)

```
python -B -m unittest discover -s tests/tooling/autopilot-godot -p test_extraction.py
python -B tests/tooling/autopilot-godot/check_godot.py --godot <absolute-console-executable>
```

The extraction checks validate hashes, syntax, preload files, licensing and registry behavior using stand-ins. They DO NOT prove Python engine/service integration.
The Godot runner copies the upstream test game/addon into a temporary directory and redirects profile paths. It executes headless import, units.gd and dock_units.gd only. No LLM, Python service or install scripts are launched by this runner. Upstream unit tests use injected service launchers, and log messages about install/replace operations are mock scenarios, not global installation.

The upstream Python runtime needs Python >=3.12 and packages from pyproject.toml; websockets, typesafe-sdk, requests, python-dotenv, av and anthropic are not approved for installation here. Optional coding agents add dependencies. Full bridge, CI, editor integration and real-game tests are pending separate approval.

## Coordination

P2 task manifest revision 3 is LOCAL to this worktree. The UI worktree also has an uncommitted revision 3 with P2-A01. Reconcile both task additions into one reviewed manifest and increment revision before combining branches; do not overwrite either workstream's manifest. No claim of partner baseline synchronization.
