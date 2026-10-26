extends StaticBody3D
## Resettable target/cover with team filtering and a visible damage/stun response.

signal hit_received(damage: float)

@export var max_health: float = 100.0
@export var team: int = 1
@export var breakable: bool = false
@export var dimensions := Vector3(1.1, 1.5, 0.3)
@export var tint := Color("d58363")

var health: float
var stun_remaining := 0.0
var _visual: MeshInstance3D
var _label: Label3D
var _collision: CollisionShape3D
var _flash := 0.0

func _ready() -> void:
	_collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	_collision.shape = shape
	add_child(_collision)
	_visual = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	_visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	_visual.material_override = material
	add_child(_visual)
	_label = Label3D.new()
	_label.position.y = dimensions.y * 0.5 + 0.3
	_label.font_size = 32
	_label.pixel_size = 0.012
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)
	reset_target()

func _process(delta: float) -> void:
	stun_remaining = maxf(stun_remaining - delta, 0.0)
	_flash = maxf(_flash - delta, 0.0)
	_visual.material_override.albedo_color = Color.WHITE if _flash > 0.0 else tint
	_label.text = tr("HEDEF") + " %d" % int(health)
	if stun_remaining > 0.0:
		_label.text += " • " + tr("SERSEM")

## Friendly shots and invalid damage cannot affect health or stun.
func receive_hit(amount: float, source_team: int, stun: float = 0.0) -> bool:
	if source_team == team or health <= 0.0 or not is_finite(amount) or amount <= 0.0:
		return false
	health = maxf(health - amount, 0.0)
	if is_finite(stun):
		stun_remaining = maxf(stun_remaining, stun)
	_flash = 0.08
	hit_received.emit(amount)
	if breakable and health <= 0.0:
		visible = false
		_collision.set_deferred(&"disabled", true)
	return true

## Restore collision, health and effects without recreating the world node.
func reset_target() -> void:
	health = maxf(max_health, 0.0)
	stun_remaining = 0.0
	_flash = 0.0
	visible = true
	if is_instance_valid(_collision):
		_collision.set_deferred(&"disabled", false)
