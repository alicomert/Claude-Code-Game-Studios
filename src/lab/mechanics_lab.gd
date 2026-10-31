extends Node3D
## Entry point for the offline movement laboratory, not the complete Phase 1 game.

const PlayerScript = preload("res://src/player/player_controller.gd")
const CameraScript = preload("res://src/camera/player_camera.gd")
const TuningScript = preload("res://src/data/movement_tuning.gd")
const CombatPreset = preload("res://assets/data/player_combat_default.tres")
const CombatScript = preload("res://src/combat/player_combat.gd")
const PistolScript = preload("res://src/combat/pistol_visual.gd")
const HudScript = preload("res://src/ui/player_hud.gd")
const WeaponScript = preload("res://src/combat/weapon_controller.gd")
const RangeScript = preload("res://src/lab/combat_range.gd")
const InteractionScript = preload("res://src/interaction/interaction_controller.gd")
const FeedbackScript = preload("res://src/combat/shot_feedback.gd")
const LabRules = preload("res://assets/data/lab_rules.tres")
const RoleScript = preload("res://src/roles/role_controller.gd")
const CargoScript = preload("res://src/roles/cargo_controller.gd")
const SPAWN := Vector3(0.0, 0.75, 5.0)
const FLOOR_COLOR := Color("172333")
const LINE_COLOR := Color("304455")
const TEAL := Color("66e0c2")
const ORANGE := Color("ffae73")

@export var tuning: TuningScript

## Per-lab health and ammunition; external damage systems call combat.apply_damage().
var combat: CombatScript
var weapon: WeaponScript
var interaction: InteractionScript
var combat_range: RangeScript
var roles: RoleScript
var cargo: CargoScript
var _feedback: FeedbackScript
var _hazard_wait := 0.0
var _kick := 0.0
var _reduced_effects := false
var _limited_ammo := false
var _sample_status := ""
var _pistol: PistolScript
var _combat_hud: HudScript
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
var _verification_frame := 0
var _focus_wait_frames := 0
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
	combat = CombatPreset.duplicate()
	combat.reset()
	_pistol = PistolScript.new()
	_pistol.name = "Pistol"
	_pistol.tuning = combat
	_pistol.position = Vector3(0.38, 0.86, -0.48)
	_visual_root.add_child(_pistol)
	combat.fired.connect(_pistol.play_shot)
	_build_hud()
	_build_combat_range()
	var arguments := OS.get_cmdline_user_args()
	for index in range(arguments.size()):
		if arguments[index] == "--capture-evidence" and index + 1 < arguments.size():
			_capture_path = arguments[index + 1]
	_verification = arguments.has("--verify-lab")
	_verify_jump = arguments.has("--verify-jump")
	if _verification or _verify_jump:
		get_window().grab_focus()
	print("SECTOR9 LAB | WASD / Shift / Space jump / Left click fire / R reload / C / F5 / Esc")


func _process(delta: float) -> void:
	_frames += 1
	if not _paused:
		_animate_jump(delta)
		combat.advance(delta)
		weapon.advance(delta)
		_update_cargo(delta)
		_kick = maxf(_kick - delta, 0.0)
		_camera.h_offset = sin(_kick * 120.0) * _kick if not _reduced_effects else 0.0
		_update_lab_commands(delta)
	if Input.is_action_just_pressed(&"lab_reset"):
		_reset_lab()
	if Input.is_action_just_pressed(&"ui_cancel"):
		set_paused(not _paused)
	if Input.is_action_just_pressed(&"reload"):
		reload_weapon()
	if Input.is_action_just_pressed(&"fire"):
		try_fire()
	var mode_text := tr("BEKLEME")
	if not _player.is_on_floor():
		mode_text = tr("YÜKSELİYOR") if _player.velocity.y > 0.0 else tr("İNİYOR")
	elif _player.velocity.length() > 0.1:
		mode_text = tr("SESSİZ YÜRÜYÜŞ") if _player.is_slow_walking else tr("HAREKET")
	_status.text = tr("%s  •  Konum: %.1f / %.1f") % [
		mode_text, _player.position.x, _player.position.z]
	if _player.position.y < -5.0:
		_reset_lab()
	if not _capture_path.is_empty() and _frames == 90 and not _verification and not _verify_jump:
		_capture_and_quit()


