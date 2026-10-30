class_name PlayerController
extends CharacterBody3D
## Camera-relative locomotion, cursor-plane aiming, and grounded jumping.
## The lab owns visuals/collision children and injects camera and tuning references.

const TuningScript = preload("res://src/data/movement_tuning.gd")
const GEOMETRY_EPSILON: float = 0.000001

## Emitted once at accepted physical takeoff, before move_and_slide.
signal jumped()
## Emitted once after an observed airborne-to-floor transition; speed is positive.
signal landed(impact_speed: float)

@export var tuning: TuningScript
@export var camera: Camera3D

## Seconds left in the active dash; zero when inactive.
var dash_remaining: float = 0.0
## Seconds until another dash may begin, counted from the last activation.
var dash_cooldown_remaining: float = 0.0
## True only while moving slowly.
var is_slow_walking: bool = false
## Last grounded world height (body origin); held at takeoff while airborne.
var ground_anchor_y: float = 0.0

var _aim_direction: Vector3 = Vector3.FORWARD
var _dash_direction: Vector3 = Vector3.FORWARD
var _motion_velocity: Vector3 = Vector3.ZERO
var _dash_step_applied: bool = false
var _floor_contact_invalidated: bool = true
var _was_airborne: bool = false
var _jump_input_held: bool = false


func _ready() -> void:
	if tuning == null:
		push_error("PlayerController requires an injected MovementTuning resource.")
		set_physics_process(false)
		return
	ground_anchor_y = global_position.y


func _physics_process(delta: float) -> void:
	if tuning == null:
		return
	# Query current window focus; a startup cache can remain stale in embedded play.
	var accepts_input: bool = get_window().has_focus()
	var input_axis: Vector2 = Vector2.ZERO
	var slow: bool = false
	var wants_dash: bool = false
	var wants_jump: bool = false
	if accepts_input:
		input_axis = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
		slow = Input.is_action_pressed(&"slow_walk")
		wants_dash = Input.is_action_just_pressed(&"dash")
		wants_jump = Input.is_action_pressed(&"jump")
		_update_aim(delta)
	else:
		_cancel_horizontal_motion()
	var grounded_before_step: bool = not _floor_contact_invalidated and is_on_floor()
	if grounded_before_step:
		ground_anchor_y = global_position.y
	simulate_motion(input_axis, slow, delta, wants_dash)
	if simulate_vertical_motion(wants_jump, grounded_before_step, delta):
		jumped.emit()
	var impact_speed: float = maxf(-velocity.y, 0.0)
	move_and_slide()
	_floor_contact_invalidated = false
	var grounded_after_step: bool = is_on_floor()
	if grounded_after_step:
		ground_anchor_y = global_position.y
		if _was_airborne:
			landed.emit(impact_speed)
	_was_airborne = not grounded_after_step
	# Retain collision resolution instead of accumulating speed behind a wall.
	if not _dash_step_applied:
		_motion_velocity = Vector3(velocity.x, 0.0, velocity.z)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_cancel_horizontal_motion()


## Reset world position, velocity, jump state, and facing to world forward (-Z).
## Also works outside a SceneTree, where point is interpreted in local space.
func reset_to(point: Vector3) -> void:
	if is_inside_tree():
		global_position = point
	else:
		position = point
	velocity = Vector3.ZERO
	ground_anchor_y = point.y
	_floor_contact_invalidated = true
	_was_airborne = false
	_jump_input_held = false
	_motion_velocity = Vector3.ZERO
	_dash_step_applied = false
	dash_remaining = 0.0
	dash_cooldown_remaining = 0.0
	is_slow_walking = false
	_aim_direction = Vector3.FORWARD
	_dash_direction = Vector3.FORWARD
	if is_inside_tree():
		global_rotation = Vector3.ZERO
	else:
		rotation = Vector3.ZERO
	if is_inside_tree():
		reset_physics_interpolation()


