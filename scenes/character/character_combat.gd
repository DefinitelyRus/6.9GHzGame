class_name CharacterCombat
extends Node2D

# ---------- STATE ----------
var in_combat: bool = false
var facing_direction: int = 1

# ---------- DEBUGGING ----------
@export_group("Debugging")
@export var log_ready: bool = false

# ---------- GODOT CALLBACKS ----------
func _ready() -> void:
	Log.me("Readying character combat %s. Scanning properties..." % name, log_ready)
	Log.me("Done!", log_ready)
	return

# ---------- PURPOSE-SPECIFIC METHODS ----------
func set_facing_direction(direction: int) -> void:
	facing_direction = direction
	return

func can_move() -> bool:
	return not in_combat

func is_in_combat() -> bool:
	return in_combat

func start_combat() -> void:
	in_combat = true
	Log.me("combat started")
	return

func end_combat() -> void:
	in_combat = false
	Log.me("combat ended")
	return
