class_name PlayerCamera
extends Camera3D
## Fixed-angle exponential follow camera. The lab injects target and shared tuning.

const TuningScript = preload("res://src/data/movement_tuning.gd")

@export var target: Node3D
@export var tuning: TuningScript
## Optional ground reference: follow X/Z without bobbing with the airborne body.
@export var height_anchor: Node3D

var _input_focused: bool = true


func _ready() -> void:
	if tuning == null:
		push_error("PlayerCamera requires an injected MovementTuning resource.")
		set_process(false)
		return
	_input_focused = get_window().has_focus()
	snap_to_target()


func _process(delta: float) -> void:
	if tuning == null or not is_instance_valid(target):
		return
	fov = clampf(tuning.camera_fov, 1.0, 179.0)
	var edge: Vector2 = Vector2.ZERO
	if _input_focused and get_window().has_focus() and not Input.is_action_pressed(&"camera_center"):
		edge = screen_edge_offset(get_viewport().get_mouse_position(),
			get_viewport().get_visible_rect().size)
	var right: Vector3 = Vector3(global_basis.x.x, 0.0, global_basis.x.z).normalized()
	if right.is_zero_approx():
		right = Vector3.RIGHT
	var back: Vector3 = right.cross(Vector3.UP).normalized()
	var desired: Vector3 = follow_point() + _camera_offset() + right * edge.x + back * edge.y
	global_position = smooth_follow(global_position, desired,
		tuning.camera_follow_sharpness, delta)
	# Keep the inclination fixed while following/panning; mouse movement translates
	# the camera rather than orbiting or rotating the movement coordinate system.
	look_at(global_position - _camera_offset(), Vector3.UP)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_input_focused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_input_focused = true


## Place the camera immediately over its target, clearing any accumulated edge pan.
## The offset (height, depth) gives a roughly 55-degree downward view toward -Z.
func snap_to_target() -> void:
	if tuning == null or not is_instance_valid(target) or not is_inside_tree():
		return
	fov = clampf(tuning.camera_fov, 1.0, 179.0)
	global_position = follow_point() + _camera_offset()
	look_at(follow_point(), Vector3.UP)
	reset_physics_interpolation()


## Return a ground-plane pan vector in meters: x is screen-right, y screen-down.
## No tree or Input access. Only outer edge bands pan; corners share one distance cap.
func screen_edge_offset(mouse: Vector2, size: Vector2) -> Vector2:
	if tuning == null or not tuning.camera_edge_pan_enabled or size.x <= 0.0 or size.y <= 0.0:
		return Vector2.ZERO
	var threshold: float = clampf(tuning.camera_edge_threshold, 0.5, 0.99)
	var unit: Vector2 = Vector2(mouse.x / size.x, mouse.y / size.y)
	var edge: Vector2 = Vector2(_edge_axis(unit.x, threshold), _edge_axis(unit.y, threshold))
	return edge.limit_length(1.0) * maxf(tuning.camera_edge_pan, 0.0)


## Exponentially approach a fixed destination; independent of frame subdivision.
## Negative delta or sharpness are clamped so the position can never extrapolate.
static func smooth_follow(current: Vector3, desired: Vector3, sharpness: float, delta: float) -> Vector3:
	var weight: float = 1.0 - exp(-maxf(sharpness, 0.0) * maxf(delta, 0.0))
	return current.lerp(desired, weight)


## Resolve target X/Z and optional grounded Y; usable outside a scene for tests.
func follow_point() -> Vector3:
	if not is_instance_valid(target):
		return Vector3.ZERO
	var point := target.global_position if target.is_inside_tree() else target.position
	if is_instance_valid(height_anchor):
		point.y = height_anchor.global_position.y if height_anchor.is_inside_tree() else height_anchor.position.y
	return point


func _camera_offset() -> Vector3:
	return Vector3(0.0, maxf(tuning.camera_height, 0.001), maxf(tuning.camera_depth, 0.001))


static func _edge_axis(unit: float, threshold: float) -> float:
	if unit > threshold:
		return clampf((unit - threshold) / (1.0 - threshold), 0.0, 1.0)
	if unit < 1.0 - threshold:
		return -clampf((1.0 - threshold - unit) / (1.0 - threshold), 0.0, 1.0)
	return 0.0
