extends Node3D
## Entry point for the offline movement laboratory, not the complete Phase 1 game.

const PlayerScript = preload("res://src/player/player_controller.gd")
const CameraScript = preload("res://src/camera/player_camera.gd")
const TuningScript = preload("res://src/data/movement_tuning.gd")
const SPAWN := Vector3(0.0, 0.75, 5.0)
const FLOOR_COLOR := Color("172333")
const LINE_COLOR := Color("304455")
const TEAL := Color("66e0c2")
const ORANGE := Color("ffae73")

@export var tuning: TuningScript

var _player: PlayerScript
var _camera: CameraScript
var _status: Label
var _pause_label: Label
var _paused := false
var _capture_path := ""
var _frames := 0
var _verification := false
var _verification_start := Vector3.ZERO
var _verification_failures := 0
var _verification_checks := 0
var _verify_jump := false
var _visual_root: Node3D
var _height_anchor: Node3D
var _ground_ring: MeshInstance3D
var _takeoff_age := -1.0
var _landing_age := -1.0
var _jump_count := 0
var _landing_count := 0
var _jump_start_y := 0.0
var _jump_camera_y := 0.0
var _peak_height := 0.0


func _ready() -> void:
	_build_environment()
	_build_arena()
	_build_player()
	_build_hud()
	var arguments := OS.get_cmdline_user_args()
	for index in range(arguments.size()):
		if arguments[index] == "--capture-evidence" and index + 1 < arguments.size():
			_capture_path = arguments[index + 1]
	_verification = arguments.has("--verify-lab")
	_verify_jump = arguments.has("--verify-jump")
	print("SECTOR9 LAB | WASD / Shift / Space dash / V jump / C / F5 / Esc")


func _process(delta: float) -> void:
	_frames += 1
	if not _paused:
		_animate_jump(delta)
	if Input.is_action_just_pressed(&"lab_reset"):
		_reset_lab()
	if Input.is_action_just_pressed(&"ui_cancel"):
		_paused = not _paused
		_player.set_physics_process(not _paused)
		_camera.set_process(not _paused)
		_player.velocity = Vector3.ZERO
		_pause_label.visible = _paused
	var mode_text := tr("BEKLEME")
	if not _player.is_on_floor():
		mode_text = tr("YÜKSELİYOR") if _player.velocity.y > 0.0 else tr("İNİYOR")
	elif _player.dash_remaining > 0.0:
		mode_text = tr("ATILMA")
	elif _player.velocity.length() > 0.1:
		mode_text = tr("SESSİZ YÜRÜYÜŞ") if _player.is_slow_walking else tr("HAREKET")
	_status.text = tr("%s  •  Atılma bekleme: %.1f sn  •  Konum: %.1f / %.1f") % [
		mode_text, _player.dash_cooldown_remaining, _player.position.x, _player.position.z]
	if _player.position.y < -5.0:
		_reset_lab()
	if not _capture_path.is_empty() and _frames == 90 and not _verification and not _verify_jump:
		_capture_and_quit()


func _physics_process(_delta: float) -> void:
	_height_anchor.global_position = Vector3(_player.global_position.x, _player.ground_anchor_y, _player.global_position.z)
	if _verify_jump:
		_verify_jump_sequence()
		return
	if not _verification:
		return
	# Explicit opt-in integration rehearsal drives the same actions as a keyboard.
	match Engine.get_physics_frames():
		10:
			_verification_start = _player.position
			Input.action_press(&"move_right")
		50:
			_check(_player.position.x > _verification_start.x + 1.0, "right action moves player")
			Input.action_release(&"move_right")
			Input.action_press(&"move_forward")
		80:
			Input.action_press(&"dash")
		82:
			Input.action_release(&"dash")
			_check(_player.dash_cooldown_remaining > 0.0, "dash input starts cooldown")
		110:
			Input.action_release(&"move_forward")
			_reset_lab()
			_check(_player.position.distance_to(SPAWN) < 0.01, "reset restores spawn")
			_check(_player.velocity.is_zero_approx(), "reset clears velocity")
			Input.action_press(&"move_right")
		310:
			Input.action_release(&"move_right")
			_check(_player.position.x < 15.7, "arena boundary blocks player")
			_check(_player.position.x > 14.0, "player reaches boundary rather than stalling")
			_check(_player.is_on_floor(), "player remains grounded")
			_reset_lab()
		330:
			print("LAB INTEGRATION: %d checks, %d failures" % [_verification_checks, _verification_failures])
			if _capture_path.is_empty():
				get_tree().quit(0 if _verification_failures == 0 else 1)
			else:
				_capture_and_quit()