func _physics_process(_delta: float) -> void:
	_height_anchor.global_position = Vector3(_player.global_position.x, _player.ground_anchor_y, _player.global_position.z)
	if _verification or _verify_jump:
		if not get_window().has_focus():
			_focus_wait_frames += 1
			if _verification_frame > 0 or _focus_wait_frames > 300:
				push_error("NOT ASSESSED: visible integration requires uninterrupted window focus")
				get_tree().quit(2)
			return
		_verification_frame += 1
	if _verify_jump:
		_verify_jump_sequence()
		return
	if not _verification:
		return
	# Explicit opt-in integration rehearsal drives the same actions as a keyboard.
	match _verification_frame:
		10:
			_verification_start = _player.position
			Input.action_press(&"move_right")
		50:
			_check(_player.position.x > _verification_start.x + 1.0, "right action moves player")
			Input.action_release(&"move_right")
			Input.action_press(&"move_forward")
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


## Accept one shot only while gameplay can receive focused input.
func try_fire() -> bool:
	if _paused or not get_window().has_focus() or roles.is_hacking() or cargo.carrying_core() or cargo.aiming:
		return false
	var origin: Vector3 = _player.global_position + Vector3.UP * 0.25
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var direction: Vector3 = PlayerScript.ray_plane_aim_direction(
		_camera.project_ray_origin(mouse), _camera.project_ray_normal(mouse), origin)
	if direction.is_zero_approx():
		direction = -_player.global_basis.z
	var accepted: bool = weapon.fire_at(origin, direction, _player.velocity.length() > 0.1)
	if accepted:
		_kick = LabRules.camera_kick
		_feedback.play_tone(weapon.current_profile().tone_hz)
	return accepted


func _cargo_aim_point() -> Vector3:
	var mouse := get_viewport().get_mouse_position()
	var ray_origin := _camera.project_ray_origin(mouse)
	var ray_direction := _camera.project_ray_normal(mouse)
	if absf(ray_direction.y) > 0.000001:
		var distance := (_player.global_position.y - ray_origin.y) / ray_direction.y
		if distance >= 0.0:
			return ray_origin + ray_direction * distance
	return _player.global_position - _player.global_basis.z * 5.0


func _update_cargo(delta: float) -> void:
	cargo.advance(delta, _player, _cargo_aim_point())


func _on_cargo_noise(_point: Vector3, radius: float) -> void:
	_sample_status = tr("Yem sesi: %.1f m") % radius


## Refill seven rounds from the lab's unlimited supply while gameplay is active.
func reload_weapon() -> bool:
	if _paused or not get_window().has_focus() or combat.health <= 0.0 or combat.stun_remaining > 0.0 or roles.is_hacking():
		return false
	return combat.reload()


## Freeze movement and presentation without deleting airborne velocity.
func set_paused(value: bool) -> void:
	_paused = value
	_player.set_physics_process(not value)
	_camera.set_process(not value)
	_pistol.set_paused(value)
	_combat_hud.set_paused(value)
	_pause_label.visible = value
	_feedback.set_paused(value)
	interaction.cancel()
	roles.cancel_hack()
	cargo.set_paused(value)
	_player.ability_locked = false
	for target in combat_range.targets:
		target.set_process(not value)
	_camera.h_offset = 0.0


