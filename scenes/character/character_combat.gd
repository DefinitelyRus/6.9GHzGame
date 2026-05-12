class_name CharacterCombat
extends Node

var in_combat: bool = false
var facing_direction: int = 1

func _ready() -> void:
	Log.me("Readying character combat %s. Scanning properties..." % name)
	Log.me("Done!", true, false)
	return

func set_facing_direction(direction: int) -> void:
	facing_direction = direction
	return

func can_move() -> bool:
	return not in_combat

func is_in_combat() -> bool:
	return in_combat

func start_combat() -> void:
	in_combat = true
	print("combat started")
	return

func end_combat() -> void:
	in_combat = false
	print("combat ended")
	return
