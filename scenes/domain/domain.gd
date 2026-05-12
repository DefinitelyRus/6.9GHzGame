class_name Domain
extends Node2D

# ---------- COMPONENTS ----------
@onready var world_objects: Node2D = $WorldObjects # Add to on_ready check
var level: Level = null


# ---------- DOMAIN VISIBILITY ----------
@export_group("Domain Visibility")

## The default layer is the integer representation of the `visibility_layer` property.
@export var default_layer: int = 0


func set_enabled(enable: bool) -> void:
	visible = enable
	return


# ---------- DEBUGGING ----------
@export var log_ready: bool = false



# ---------- GODOT CALLBACKS ----------
func _ready() -> void:
	Log.me("Readying domain %s. Scanning children and properties..." % name, log_ready, true)

	if default_layer < 1 or default_layer > 5:
		Log.err("A domain's default visibility layer should be between 1 to 5 only.", true, false)
		return
	
	var domain_bit: int = (1 << (default_layer - 1))
	var updated_visibility_layer: int = domain_bit | 0xFFFE0
	var children: Array[Node] = get_children(true)

	visibility_layer = updated_visibility_layer
	for child: Node in children:
		if child is not Node2D: continue
		var child_2d: Node2D = child as Node2D
		child_2d.visibility_layer = updated_visibility_layer
		pass
	
	level = SceneLoader.get_current_level_as_level()

	Log.me("Done!", log_ready, false)
	return
