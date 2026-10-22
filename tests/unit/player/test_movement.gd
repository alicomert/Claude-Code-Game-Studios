extends SceneTree
## Standalone deterministic movement tests; no scene, input polling, or addons.

const TuningScript = preload("res://src/data/movement_tuning.gd")
const PlayerScript = preload("res://src/player/player_controller.gd")
const CameraScript = preload("res://src/camera/player_camera.gd")
const EPSILON: float = 0.0001

var _assertion_count: int = 0
var _failure_count: int = 0


func _initialize() -> void:
	_test_lab_physical_keycodes_match_engine_enums()
	_test_diagonal_input_has_unit_length()
	_test_camera_relative_input_uses_ground_basis()
	_test_acceleration_and_deceleration_are_bounded()
	_test_slow_walk_uses_tuning_multiplier()
	_test_dash_uses_aim_when_idle_and_stays_locked()
	_test_dash_duration_and_cooldown_are_bounded()
	_test_large_step_does_not_extend_dash()
	_test_zero_duration_dash_is_disabled()
	_test_zero_delta_does_not_change_state()
	_test_reset_clears_motion_and_restores_facing()
	_test_focus_loss_cancels_dash_and_horizontal_motion()
	_test_partial_dash_retains_normal_speed_for_next_step()
	_test_ray_aim_uses_player_height_and_handles_parallel_rays()
	_test_pan_center_and_inner_region_are_neutral()
	_test_pan_edges_and_corners_are_bounded()
	_test_pan_invalid_viewport_is_neutral()
	_test_exponential_follow_is_frame_rate_independent()
	print("Movement tests: %d assertions executed; %d failures." % [
		_assertion_count, _failure_count
	])
	quit(1 if _failure_count > 0 or _assertion_count == 0 else 0)


func _make_tuning() -> TuningScript:
	return TuningScript.new()


func _make_player() -> PlayerScript:
	var player: PlayerScript = PlayerScript.new()
	player.tuning = _make_tuning()
	return player


func _make_camera() -> CameraScript:
	var camera: CameraScript = CameraScript.new()
	camera.tuning = _make_tuning()
	return camera


func _expect(condition: bool, description: String) -> void:
	_assertion_count += 1
	if not condition:
		_failure_count += 1
		printerr("FAIL: " + description)


func _expect_float(actual: float, expected: float, description: String) -> void:
	_expect(absf(actual - expected) <= EPSILON, "%s (got %f; expected %f)" % [
		description, actual, expected
	])


func _expect_vector(actual: Vector3, expected: Vector3, description: String) -> void:
	_expect(actual.distance_to(expected) <= EPSILON, description)


func _test_lab_physical_keycodes_match_engine_enums() -> void:
	# Boundary fixture: exact serialized keycodes in the parent-owned InputMap.
	_expect(KEY_F5 == 4194336, "F5 physical keycode is 4194336")
	_expect(KEY_SHIFT == 4194325, "Shift physical keycode is 4194325")
	_expect(KEY_SPACE == 32, "Space physical keycode is 32")


func _test_diagonal_input_has_unit_length() -> void:
	var direction: Vector3 = PlayerScript.horizontal_input_direction(Vector2(1.0, -1.0))
	_expect_float(direction.length(), 1.0, "Diagonal movement is normalized")
	_expect(direction.x > 0.0 and direction.z < 0.0, "Forward-right has correct signs")
	_expect_vector(PlayerScript.horizontal_input_direction(Vector2.ZERO), Vector3.ZERO,
		"Zero input is safe")
	_expect_float(PlayerScript.horizontal_input_direction(Vector2(0.25, 0.0)).length(),
		0.25, "Analog input magnitude is retained")


func _test_camera_relative_input_uses_ground_basis() -> void:
	var camera_basis: Basis = Basis(Vector3.UP, PI / 2.0)
	_expect_vector(PlayerScript.horizontal_input_direction(Vector2(0.0, -1.0),
		camera_basis), Vector3.LEFT, "Camera yaw rotates forward movement")
	var vertical_basis: Basis = Basis(Vector3.RIGHT, -PI / 2.0)
	var direction: Vector3 = PlayerScript.horizontal_input_direction(Vector2.UP,
		vertical_basis)
	_expect_float(direction.length(), 1.0, "Vertical camera has a nonzero fallback")
	_expect_float(direction.y, 0.0, "Camera pitch never adds vertical movement")
	var player: PlayerScript = _make_player()
	var camera: CameraScript = _make_camera()
	camera.rotation.y = PI / 2.0
	player.camera = camera
	player.simulate_motion(Vector2.UP, false, false,
		player.tuning.move_speed / player.tuning.acceleration)
	_expect_vector(player.velocity, Vector3.LEFT * player.tuning.move_speed,
		"Injected camera is used by simulation outside the scene tree")
	player.free()
	camera.free()


