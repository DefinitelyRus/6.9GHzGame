class_name CameraManager
extends Camera2D

static var instance: CameraManager = null

@export_group("Shake")
@export var shake_fade: float = 20.0
var shake_strength: float = 0.0


func _enter_tree() -> void:
	Log.me("A CameraManager has entered the tree. Scanning...")
	if instance != null:
		Log.err("Existing instance of CameraManager detected.")
		queue_free()
		return

	instance = self
	return


func shake(strength: float) -> void:
	shake_strength = strength
	return


func _process(delta: float) -> void:
	_handle_shake(delta)
	return


func _handle_shake(delta: float) -> void:
	if shake_strength > 0.0:
		shake_strength = lerp(shake_strength, 0.0, shake_fade * delta)

		var offset_x: float = randf_range(-shake_strength, shake_strength)
		var offset_y: float = randf_range(-shake_strength, shake_strength)
		offset = Vector2(offset_x, offset_y)
		pass

	else:
		offset = Vector2.ZERO
		pass
	return
