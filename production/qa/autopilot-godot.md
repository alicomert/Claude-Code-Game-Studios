# Autopilot Godot-only extraction evidence

## Scope

Branch: feat/alicomert/p2-autopilot-godot. Upstream commit: 48966d174939487cc759fdf8560f2bed6e717676.
158 source/license/resource files fetched from pinned raw URLs. Original SHA256 values in tools/vendor/autopilot-godot/UPSTREAM.json. Only upstream registry modified. No install, paid model calls, real project activation, commit or push.

## Results

- Extraction tests: 5/5 PASS (original byte verification excluding documented modification, Python AST syntax, excluded motor adapters, licenses/preload targets, registry contract with stand-ins).
- SDLC routing tests: 21/21 PASS.
- Existing Godot executable: 4.7.2 stable official ed1daf0bf.
- Isolated temporary game import: PASS.
- Upstream units.gd: 348/348 checks passed.
- Upstream dock_units.gd: 850/850 checks passed.
- First runner attempt encountered Windows console UnicodeEncodeError after units; runner corrected to UTF-8 and rerun.
- CONCERNS: dock test exit warns of 11 CanvasItem RIDs and 22 ObjectDB instances leaked. Assertions passed, but clean teardown is NOT established.
- Full Python bridge/CI/editor tests: NOT ASSESSED. websockets/typesafe_sdk/av/anthropic absent; no dependencies installed.
- Real Sector 9 gameplay/UI or multiplayer: NOT ASSESSED.
- Privacy hardening: PENDING; upstream defaults still share on. Extraction does not change that. Do not activate before explicit isolated share-off configuration and approval.

## Safety / outstanding work

Source includes remote reflection and service installation/account code. Not a sandboxed production-safe package. Godot-only registry tested in isolation, not with real Python dependencies. See SECTOR9-INTEGRATION.md for commands and limitations.

Task manifest revision 3 is branch-local and diverges from the UI worktree's uncommitted revision 3. Both additions must be reconciled with a new revision before integration. Shared baseline freshness remains unknown. Task stays in_progress pending hardening and full tests.
