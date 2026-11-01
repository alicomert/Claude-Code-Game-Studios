"""Modified for Sector 9: Godot-only registry; unsupported engines fail closed.
Upstream: ramenvr/autopilot @ 48966d174939487cc759fdf8560f2bed6e717676.
Apache-2.0; see the distribution's LICENSE. No Unity/Unreal adapter imports.
"""
import os

from .base import Engine, OpEngine  # noqa: F401
from .godot import Godot

ENGINES = {"godot": Godot()}
DEFAULT = "godot"


def get(name=None):
    """Missing engine uses Godot; an explicit unknown engine is rejected."""
    key = str(name or "").strip().lower() or DEFAULT
    if key not in ENGINES:
        raise ValueError(f"Unsupported engine in Godot-only distribution: {key}")
    return ENGINES[key]


def for_hello(hello):
    return get(hello.get("engine") if isinstance(hello, dict) else None)


def for_link(link):
    return for_hello(getattr(link, "hello", None))


def of(game):
    eng = getattr(game, "engine", None)
    if isinstance(eng, Engine):
        if eng.name != "godot":
            raise ValueError("Only Godot is supported")
        return eng
    return for_link(getattr(game, "link", None))


def find_project(path, engine=None):
    eng = get(engine)
    if not path or not os.path.exists(path):
        return None, None
    project = eng.project_at(path)
    return (eng, project) if project else (None, None)