## Update horizontal velocity and dash state without input polling or movement; vertical speed is untouched.
## Inject tuning before calling. Optional camera sets the horizontal movement basis.
func simulate_motion(input_axis: Vector2, slow: bool, delta: float, wants_dash: bool = false) -> void:
	if tuning == null or delta <= 0.0:
		return
	var camera_basis: Basis = Basis.IDENTITY
	if is_instance_valid(camera):
		camera_basis = camera.global_basis if camera.is_inside_tree() else camera.basis
	var direction: Vector3 = horizontal_input_direction(input_axis, camera_basis)
	if wants_dash and dash_remaining <= 0.0 and dash_cooldown_remaining <= 0.0:
		if tuning.dash_duration > 0.0 and tuning.dash_speed > 0.0:
			_dash_direction = direction.normalized() if not direction.is_zero_approx() else _aim_direction
			if _dash_direction.is_zero_approx():
				_dash_direction = Vector3.FORWARD
			dash_remaining = maxf(tuning.dash_duration, 0.0)
			dash_cooldown_remaining = maxf(tuning.dash_cooldown, 0.0)
			_motion_velocity = Vector3.ZERO
	var dash_step: float = minf(dash_remaining, delta)
	_dash_step_applied = dash_step > 0.0
	var normal_step: float = maxf(delta - dash_step, 0.0)
	var normal_speed: float = maxf(tuning.move_speed, 0.0)
	if slow:
		normal_speed *= clampf(tuning.walk_multiplier, 0.0, 1.0)
	var desired: Vector3 = direction * normal_speed
	if normal_step > 0.0:
		var rate: float = tuning.deceleration if direction.is_zero_approx() else tuning.acceleration
		_motion_velocity = _motion_velocity.move_toward(desired, maxf(rate, 0.0) * normal_step)
	var horizontal: Vector3 = (
		_dash_direction * maxf(tuning.dash_speed, 0.0) * dash_step
		+ _motion_velocity * normal_step
	) / delta
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	dash_remaining = maxf(dash_remaining - delta, 0.0)
	dash_cooldown_remaining = maxf(dash_cooldown_remaining - delta, 0.0)
	is_slow_walking = slow and not direction.is_zero_approx() and dash_step <= 0.0


## Update only vertical velocity without input, scene queries, movement, or signals.
## Pass jump-button state; only its rising edge can jump. Ground contact is injected.
## Returns whether takeoff was accepted; nonpositive delta leaves all state unchanged.
func simulate_vertical_motion(wants_jump: bool, grounded: bool, delta: float) -> bool:
	if tuning == null or delta <= 0.0:
		return false
	var rising_edge: bool = wants_jump and not _jump_input_held
	_jump_input_held = wants_jump
	if rising_edge and grounded and dash_remaining <= 0.0 and not _dash_step_applied:
		if tuning.jump_height > 0.0 and tuning.gravity > 0.0:
			velocity.y = sqrt(2.0 * tuning.gravity * tuning.jump_height)
			return true
	# A small downward step preserves move_and_slide floor contact while idle.
	if grounded:
		velocity.y = -maxf(tuning.gravity, 0.0) * delta
	else:
		velocity.y -= maxf(tuning.gravity, 0.0) * delta
	return false


## Exponential shortest-path yaw response; sharpness is a coefficient, not a speed cap.
## Nonpositive sharpness or delta preserves the current angle.
static func smooth_yaw(current: float, desired: float, sharpness: float, delta: float) -> float:
	var weight: float = 1.0 - exp(-maxf(sharpness, 0.0) * maxf(delta, 0.0))
	return lerp_angle(current, desired, weight)