func _check(condition: bool, description: String) -> void:
	_verification_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_verification_failures += 1
		push_error("FAIL: " + description)


func _reset_lab() -> void:
	_player.reset_to(SPAWN)
	_height_anchor.position = SPAWN
	_takeoff_age = -1.0
	_landing_age = -1.0
	_visual_root.scale = Vector3.ONE
	_visual_root.position.y = -0.7
	_camera.snap_to_target()


func _capture_and_quit() -> void:
	await RenderingServer.frame_post_draw
	var directory := _capture_path.get_base_dir()
	var directory_error := DirAccess.make_dir_recursive_absolute(directory)
	if directory_error != OK:
		push_error("Evidence directory could not be created: %s" % directory)
		get_tree().quit(1)
		return
	var image := get_viewport().get_texture().get_image()
	var save_error := image.save_png(_capture_path)
	print("EVIDENCE: %s | result=%s" % [_capture_path, error_string(save_error)])
	get_tree().quit(0 if save_error == OK and _verification_failures == 0 else 1)


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("0b1322")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a9c0df")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	key.light_color = Color("d5e4ff")
	key.light_energy = 1.3
	key.shadow_enabled = true
	add_child(key)


func _build_arena() -> void:
	_box("Floor", Vector3(32, 0.5, 28), Vector3(0, -0.25, 0), FLOOR_COLOR, true)
	_box("WestBoundary", Vector3(0.4, 0.7, 28), Vector3(-16, 0.35, 0), LINE_COLOR, true)
	_box("EastBoundary", Vector3(0.4, 0.7, 28), Vector3(16, 0.35, 0), LINE_COLOR, true)
	_box("NorthBoundary", Vector3(32, 0.7, 0.4), Vector3(0, 0.35, -14), LINE_COLOR, true)
	_box("SouthBoundary", Vector3(32, 0.7, 0.4), Vector3(0, 0.35, 14), LINE_COLOR, true)
	for x in range(-14, 16, 2):
		_box("GridX", Vector3(0.025, 0.008, 27), Vector3(x, 0.008, 0), LINE_COLOR)
	for z in range(-12, 14, 2):
		_box("GridZ", Vector3(31, 0.008, 0.025), Vector3(0, 0.008, z), LINE_COLOR)
	_box("CenterLine", Vector3(0.07, 0.01, 23), Vector3(0, 0.012, 0), TEAL)
	_box("StartPad", Vector3(3.2, 0.012, 2.8), Vector3(0, 0.015, 5), Color("254d53"))
	_box("SlalomA", Vector3(1.8, 1.5, 1.8), Vector3(-6, 0.75, -1), Color("46576d"), true)
	_box("SlalomB", Vector3(1.8, 1.5, 1.8), Vector3(-9, 0.75, -5), Color("46576d"), true)
	_box("SlalomC", Vector3(1.8, 1.5, 1.8), Vector3(-5, 0.75, -9), Color("46576d"), true)
	_box("CollisionWall", Vector3(0.5, 1.2, 5), Vector3(6, 0.6, -3), Color("66505a"), true)
	_box("CollisionCap", Vector3(0.54, 0.08, 5), Vector3(6, 1.24, -3), ORANGE)
	_box("NarrowLeft", Vector3(0.5, 1.2, 4), Vector3(9.5, 0.6, -8), Color("46576d"), true)
	_box("NarrowRight", Vector3(0.5, 1.2, 4), Vector3(11.3, 0.6, -8), Color("46576d"), true)
	_box("JumpLow", Vector3(3.5, 0.45, 0.6), Vector3(0, 0.225, -2), Color("356a68"), true)
	_box("JumpMedium", Vector3(3.5, 0.75, 0.6), Vector3(0, 0.375, -6), Color("476571"), true)
	_world_label(tr("V / ZIPLA — 45 cm"), Vector3(0, 0.08, -0.8), TEAL)
	_world_label(tr("75 cm"), Vector3(0, 0.08, -4.8), TEAL)
	_world_label(tr("01 / HAREKET"), Vector3(0, 0.08, 8), TEAL)
	_world_label(tr("02 / SLALOM"), Vector3(-7, 0.08, 1), Color("bdc9d9"))
	_world_label(tr("03 / ÇARPIŞMA"), Vector3(7, 0.08, 1), ORANGE)
	_world_label(tr("DAR GEÇİT"), Vector3(10.4, 0.08, -11.5), Color("bdc9d9"))


