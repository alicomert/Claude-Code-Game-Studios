extends SceneTree
## Verify actual keyboard mappings accept the normal OS keyboard device, not a test action.

func _initialize() -> void:
	var failures := 0
	var bindings := {
		&"move_left": KEY_A,
		&"move_right": KEY_D,
		&"move_forward": KEY_W,
		&"move_back": KEY_S,
		&"jump": KEY_SPACE,
		&"reload": KEY_R,
	}
	for action in bindings:
		var compatible := false
		for binding in InputMap.action_get_events(action):
			if binding is InputEventKey and binding.physical_keycode == bindings[action]:
				compatible = binding.device == 0 or binding.device == -1
		if not compatible:
			failures += 1
			printerr("FAIL: %s must accept the standard keyboard device with the requested key" % action)
	if InputMap.has_action(&"dash") and not InputMap.action_get_events(&"dash").is_empty():
		failures += 1
		printerr("FAIL: dash must have no playable binding")
	print("Keyboard bindings: %d checks; %d failures" % [bindings.size() + 1, failures])
	quit(1 if failures > 0 else 0)
