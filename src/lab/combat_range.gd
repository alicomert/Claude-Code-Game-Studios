extends Node3D
## Combat/interaction fixtures stay separate from existing locomotion geometry.

const Prop = preload("res://src/combat/damageable_prop.gd")
const Station = preload("res://src/interaction/lab_interactable.gd")
const Rules = preload("res://assets/data/lab_rules.tres")

var targets: Array[Node3D] = []
var stations: Array[Node3D] = []
var terminal: Node3D
var door: Node3D
var shield_station: Node3D
var hazard: Area3D

func _ready() -> void:
	for index in range(3):
		var target = Prop.new()
		target.name = "Target%d" % index
		target.position = Vector3(-10 + index * 2.4, 1.0, -11)
		add_child(target)
		targets.append(target)
	var friendly = Prop.new()
	friendly.name = "FriendlyTarget"
	friendly.team = 0
	friendly.tint = Color("66e0c2")
	friendly.position = Vector3(-2.8, 1.0, -11)
	add_child(friendly)
	targets.append(friendly)
	_cover("LowCover", Vector3(2, 0.7, 0.5), Vector3(-10, 0.35, -8), false)
	_cover("HighCover", Vector3(2, 2.5, 0.5), Vector3(-7.6, 1.25, -8), false)
	_cover("BreakableCover", Vector3(2, 1.5, 0.5), Vector3(-5.2, 0.75, -8), true)
	door = _station("Kapı", "door", Vector3(12.5, 1.1, 4), 0.0)
	terminal = _station("Terminal", "terminal", Vector3(4, 0.5, 7), Rules.terminal_duration)
	shield_station = _station("Kalkan istasyonu", "shield", Vector3(-4, 0.5, 5), 0.0)
	hazard = Area3D.new()
	hazard.name = "DamagePad"
	hazard.position = Vector3(-10, 0.1, 6)
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.5, 0.3, 2.5)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	hazard.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.5, 0.05, 2.5)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("b83c40")
	mesh.material_override = mat
	hazard.add_child(mesh)
	add_child(hazard)

func _cover(title: String, size: Vector3, point: Vector3, breaks: bool) -> void:
	var cover = Prop.new()
	cover.name = title
	cover.dimensions = size
	cover.position = point
	cover.breakable = breaks
	cover.max_health = 60.0 if breaks else 100000.0
	cover.tint = Color("876d59") if breaks else Color("45566b")
	add_child(cover)
	targets.append(cover)

func _station(title: String, kind: String, point: Vector3, hold: float) -> Node3D:
	var station = Station.new()
	station.display_name = title
	station.kind = kind
	station.position = point
	station.hold_duration = hold
	add_child(station)
	stations.append(station)
	return station

## Reset all world fixtures, including broken cover and opened doors.
func reset_range() -> void:
	for target in targets:
		target.reset_target()
	for station in stations:
		station.reset_target()

## Find a station under the cursor, then check body-to-station line of sight separately.
func pick_station(camera: Camera3D, mouse: Vector2) -> Node3D:
	var best: Node3D
	var best_score := INF
	for station in stations:
		if camera.is_position_behind(station.global_position):
			continue
		var distance: float = camera.unproject_position(station.global_position).distance_to(mouse)
		var score: float = distance - station.priority * 10.0
		if distance < 65.0 and score < best_score:
			best_score = score
			best = station
	return best

## Ground-body LOS prevents using a terminal through a wall even if its label is visible.
func clear_sight(player: CharacterBody3D, station: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(player.global_position, station.global_position)
	query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == station