func _test_acceleration_and_deceleration_are_bounded() -> void:
	var player: PlayerScript = _make_player()
	var step: float = player.tuning.move_speed / player.tuning.acceleration / 2.0
	player.simulate_motion(Vector2.RIGHT, false, false, step)
	_expect_float(player.velocity.x, player.tuning.move_speed / 2.0,
		"Velocity ramps up using acceleration")
	player.simulate_motion(Vector2.RIGHT, false, false, step * 4.0)
	_expect_float(player.velocity.x, player.tuning.move_speed, "Speed never overshoots")
	step = player.tuning.move_speed / player.tuning.deceleration / 2.0
	player.simulate_motion(Vector2.ZERO, false, false, step)
	_expect_float(player.velocity.x, player.tuning.move_speed / 2.0,
		"Released input decelerates")
	player.simulate_motion(Vector2.ZERO, false, false, step * 4.0)
	_expect_vector(player.velocity, Vector3.ZERO, "Deceleration reaches rest without reversal")
	player.free()


func _test_slow_walk_uses_tuning_multiplier() -> void:
	var player: PlayerScript = _make_player()
	player.simulate_motion(Vector2.RIGHT, true, false,
		player.tuning.move_speed / player.tuning.acceleration)
	_expect_float(player.velocity.length(),
		player.tuning.move_speed * player.tuning.walk_multiplier,
		"Slow walking obeys external tuning")
	_expect(player.is_slow_walking, "Slow-walk state is exposed")
	player.simulate_motion(Vector2.ZERO, true, false, player.tuning.dash_cooldown)
	_expect(not player.is_slow_walking, "Idle is not reported as slow walking")
	player.free()


func _test_dash_uses_aim_when_idle_and_stays_locked() -> void:
	var player: PlayerScript = _make_player()
	var step: float = player.tuning.dash_duration / 4.0
	player.simulate_motion(Vector2.ZERO, false, true, step)
	_expect_vector(player.velocity, Vector3.FORWARD * player.tuning.dash_speed,
		"Idle dash uses default aim instead of a zero direction")
	player.simulate_motion(Vector2.RIGHT, true, true, step)
	_expect_vector(player.velocity, Vector3.FORWARD * player.tuning.dash_speed,
		"Active dash direction is locked and ignores walk speed")
	_expect(not player.is_slow_walking, "Dash is not reported as slow walking")
	player.free()


func _test_dash_duration_and_cooldown_are_bounded() -> void:
	var player: PlayerScript = _make_player()
	var duration: float = player.tuning.dash_duration
	var cooldown: float = player.tuning.dash_cooldown
	player.simulate_motion(Vector2.RIGHT, false, true, duration)
	_expect_float(player.dash_remaining, 0.0, "Dash expires at its duration")
	_expect_float(player.dash_cooldown_remaining, cooldown - duration,
		"Cooldown counts from dash activation")
	var step: float = duration / 2.0
	player.simulate_motion(Vector2.LEFT, false, true, step)
	_expect_float(player.dash_remaining, 0.0, "Cooldown rejects another dash")
	player.simulate_motion(Vector2.ZERO, false, false, cooldown)
	_expect_float(player.dash_cooldown_remaining, 0.0, "Cooldown is clamped at zero")
	player.simulate_motion(Vector2.LEFT, false, true, step)
	_expect(player.dash_remaining > 0.0, "Dash can activate again after cooldown")
	_expect_float(player.velocity.x, -player.tuning.dash_speed,
		"New dash uses the new movement direction")
	player.free()


func _test_large_step_does_not_extend_dash() -> void:
	var player: PlayerScript = _make_player()
	var step: float = player.tuning.dash_duration * 2.0
	player.simulate_motion(Vector2.ZERO, false, true, step)
	_expect_float(player.dash_remaining, 0.0, "Oversized delta still expires dash")
	_expect_float(player.velocity.length() * step,
		player.tuning.dash_speed * player.tuning.dash_duration,
		"Dash contributes only its remaining duration to displacement")
	player.simulate_motion(Vector2.ZERO, false, false, step)
	_expect_vector(player.velocity, Vector3.ZERO, "Dash does not leave excess residual speed")
	player.free()