## Convert a clamped input axis to a horizontal camera-relative direction.
## Preserves analog magnitude and supplies a stable basis for a vertical camera.
static func horizontal_input_direction(input_axis: Vector2, camera_basis: Basis = Basis.IDENTITY) -> Vector3:
	var axis: Vector2 = input_axis.limit_length(1.0)
	var right: Vector3 = Vector3(camera_basis.x.x, 0.0, camera_basis.x.z)
	if right.length_squared() <= GEOMETRY_EPSILON:
		right = Vector3.RIGHT
	else:
		right = right.normalized()
	var back: Vector3 = right.cross(Vector3.UP).normalized()
	return right * axis.x + back * axis.y


## Project a camera ray onto the player's horizontal plane; zero means no valid aim.
## Parallel rays, behind-camera hits, and an aim point on the player are rejected.
static func ray_plane_aim_direction(ray_origin: Vector3, ray_direction: Vector3, player_point: Vector3) -> Vector3:
	if absf(ray_direction.y) <= GEOMETRY_EPSILON:
		return Vector3.ZERO
	var distance: float = (player_point.y - ray_origin.y) / ray_direction.y
	if distance < 0.0:
		return Vector3.ZERO
	var offset: Vector3 = ray_origin + ray_direction * distance - player_point
	offset.y = 0.0
	if offset.length_squared() <= GEOMETRY_EPSILON:
		return Vector3.ZERO
	return offset.normalized()


## Calculate 3D aim direction from weapon origin toward the 3D world target point under the cursor.
## Uses a 3-stage smart height curve:
## - At close range (<= 2.5m near feet), aims downward at ground level.
## - Between 2.5m and 6.0m, smoothly blends from ground to weapon height.
## - Beyond 6.0m, levels out completely to horizontal chest height so bullets never hit the ground at distance.
## Parallel rays, behind-camera rays, or zero vectors fallback safely to horizontal forward (-Z).
static func calculate_3d_aim_direction(ray_origin: Vector3, ray_direction: Vector3, weapon_origin: Vector3, ground_y: float = 0.0) -> Vector3:
	if absf(ray_direction.y) <= GEOMETRY_EPSILON:
		return -Vector3.FORWARD
	var t: float = (ground_y - ray_origin.y) / ray_direction.y
	if t <= 0.0:
		return -Vector3.FORWARD
	var ground_point: Vector3 = ray_origin + ray_direction * t
	var horiz_vec: Vector2 = Vector2(ground_point.x - weapon_origin.x, ground_point.z - weapon_origin.z)
	var horiz_dist: float = horiz_vec.length()
	if horiz_dist < 0.2:
		horiz_vec = Vector2(0.0, -0.2)
		horiz_dist = 0.2
	var blend: float = clampf((horiz_dist - 2.5) / 3.5, 0.0, 1.0)
	var smooth_weight: float = blend * blend * (3.0 - 2.0 * blend)
	var target_y: float = lerpf(ground_y, weapon_origin.y, smooth_weight)
	var to_target: Vector3 = Vector3(horiz_vec.x, target_y - weapon_origin.y, horiz_vec.y)
	if to_target.length_squared() <= GEOMETRY_EPSILON:
		return -Vector3.FORWARD
	return to_target.normalized()


func _update_aim(delta: float) -> void:
	if not is_instance_valid(camera):
		return
	var mouse: Vector2 = camera.get_viewport().get_mouse_position()
	var direction: Vector3 = ray_plane_aim_direction(camera.project_ray_origin(mouse),
		camera.project_ray_normal(mouse), global_position)
	if not direction.is_zero_approx():
		_aim_direction = direction
	var desired_yaw: float = atan2(-_aim_direction.x, -_aim_direction.z)
	var facing: Vector3 = global_rotation
	facing.y = smooth_yaw(facing.y, desired_yaw, tuning.turn_sharpness, delta)
	global_rotation = facing


func _cancel_horizontal_motion() -> void:
	dash_remaining = 0.0
	_motion_velocity = Vector3.ZERO
	velocity.x = 0.0
	velocity.z = 0.0
	is_slow_walking = false