func _build_player() -> void:
	_player = PlayerScript.new()
	_player.name = "Player"
	_player.tuning = tuning
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.4
	collider.shape = shape
	_player.add_child(collider)
	_visual_root = Node3D.new()
	_visual_root.name = "JumpVisual"
	_visual_root.position.y = -0.7
	_player.add_child(_visual_root)
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.4
	mesh.mesh = capsule
	mesh.material_override = _material(TEAL)
	mesh.position.y = 0.7
	_visual_root.add_child(mesh)
	# The orange nose makes facing direction immediately visible without animation.
	var nose := MeshInstance3D.new()
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.18, 0.16, 0.5)
	nose.mesh = nose_mesh
	nose.position = Vector3(0, 0.95, -0.43)
	nose.material_override = _material(ORANGE)
	_visual_root.add_child(nose)
	_player.position = SPAWN
	add_child(_player)
	_player.jumped.connect(_on_jumped)
	_player.landed.connect(_on_landed)
	_height_anchor = Node3D.new()
	_height_anchor.position = SPAWN
	add_child(_height_anchor)
	_ground_ring = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.43
	ring.outer_radius = 0.48
	_ground_ring.mesh = ring
	_ground_ring.material_override = _material(TEAL)
	_ground_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ground_ring)
	_camera = CameraScript.new()
	_camera.name = "PlayerCamera"
	_camera.target = _player
	_camera.height_anchor = _height_anchor
	_camera.tuning = tuning
	_camera.current = true
	add_child(_camera)
	_player.camera = _camera
	_camera.snap_to_target()


func _on_jumped() -> void:
	_takeoff_age = 0.0
	_landing_age = -1.0
	_jump_count += 1


func _on_landed(_impact_speed: float) -> void:
	_landing_age = 0.0
	_takeoff_age = -1.0
	_landing_count += 1