func _test_zero_duration_dash_is_disabled() -> void:
	var player: PlayerScript = _make_player()
	player.tuning.dash_duration = 0.0
	player.simulate_motion(Vector2.ZERO, false, true, player.tuning.dash_cooldown)
	_expect_vector(player.velocity, Vector3.ZERO, "Zero-duration dash has no displacement")
	_expect_float(player.dash_remaining, 0.0, "Disabled dash stays inactive")
	player.free()


func _test_zero_delta_does_not_change_state() -> void:
	var player: PlayerScript = _make_player()
	player.simulate_motion(Vector2.RIGHT, false, true, 0.0)
	_expect_vector(player.velocity, Vector3.ZERO, "Zero delta does not change velocity")
	_expect_float(player.dash_cooldown_remaining, 0.0, "Zero delta does not consume dash")
	player.simulate_motion(Vector2.RIGHT, false, true, -1.0)
	_expect_vector(player.velocity, Vector3.ZERO, "Negative delta is ignored")
	player.free()


func _test_reset_clears_motion_and_restores_facing() -> void:
	var player: PlayerScript = _make_player()
	player.simulate_motion(Vector2.RIGHT, true, true, player.tuning.dash_duration / 2.0)
	player.velocity.y = -player.tuning.gravity
	player.rotation.y = PI / 2.0
	var spawn: Vector3 = Vector3(3.0, 0.75, -2.0)
	player.reset_to(spawn)
	_expect_vector(player.position, spawn, "Reset places player at the requested point")
	_expect_vector(player.velocity, Vector3.ZERO, "Reset clears all velocity")
	_expect_float(player.dash_remaining, 0.0, "Reset clears active dash")
	_expect_float(player.dash_cooldown_remaining, 0.0, "Reset clears dash cooldown")
	_expect_float(player.rotation.y, 0.0, "Reset snaps facing to world forward")
	_expect(not player.is_slow_walking, "Reset clears slow-walk state")
	player.free()


func _test_focus_loss_cancels_dash_and_horizontal_motion() -> void:
	var player: PlayerScript = _make_player()
	player.simulate_motion(Vector2.RIGHT, false, true, player.tuning.dash_duration / 2.0)
	player.velocity.y = -player.tuning.gravity
	var cooldown_before: float = player.dash_cooldown_remaining
	player.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect_float(player.dash_remaining, 0.0, "Focus loss cancels an active dash")
	_expect_float(player.velocity.x, 0.0, "Focus loss stops horizontal motion immediately")
	_expect_float(player.velocity.y, -player.tuning.gravity,
		"Focus loss does not cancel gravity")
	_expect_float(player.dash_cooldown_remaining, cooldown_before,
		"Focus loss does not refund cooldown")
	player.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	player.simulate_motion(Vector2.RIGHT, false, true, player.tuning.dash_duration / 2.0)
	_expect_float(player.dash_remaining, 0.0, "Focus regain does not bypass cooldown")
	player.free()


func _test_partial_dash_retains_normal_speed_for_next_step() -> void:
	var player: PlayerScript = _make_player()
	var duration: float = player.tuning.dash_duration
	player.simulate_motion(Vector2.RIGHT, false, true, duration * 2.0)
	var normal_speed: float = minf(player.tuning.acceleration * duration,
		player.tuning.move_speed)
	_expect_float(player.velocity.x,
		(player.tuning.dash_speed + normal_speed) / 2.0,
		"Expiry step blends dash and ordinary motion by duration")
	player.simulate_motion(Vector2.RIGHT, false, false,
		player.tuning.move_speed / player.tuning.acceleration)
	_expect_float(player.velocity.x, player.tuning.move_speed,
		"Duration-weighted dash velocity does not leak into the next ordinary step")
	player.free()


