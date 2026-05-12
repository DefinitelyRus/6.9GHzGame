class_name TestLevel1
extends Level

func _ready() -> void:
	super._ready()
	_setup_initial_camera_focus()
	return


func _process(delta) -> void:
	super._process(delta)
	return


func _setup_initial_camera_focus() -> void:
	Log.me("Player exists: %s" % str(player != null))

	if not is_instance_valid(player):
		Log.err("Could not find 'Player' node to set initial camera focus.")
		return

	set_camera_focus(player, true, true)
	return