func _reset_lab() -> void:
	combat.reset()
	weapon.reset_weapon()
	roles.reset_role()
	cargo.reset_cargo()
	cargo.set_paused(_paused)
	_player.cargo_speed_multiplier = 1.0
	if roles.current_profile().equipped_weapon >= 0:
		weapon.select_weapon(roles.current_profile().equipped_weapon)
	interaction.cancel()
	combat_range.reset_range()
	_feedback.reset_effects()
	_hazard_wait = 0.0
	_kick = 0.0
	combat.reserve_ammo = LabRules.limited_reserve if _limited_ammo else -1
	_sample_status = ""
	_camera.h_offset = 0.0
	_combat_hud.reset_display()
	_pistol.reset_visual()
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
	_world_label(tr("SPACE / ZIPLA — 45 cm"), Vector3(0, 0.08, -0.8), TEAL)
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
	var frame := _verification_frame
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
	_combat_hud = HudScript.new()
	_combat_hud.name = "CombatHud"
	root.add_child(_combat_hud)
	_combat_hud.bind_state(combat)
	var controls := _label(tr("WASD   Hareket\nFARE   Bakış yönü\nSOL TIK   Ateş\n1–4   Silah seç\nR   Şarjör değiştir\nE   Etkileşim\nF2   Rol seç\nQ / F   Rol yeteneği\nT   Basılı tut / aç-kapa\nF6   Efekt azalt\nF7   Mermi test modu\nSHIFT   Sessiz yürü\nSPACE   Zıpla\nC basılı   Kamerayı merkezle\nF5   Alanı sıfırla\nESC   Duraklat / devam"), 17, Color("e3eaf2"))
	controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	controls.position = Vector2(-290, 24)
	controls.size = Vector2(260, 205)
	root.add_child(controls)
	_status = _label("", 17, TEAL)
	_status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_status.position = Vector2(30, -62)
	root.add_child(_status)
	var disclaimer := _label(tr("R: şarjör değiştir • Sınırsız yedek şarjör • F5: laboratuvarı sıfırla."), 14, Color("aebed1"))
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


func _build_combat_range() -> void:
	weapon = WeaponScript.new()
	weapon.state = combat
	weapon.excluded = [_player.get_rid()]
	add_child(weapon)
	weapon.weapon_changed.connect(_combat_hud.show_weapon)
	weapon.weapon_changed.connect(_pistol.show_profile)
	_pistol.show_profile(weapon.current_profile())
	combat_range = RangeScript.new()
	combat_range.name = "CombatRange"
	add_child(combat_range)
	interaction = InteractionScript.new()
	interaction.reach = LabRules.interaction_reach
	add_child(interaction)
	_feedback = FeedbackScript.new()
	add_child(_feedback)
	weapon.shot_traced.connect(_on_shot_traced)
	combat_range.shield_station.activated.connect(combat.refill_shield)
	combat_range.terminal.activated.connect(func():
		combat_range.door.activate()
		_sample_status = tr("Terminal kapıyı açtı"))
	combat.reserve_ammo = LabRules.limited_reserve if _limited_ammo else -1
	roles = RoleScript.new()
	add_child(roles)
	cargo = CargoScript.new()
	cargo.name = "CargoController"
	add_child(cargo)
	roles.role_changed.connect(_on_role_changed)
	roles.fuse_cast.connect(_show_fuse_cone)
	cargo.noise_emitted.connect(_on_cargo_noise)
	combat.damaged.connect(_interrupt_role_on_damage)
	_on_role_changed(roles.current_profile())


