class_name Player
extends Character

func _ready() -> void:
	Log.me("Readying player %s. Scanning properties..." % name)
	super._ready()
	Log.me("Done!", true, false)
	return


func _physics_process(delta: float) -> void:
	_poll_inputs()
	super._physics_process(delta)
	return


func _poll_inputs() -> void:
	move_direction = InputManager.move_vector.x
	jump_intent = InputManager.consume_action(InputManager.JUMP)
	return
