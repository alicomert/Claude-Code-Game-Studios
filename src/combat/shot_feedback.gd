extends Node3D
## Short-lived tracers and synthesized shot/impact sound; effects can be reduced together.

var reduced := false
var _effects: Array[Dictionary] = []
var _audio: AudioStreamPlayer
var _tones: Dictionary = {}

func _ready() -> void:
	_audio = AudioStreamPlayer.new()
	_audio.max_polyphony = 8
	_audio.volume_db = -20.0
	add_child(_audio)

func _exit_tree() -> void:
	_audio.stop()
	_audio.stream = null
	_tones.clear()


func _process(delta: float) -> void:
	for index in range(_effects.size() - 1, -1, -1):
		_effects[index].remaining -= delta
		if _effects[index].remaining <= 0.0:
			_effects[index].node.queue_free()
			_effects.remove_at(index)

## Show a bounded short tracer; hit tint confirms actual target damage, not every collision.
func trace_shot(start: Vector3, finish: Vector3, hit: bool) -> void:
	var length: float = start.distance_to(finish)
	if length <= 0.001:
		return
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.018 if reduced else 0.035, 0.018, length)
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("ffae73") if hit else Color("c6e8df")
	visual.material_override = material
	add_child(visual)
	visual.global_position = (start + finish) * 0.5
	visual.look_at(finish)
	_effects.append({"node": visual, "remaining": 0.05 if reduced else 0.08})

## Emit procedural shot and impact audio without external assets.
func play_tone(hz: float, impact := false) -> void:
	if reduced:
		return
	var key := "%s:%s" % [hz, impact]
	if not _tones.has(key):
		var data := PackedByteArray()
		var count := 3000
		for sample in range(count):
			var envelope: float = pow(1.0 - float(sample) / count, 3.0)
			var value: float = sin(TAU * hz * sample / 22050.0) * envelope
			data.append(int(value * 100) & 255)
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_8_BITS
		stream.mix_rate = 22050
		stream.data = data
		_tones[key] = stream
	_audio.stream = _tones[key]
	_audio.play()

## Remove active effects on reset and pause their lifetime/audio with gameplay.
func reset_effects() -> void:
	for effect in _effects:
		effect.node.queue_free()
	_effects.clear()
	_audio.stop()

func set_paused(value: bool) -> void:
	set_process(not value)
	_audio.stream_paused = value