func _update_lab_commands(delta: float) -> void:
	var focused: bool = get_window().has_focus()
	var can_act: bool = focused and combat.health > 0.0 and combat.stun_remaining <= 0.0
	_player.set_physics_process(combat.health > 0.0 and combat.stun_remaining <= 0.0)
	_hazard_wait = maxf(_hazard_wait - delta, 0.0)
	if combat_range.hazard.overlaps_body(_player) and _hazard_wait <= 0.0 and not combat_range.electrical_panel.is_disabled():
		combat.apply_damage(LabRules.hazard_damage, 1)
		combat.apply_stun(LabRules.hazard_stun)
		_hazard_wait = LabRules.hazard_interval
	if not can_act:
		cargo.cancel_aim()
		if not focused:
			_player.velocity.x = 0.0
			_player.velocity.z = 0.0
		interaction.cancel()
		roles.cancel_hack()
		_player.ability_locked = false
		_update_role_abilities(delta, false)
		_combat_hud.show_context(tr("F5: yeniden başlat") if combat.health <= 0.0 else "")
		return
	_update_role_abilities(delta, true)
	if roles.is_hacking():
		interaction.cancel()
		return
	for index in range(4):
		if Input.is_action_just_pressed(StringName("weapon_%d" % (index + 1))):
			if roles.current_profile().role_id == &"operator" or index == roles.current_profile().equipped_weapon:
				weapon.select_weapon(index)
	if Input.is_action_just_pressed(&"interaction_toggle"):
		interaction.cancel()
		interaction.toggle_mode = not interaction.toggle_mode
	if Input.is_action_just_pressed(&"effects_toggle"):
		_reduced_effects = not _reduced_effects
		_feedback.reduced = _reduced_effects
		_pistol.set_meta(&"reduced", _reduced_effects)
	if Input.is_action_just_pressed(&"ammo_mode"):
		_limited_ammo = not _limited_ammo
		combat.reserve_ammo = LabRules.limited_reserve if _limited_ammo else -1
	var candidate: Node3D = combat_range.pick_station(_camera, get_viewport().get_mouse_position())
	var clear := candidate != null and combat_range.clear_sight(_player, candidate)
	if roles.current_profile().role_id == &"yuk":
		var cargo_item := cargo.pick_item(_player, _camera, get_viewport().get_mouse_position())
		if is_instance_valid(cargo_item) and Input.is_action_just_pressed(&"interact"):
			cargo.pickup(cargo_item)
			candidate = null
			clear = false
	interaction.set_candidate(candidate, _player.global_position, clear)
	interaction.step(Input.is_action_just_pressed(&"interact"), Input.is_action_pressed(&"interact"), delta)
	var context := ""
	if is_instance_valid(candidate):
		context = tr(candidate.display_name) + " • "
		if not interaction.reason.is_empty():
			context += interaction.reason
		else:
			context += tr("E: kullan") + " %d%%" % int(interaction.progress * 100.0)
	if interaction.toggle_mode:
		context += "  " + tr("E aç/kapa")
	if _limited_ammo:
		context += "  " + tr("Yedek") + ": %d" % combat.reserve_ammo
	_combat_hud.show_context(context)


func _on_shot_traced(start: Vector3, finish: Vector3, hit: bool) -> void:
	_feedback.trace_shot(start, finish, hit)
	if hit:
		_combat_hud.show_hit()
		_pistol.confirm_hit(LabRules.impact_duration)
		_feedback.play_tone(700.0, true)


