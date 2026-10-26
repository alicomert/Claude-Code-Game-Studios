extends StaticBody3D
## Visible one-use lab station/door; reset makes it available again.

signal activated()
@export var display_name: String = "Terminal"
@export var hold_duration: float = 1.5
@export var priority: int = 0
@export var kind: String = "terminal"
var completed := false
var _mesh: MeshInstance3D
var _collision: CollisionShape3D
var _label: Label3D

func _ready() -> void:
	_collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.5, 2.2, 0.3) if kind == "door" else Vector3(0.8, 1.0, 0.8)
	_collision.shape = shape
	add_child(_collision)
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	_mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("5da9a0")
	_mesh.material_override = material
	add_child(_mesh)
	_label = Label3D.new()
	_label.text = tr(display_name)
	_label.position.y = 1.4
	_label.font_size = 32
	_label.pixel_size = 0.012
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)

## Return false for an already completed action, preventing duplicate side effects.
func activate() -> bool:
	if completed:
		return false
	completed = true
	if kind == "door":
		_mesh.position.y = 2.5
		_collision.set_deferred(&"disabled", true)
	else:
		_mesh.material_override.albedo_color = Color("66e0c2")
	_label.text = tr(display_name) + " • " + tr("TAMAM")
	activated.emit()
	return true

## Restore a door/station and its activation state after a lab reset.
func reset_target() -> void:
	completed = false
	if is_instance_valid(_mesh):
		_mesh.position = Vector3.ZERO
		_mesh.material_override.albedo_color = Color("5da9a0")
		_collision.set_deferred(&"disabled", false)
		_label.text = tr(display_name)
