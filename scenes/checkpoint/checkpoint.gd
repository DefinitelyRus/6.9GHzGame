class_name Checkpoint
extends Area2D

# ---------- COMPONENTS ----------
var current_level: Level = null


# ---------- GODOT CALLBACKS ----------
func _enter_tree() -> void:
	Log.me("Checkpoint %s has entered the tree." % name)
	current_level = SceneLoader.get_current_level_as_level()
	Log.me("Done!")
	return


func _ready() -> void:
	Log.me("Readying checkpoint %s. Scanning children and properties..." % name)
	
	if current_level == null:
		Log.warn("current_level is null; checkpoint respawn functionality may not work.")
		pass
	
	body_entered.connect(_on_body_entered)
	Log.me("Done!")
	return


# ---------- INTERACTION HANDLING ----------
func _on_body_entered(body: Node2D) -> void:
	if body is not Player:
		return
	
	var player: Player = body as Player
	var is_in_irl_domain: bool = not current_level._using_vr_domain
	
	if not is_in_irl_domain:
		return
	
	set_as_spawnpoint(player.global_position)
	return


# ---------- PURPOSE-SPECIFIC METHODS ----------
## Sets this checkpoint as the respawn point for the current level.
## The player will respawn at the provided position.
## Calls special_action before completing.
func set_as_spawnpoint(respawn_position: Vector2) -> void:
	Log.me("Setting checkpoint respawn point at position (x=%d y=%d)..." % [int(respawn_position.x), int(respawn_position.y)])
	
	if current_level == null:
		Log.err("current_level is null; cannot set respawn point.", true, true)
		return
	
	special_action()
	current_level.respawn_point = respawn_position
	Log.me("Done!")
	return


## Override this in child classes to add custom behavior when a checkpoint is activated.
## This is called before the respawn point is saved.
func special_action() -> void:
	pass
