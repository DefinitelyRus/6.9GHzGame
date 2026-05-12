class_name CameraManager
extends Camera2D

static var instance: CameraManager = null

func _enter_tree() -> void:
	Log.me("A CameraManager has entered the tree. Scanning...")
	if instance != null:
		Log.err("Existing instance of CameraManager detected.")
		queue_free()
		return
		
	instance = self
	return