func _test_ray_aim_uses_player_height_and_handles_parallel_rays() -> void:
	var player_point: Vector3 = Vector3(0.0, 0.75, 0.0)
	var ray_origin: Vector3 = Vector3(0.0, 10.75, 0.0)
	var ray_direction: Vector3 = Vector3(1.0, -1.0, 0.0).normalized()
	_expect_vector(PlayerScript.ray_plane_aim_direction(ray_origin, ray_direction,
		player_point), Vector3.RIGHT, "Aim ray intersects player-height horizontal plane")
	_expect_vector(PlayerScript.ray_plane_aim_direction(ray_origin, Vector3.RIGHT,
		player_point), Vector3.ZERO, "Parallel ray is safely rejected")
	_expect_vector(PlayerScript.ray_plane_aim_direction(ray_origin, Vector3.UP,
		player_point), Vector3.ZERO, "Behind-camera intersection is safely rejected")
	_expect_vector(PlayerScript.ray_plane_aim_direction(ray_origin, Vector3.DOWN,
		player_point), Vector3.ZERO, "Aim directly on player is safely rejected")


func _test_pan_center_and_inner_region_are_neutral() -> void:
	var camera: CameraScript = _make_camera()
	var size: Vector2 = Vector2(1000.0, 800.0)
	_expect(camera.screen_edge_offset(size / 2.0, size).is_zero_approx(),
		"Screen center has no edge pan")
	_expect(camera.screen_edge_offset(size * Vector2(0.7, 0.3), size).is_zero_approx(),
		"Inner screen remains neutral")
	_expect(camera.screen_edge_offset(size * Vector2(camera.tuning.camera_edge_threshold,
		0.5), size).is_zero_approx(), "Edge threshold itself remains neutral")
	camera.free()


func _test_pan_edges_and_corners_are_bounded() -> void:
	var camera: CameraScript = _make_camera()
	var size: Vector2 = Vector2(1000.0, 800.0)
	var limit: float = camera.tuning.camera_edge_pan
	_expect_float(camera.screen_edge_offset(Vector2(size.x, size.y / 2.0), size).x,
		limit, "Right edge reaches configured pan distance")
	_expect_float(camera.screen_edge_offset(Vector2(0.0, size.y / 2.0), size).x,
		-limit, "Left edge reaches negative configured distance")
	_expect_float(camera.screen_edge_offset(Vector2(size.x / 2.0, 0.0), size).y,
		-limit, "Top edge pans toward camera-ground forward")
	_expect_float(camera.screen_edge_offset(size, size).length(), limit,
		"Corner pan is length-clamped, not faster diagonally")
	_expect(camera.screen_edge_offset(size * 10.0, size).length() <= limit + EPSILON,
		"Offscreen pointer never exceeds maximum pan")
	camera.tuning.camera_edge_pan_enabled = false
	_expect(camera.screen_edge_offset(size, size).is_zero_approx(),
		"Edge pan can be disabled in tuning")
	camera.free()


func _test_pan_invalid_viewport_is_neutral() -> void:
	var camera: CameraScript = _make_camera()
	_expect(camera.screen_edge_offset(Vector2.ONE, Vector2.ZERO).is_zero_approx(),
		"Zero viewport does not divide by zero")
	_expect(camera.screen_edge_offset(Vector2.ONE, Vector2(-1.0, 1.0)).is_zero_approx(),
		"Negative viewport is rejected")
	camera.free()


func _test_exponential_follow_is_frame_rate_independent() -> void:
	var tuning: TuningScript = _make_tuning()
	var desired: Vector3 = Vector3(4.0, tuning.camera_height, tuning.camera_depth)
	var low_rate: Vector3 = Vector3.ZERO
	var high_rate: Vector3 = Vector3.ZERO
	for frame: int in range(30):
		low_rate = CameraScript.smooth_follow(low_rate, desired,
			tuning.camera_follow_sharpness, 1.0 / 30.0)
	for frame: int in range(120):
		high_rate = CameraScript.smooth_follow(high_rate, desired,
			tuning.camera_follow_sharpness, 1.0 / 120.0)
	_expect_vector(low_rate, high_rate, "Exponential camera follow agrees at 30 and 120 Hz")
	_expect_vector(CameraScript.smooth_follow(Vector3.ZERO, desired,
		tuning.camera_follow_sharpness, 0.0), Vector3.ZERO,
		"Zero delta leaves camera unchanged")
	_expect_vector(CameraScript.smooth_follow(Vector3.ZERO, desired,
		tuning.camera_follow_sharpness, -1.0), Vector3.ZERO,
		"Negative delta leaves camera unchanged")
	_expect(low_rate.distance_to(desired) < Vector3.ZERO.distance_to(desired),
		"Camera converges toward target without overshooting")