func _update_role_abilities(delta: float, accepts_input: bool) -> void:
	if accepts_input and Input.is_action_just_pressed(&"role_cycle"):
		roles.select_role((roles.selected + 1) % RoleScript.PROFILES.size())
	var profile: Resource = roles.current_profile()
	var target: Node3D = combat_range.pick_hack_target(_camera, get_viewport().get_mouse_position())
	var clear: bool = target != null and combat_range.clear_sight(_player, target)
	if accepts_input:
		var moving: bool = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back").length_squared() > 0.0
		if moving or Input.is_action_just_pressed(&"jump") or Input.is_action_just_pressed(&"interact"):
			roles.cancel_hack(tr("Hack iptal: hareket"))
		if Input.is_action_just_pressed(&"ability_primary"):
			if profile.role_id == &"yuk":
				cargo.begin_aim()
			elif profile.role_id == &"kirici":
				roles.strike(_player, -_player.global_basis.z)
			elif roles.is_hacking():
				roles.cancel_hack(tr("Hack iptal"))
			elif not moving:
				roles.begin_hack(target, _player, clear)
		if profile.role_id == &"yuk" and cargo.aiming and not Input.is_action_pressed(&"ability_primary"):
			cargo.throw_item(_player, _cargo_aim_point())
		if Input.is_action_just_pressed(&"cargo_utility") and profile.role_id == &"yuk":
			cargo.toggle_utility()
		if Input.is_action_just_pressed(&"cargo_drop") and profile.role_id == &"yuk":
			cargo.drop_item(_player)
		if Input.is_action_just_pressed(&"ability_secondary"):
			if profile.role_id == &"kirici":
				roles.deploy_shield(_player, -_player.global_basis.z)
			elif profile.role_id == &"yuk":
				cargo.use_utility(_player, _cargo_aim_point())
			else:
				roles.cast_fuse(_player, -_player.global_basis.z, combat_range.electrical_devices, combat_range.targets)
	roles.advance(delta, _player, target, clear)
	if roles.is_hacking():
		_player.velocity.x = 0.0
		_player.velocity.z = 0.0
	_player.ability_locked = roles.is_hacking()
	var reveal: float = profile.cable_sight_reach if profile.role_id == &"kilit" else 0.0
	combat_range.advance_devices(delta, _player.global_position, reveal)
	var text: String = tr(profile.display_name) + " • " + tr("F2: rol seç")
	if profile.role_id == &"kilit":
		text += "\n" + tr("Q: Hack") + " %.1f  |  " % roles.hack_cooldown_remaining \
			+ tr("F: Sigorta Ağı") + " %.1f" % roles.fuse_cooldown_remaining
		if roles.is_hacking():
			text += "\n" + tr("Hack sürüyor") + " %d%%" % int(roles.hack_progress * 100.0)
		elif not roles.message.is_empty():
			text += "\n" + roles.message
	elif profile.role_id == &"kirici":
		text += "\n" + tr("Q: Kır/it") + " %.1f  |  " % roles.break_cooldown_remaining \
			+ tr("F: Kalkan Duvarı") + " %.1f" % roles.shield_cooldown_remaining
		if not roles.message.is_empty():
			text += "\n" + roles.message
	elif profile.role_id == &"yuk":
		_player.cargo_speed_multiplier = profile.core_speed_multiplier if cargo.carrying_core() else 1.0
		text += "\n" + tr("E: al  | Q: fırlat  | G: bırak  | F: %s") % tr(cargo.utility_mode)
		text += "\n" + tr("Çanta: %d/%d  | Q %.1f  F %.1f") % [cargo.carried.size(), profile.cargo_capacity, cargo.throw_cooldown, cargo.utility_cooldown]
		if not cargo.message.is_empty():
			text += "\n" + cargo.message
	_combat_hud.show_role(text)


func _on_role_changed(profile: Resource) -> void:
	_player.ability_locked = false
	_player.role_walk_multiplier = profile.slow_walk_factor
	weapon.noise_multiplier = profile.shot_noise_multiplier
	var ratio: float = combat.health / maxf(combat.max_health, 1.0)
	combat.max_health = profile.max_health
	combat.health = clampf(ratio * combat.max_health, 0.0, combat.max_health)
	combat.health_changed.emit(combat.health, combat.max_health)
	interaction.cancel()
	cargo.set_role(profile)
	_player.cargo_speed_multiplier = 1.0
	if profile.equipped_weapon >= 0:
		weapon.select_weapon(profile.equipped_weapon)
	else:
		weapon.select_weapon(0)


func _interrupt_role_on_damage(_amount: float) -> void:
	roles.cancel_hack(tr("Hack iptal: hasar"))
	_player.ability_locked = false


func _show_fuse_cone(origin: Vector3, direction: Vector3, reach: float, angle: float) -> void:
	if _reduced_effects:
		return
	for index in range(7):
		var yaw: float = deg_to_rad(-angle * 0.5 + angle * index / 6.0)
		var start: Vector3 = origin + Vector3.DOWN * 0.65
		_feedback.trace_shot(start, start + direction.rotated(Vector3.UP, yaw) * reach, false)
