class_name MovementTuning
extends Resource
## Shared, read-only tuning for the solo movement lab. Inject per-instance copies
## when changing values at runtime; assets/data/movement_default.tres is the preset.

@export_group("Locomotion")
@export_range(0.0, 30.0, 0.1) var move_speed: float = 6.0
@export_range(0.0, 100.0, 0.1) var acceleration: float = 32.0
@export_range(0.0, 100.0, 0.1) var deceleration: float = 40.0
@export_range(0.0, 1.0, 0.01) var walk_multiplier: float = 0.4
@export_range(0.0, 100.0, 0.1) var gravity: float = 24.0
@export_range(0.0, 100.0, 0.1) var turn_sharpness: float = 22.0

@export_group("Dash")
@export_range(0.0, 60.0, 0.1) var dash_speed: float = 15.0
@export_range(0.0, 2.0, 0.01) var dash_duration: float = 0.17
## Time between dash activations, measured from the start of the previous dash.
@export_range(0.0, 10.0, 0.01) var dash_cooldown: float = 0.9

@export_group("Camera")
@export_range(0.1, 50.0, 0.1) var camera_height: float = 16.0
@export_range(0.1, 50.0, 0.1) var camera_depth: float = 11.2
@export_range(1.0, 179.0, 0.1) var camera_fov: float = 50.0
@export_range(0.0, 40.0, 0.1) var camera_follow_sharpness: float = 8.0
@export var camera_edge_pan_enabled: bool = true
@export_range(0.0, 15.0, 0.1) var camera_edge_pan: float = 4.0
## Fraction of screen width/height at which the right/bottom edge band begins.
## 0.85 means the outer 15% of each edge; the middle 70% stays neutral.
@export_range(0.5, 0.99, 0.01) var camera_edge_threshold: float = 0.85
