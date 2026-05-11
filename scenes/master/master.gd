class_name Master
extends Node

@export_group("Nodes & Components")
@export var background: TextureRect

@export_group("Debugging")
@export var log_ready: bool = false

static var instance: Master
static var is_paused: bool = false


# ---------- GODOT CALLBACKS ----------
func _enter_tree() -> void:
	if instance != null:
		Log.err("Another Master instance already exists! This instance will remove itself.", log_ready)
		queue_free()
		return
		
	instance = self
	return
