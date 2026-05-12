class_name Master
extends Node

@export_group("Nodes & Components")
@export var background: TextureRect

@export_group("Debugging")
@export var log_ready: bool = false

static var instance: Master = null
static var is_paused: bool = false


# ---------- GODOT CALLBACKS ----------
func _enter_tree() -> void:
	if instance != null:
		Log.err("Existing instance of Master detected.", log_ready)
		queue_free()
		return
		
	instance = self
	return
