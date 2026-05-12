class_name CameraManager
extends Camera2D

static var instance: CameraManager = null

# ---------- CAMERA PANNING ----------
@export_group("Camera Panning")
@export var pan_duration: float = 1
var _target_position: Vector2


## Moves the camera to the target position, using the center of the screen as the comparison point.
func set_target_centered(center: Vector2, instant: bool = false) -> void:
	Log.me("Setting target position to X=%d Y=%d to the center of the screen..." % [center.x, center.y], log_process)

	if not instant: _target_position = center
	else:
		global_position = center
		_target_position = center
		pass
	return


## Moves the camera to the target position, using the top-left corner of the screen as the comparison point.
func set_target_topleft(topleft_corner: Vector2, instant: bool = false) -> void:
	Log.me("Setting target position x=%d y=%d to the top-left corner of the screen..." % [topleft_corner.x, topleft_corner.y])
	var viewport_size: Vector2 = get_viewport_rect().size
	var scaled_size: Vector2 = viewport_size / zoom
	var half_size: Vector2 = scaled_size / 2
	var new_position: Vector2 = topleft_corner + half_size

	if not instant: _target_position = new_position
	else:
		global_position = new_position
		_target_position = new_position
		pass
	return


func _move_camera(delta: float) -> void:
	if pan_duration > 0.0:
		var weight: float = delta / pan_duration
		global_position = global_position.lerp(_target_position, weight)
		pass
	else:
		global_position = _target_position
		pass
	return


# ---------- SCREEN SHAKE ----------
@export_group("Shake")
@export var shake_decay: float = 20.0
var _shake_strength: float = 0.0


func shake(strength: float) -> void:
	_shake_strength = strength
	return


func _handle_shake(delta: float) -> void:
	if _shake_strength > 0.0:
		_shake_strength = lerp(_shake_strength, 0.0, shake_decay * delta)

		var offset_x: float = randf_range(-_shake_strength, _shake_strength)
		var offset_y: float = randf_range(-_shake_strength, _shake_strength)
		offset = Vector2(offset_x, offset_y)
		pass

	else:
		offset = Vector2.ZERO
		pass
	return


# ---------- DEBUGGING ----------
@export_group("Debugging")
@export var log_ready: bool = false
@export var log_process: bool = false


# ---------- GODOT CALLBACKS ----------
func _enter_tree() -> void:
	Log.me("A CameraManager has entered the tree. Scanning...", log_ready)

	if instance != null:
		Log.err("Existing instance of CameraManager detected.", log_ready)
		queue_free()
		return

	instance = self
	return


func _process(delta: float) -> void:
	_move_camera(delta)
	_handle_shake(delta)
	return