func _animate_jump(delta: float) -> void:
	# Animate only the foot-pivoted visual: collision and input never wait on a pose.
	var desired := Vector3.ONE
	var strength := clampf(tuning.jump_animation_strength, 0.0, 1.0)
	if _takeoff_age >= 0.0:
		_takeoff_age += delta
		var duration := maxf(tuning.jump_takeoff_duration, 0.001)
		var pulse := sin(PI * clampf(_takeoff_age / duration, 0.0, 1.0))
		desired += Vector3(-0.5, 1.0, -0.5) * pulse * tuning.jump_stretch * strength
		if _takeoff_age >= duration:
			_takeoff_age = -1.0
	elif _landing_age >= 0.0:
		_landing_age += delta
		var duration := maxf(tuning.jump_landing_duration, 0.001)
		var pulse := sin(PI * clampf(_landing_age / duration, 0.0, 1.0))
		desired += Vector3(0.5, -1.0, 0.5) * pulse * tuning.jump_squash * strength
		if _landing_age >= duration:
			_landing_age = -1.0
	elif not _player.is_on_floor():
		var speed_ratio := clampf(_player.velocity.y / sqrt(maxf(2.0 * tuning.gravity * tuning.jump_height, 0.001)), -1.0, 1.0)
		desired += Vector3(-0.5, 1.0, -0.5) * absf(speed_ratio) * tuning.jump_stretch * strength * 0.5
	_visual_root.scale = _visual_root.scale.lerp(desired, 1.0 - exp(-maxf(tuning.jump_pose_sharpness, 0.0) * delta))
	# A ray-projected marker exposes height without bobbing the camera.
	var query := PhysicsRayQueryParameters3D.create(_player.global_position, _player.global_position + Vector3.DOWN * 10.0)
	query.exclude = [_player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	_ground_ring.visible = not hit.is_empty()
	if not hit.is_empty():
		_ground_ring.global_position = hit.position + Vector3.UP * 0.025


func _verify_jump_sequence() -> void:
	var frame := Engine.get_physics_frames()
	_peak_height = maxf(_peak_height, _player.position.y - _jump_start_y)
	match frame:
		15:
			_check(_player.is_on_floor(), "jump starts grounded")
			_jump_start_y = _player.position.y
			_jump_camera_y = _camera.position.y
			Input.action_press(&"camera_center")
			Input.action_press(&"jump")
		18:
			_check(_player.velocity.y > 0.0, "jump input launches upward")
			_check(_jump_count == 1, "one jump event emitted")
			Input.action_release(&"jump")
		22:
			Input.action_press(&"jump")
		26:
			_check(_jump_count == 1, "airborne repeat rejected")
			_check(absf(_camera.position.y - _jump_camera_y) < 0.08, "camera ignores airborne height")
			if not _capture_path.is_empty():
				_save_frame(_capture_path.get_basename() + "-air.png")
		54:
			if not _capture_path.is_empty():
				_save_frame(_capture_path.get_basename() + "-landing.png")
		80:
			_check(_peak_height > 0.85 and _peak_height < 1.1, "jump apex stays near one meter")
			_check(_player.is_on_floor(), "jump lands on floor")
			_check(_jump_count == 1, "held input does not auto-hop")
			_check(_landing_count >= 1, "landing feedback emitted")
			Input.action_release(&"jump")
		90:
			Input.action_press(&"jump")
		94:
			_reset_lab()
			_check(_player.velocity.is_zero_approx(), "reset clears jump velocity")
			Input.action_release(&"jump")
		110:
			print("JUMP INTEGRATION: %d checks, %d failures" % [_verification_checks, _verification_failures])
			if _capture_path.is_empty():
				get_tree().quit(0 if _verification_failures == 0 else 1)
			else:
				_capture_and_quit()


func _save_frame(path: String) -> void:
	await RenderingServer.frame_post_draw
	var result := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if result == OK:
		result = get_viewport().get_texture().get_image().save_png(path)
	_check(result == OK, "save jump pose evidence")


func _box(node_name: String, size: Vector3, location: Vector3, color: Color, solid := false) -> void:
	var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
	root.name = node_name
	root.position = location
	var visual := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	visual.mesh = box
	visual.material_override = _material(color)
	root.add_child(visual)
	if solid:
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		root.add_child(collider)
	add_child(root)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material


func _world_label(text: String, location: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = location
	label.rotation_degrees.x = -90
	label.font_size = 56
	label.pixel_size = 0.012
	label.modulate = color
	add_child(label)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var heading := _label(tr("SECTOR 9"), 28, TEAL)
	heading.position = Vector2(28, 20)
	root.add_child(heading)
	var subtitle := _label(tr("FAZ 1 / MEKANİK LABORATUVARI\nHareket + kamera + zıplama"), 16, Color("ced8e5"))
	subtitle.position = Vector2(30, 59)
	root.add_child(subtitle)
	var controls := _label(tr("WASD   Hareket\nFARE   Bakış yönü\nSHIFT   Sessiz yürü\nSPACE   Atıl\nV   Zıpla\nC basılı   Kamerayı merkezle\nF5   Alanı sıfırla\nESC   Duraklat / devam"), 17, Color("e3eaf2"))
	controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	controls.position = Vector2(-290, 24)
	controls.size = Vector2(260, 205)
	root.add_child(controls)
	_status = _label("", 17, TEAL)
	_status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_status.position = Vector2(30, -62)
	root.add_child(_status)
	var disclaimer := _label(tr("Silahlar, roller, düşmanlar ve co-op henüz eklenmedi.  •  Amaç: önce kontrol hissini denemek."), 14, Color("aebed1"))
	disclaimer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	disclaimer.position = Vector2(30, -33)
	root.add_child(disclaimer)
	_pause_label = _label(tr("DURAKLATILDI\nDevam etmek için ESC"), 28, ORANGE)
	_pause_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_pause_label.position = Vector2(-185, -45)
	_pause_label.visible = false
	root.add_child(_pause_label)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_shadow_color", Color("0b1322"))
	label.add_theme_constant_override(&"shadow_offset_x", 1)
	label.add_theme_constant_override(&"shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
