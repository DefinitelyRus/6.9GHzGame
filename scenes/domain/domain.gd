class_name Domain
extends Node2D

# ---------- COMPONENTS ----------
@export_group("Components")
@export var tilemap: TileMap
@export var world_objects: Node2D
var level: Level = null # Set by the Level itself.

@export_group("Visibility")
## The default layer is the integer representation of the `visibility_layer` property.
@export var default_layer: int = 0


func set_enabled(enable: bool) -> void:
	Log.me("Setting enabled = %s for domain %s from level %s." % [str(enable), name, level.name])
	visibility_layer = default_layer if enable else 0
	return
