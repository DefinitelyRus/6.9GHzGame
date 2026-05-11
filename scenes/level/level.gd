class_name Level
extends Node2D

# ---------- COMPONENTS ----------
## The parent node of child nodes indicating the position of player spawn points.
@onready var player_spawn_collection: Node2D = $PlayerSpawns
## The parent node of child nodes indicating the position of NPC spawn points.
## Even though the Level owns this, the NPCs can exist in either the real or fantasy domains.
@onready var npc_spawn_collection: Node2D = $NPCSpawns
## The parent node of child nodes indicating the position of enemy spawn points.
## Even though the Level owns this, the enemies will only exist in the real domain.
@onready var enemy_spawn_collection: Node2D = $EnemySpawns
## The parent node of child nodes indicating the position of camera focus points.
@onready var camera_focus_collection: Node2D = $CameraFocusPoints


# ---------- DOMAIN CONTROL ----------
@export_group("Domains")
@onready var camera: CameraManager = CameraManager.instance
@export var real_domain: Domain = null
@export var fantasy_domain: Domain = null
var active_domain: Domain
var _using_fantasy_domain: bool = false


## Sets the active domain to the fantasy domain.
func use_fantasy_domain(enable: bool) -> void:
	if enable:
		fantasy_domain.set_enabled(true)
		real_domain.set_enabled(false)
		active_domain = fantasy_domain
		pass

	else:
		fantasy_domain.set_enabled(false)
		real_domain.set_enabled(true)
		active_domain = real_domain
		pass

	_using_fantasy_domain = enable
	return


# ---------- DEBUGGING ----------
@export_group("Debugging")
@export var log_ready: bool = true


# ---------- GODOT CALLBACKS ----------
func _ready() -> void:
	Log.me("Readying level %s. Scanning children and properties..." % name)

	if player_spawn_collection == null:
		Log.err("player_spawn_collection is missing from children; cannot spawn player.", true, false)
		return

	if npc_spawn_collection == null:
		Log.err("npc_spawn_collection is not missing from children; cannot spawn NPCs.", true, false)
		return
	
	if enemy_spawn_collection == null:
		Log.err("enemy_spawn_collection is not missing from children; cannot spawn enemies.", true, false)
		return
	
	if camera_focus_collection == null:
		Log.warn("camera_focus_collection is not missing from children; camera may behave unnaturally.", true, false)
		pass
	
	if real_domain == null:
		Log.err("real_domain is not set; cannot switch to IRL view.", true, false)
		return
	
	if fantasy_domain == null:
		Log.err("fantasy_domain is not set; cannot switch to fantasy view.", true, false)
		return
	
	Log.me("Done!", log_ready, false)
	return
