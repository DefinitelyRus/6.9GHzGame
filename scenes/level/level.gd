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

# ---------- CAMERA CONTROL ----------
var _camera_target_node: Node2D = null
func set_camera_focus(node: Node2D, instant: bool = false, track: bool = false) -> void:
	if node == null:
		Log.err("The provided node must not be null.", true, true)
		return
	
	Log.me("Focusing camera on node %s (x=%d y=%d)..." % [node.global_position.x, node.global_position.y])
	camera.set_target_centered(node.global_position, instant)
	if track: _camera_target_node = node

	Log.me("Done!")
	return


func _update_camera_focus(_delta):
	if _camera_target_node == null: return
	camera.set_target_centered(_camera_target_node.global_position, false)
	return



# ----- DOMAIN CONTROL -----
@export_group("Domains")
@onready var camera: CameraManager = CameraManager.instance
@export var irl_domain: Domain = null
@export var vr_domain: Domain = null
var player: Player
var active_domain: Domain
var _using_vr_domain: bool = false
var respawn_point: Vector2 = Vector2.ZERO
signal domain_switched(target_is_vr: bool)



## Sets the active domain to the fantasy domain.
func set_domain_view(use_vr_domain: bool) -> void:

	# VR view
	if use_vr_domain:
		# Fade in to black (0.5s)
		UIManager.fade_in_black(0.5)
		
		# Play VR on SFX
		AudioManager.stream_audio("vr_on", AudioManager.AudioChannels.MASTER)
		
		# Wait 0.5s for fade to complete
		await get_tree().create_timer(0.5).timeout
		
		# Switch domain
		vr_domain.set_enabled(true)
		irl_domain.set_enabled(false)
		active_domain = vr_domain

		# Play VR on animation
		if player != null and player.animation_handler != null:
			player.animation_handler.play_vr_on_animation()

		AudioManager.use_vr_audio(true)
		
		# Cut to white and fade out (0.5s)
		UIManager.set_white_overlay_opaque()
		UIManager.fade_out_white(0.5)

		pass

	# IRL view
	else:
		# Cut to black instantly
		UIManager.set_black_overlay_opaque()
		
		# Play VR off SFX
		AudioManager.stream_audio("vr_off", AudioManager.AudioChannels.MASTER)
		
		# Switch domain instantly
		vr_domain.set_enabled(false)
		irl_domain.set_enabled(true)
		active_domain = irl_domain

		AudioManager.use_vr_audio(false)
		
		# Fade out black (1.0s)
		UIManager.fade_out_black(1.0)

		pass

	_using_vr_domain = use_vr_domain
	domain_switched.emit(use_vr_domain)
	return


## Scans if the player has triggered a domain switch.
func _check_domain_switch_trigger(_delta) -> void:
	var should_switch: bool = InputManager.consume_action(InputManager.SWITCH_DOMAIN)
	if should_switch:
		var target_domain: bool = not _using_vr_domain
		domain_switched.emit(target_domain)
		set_domain_view(target_domain)
		pass
	return


# ---------- CHECKPOINTS ----------
func teleport_player_to_checkpoint() -> void:
	if player != null:
		player.global_position = respawn_point
		pass
	return



# ---------- DEBUGGING ----------
@export_group("Debugging")
@export var log_ready: bool = true
@export var log_calls: bool = true



# ---------- GODOT CALLBACKS ----------
func _ready() -> void:
	Log.me("Readying level %s. Scanning children and properties..." % name)

	if player_spawn_collection == null:
		Log.warn("player_spawn_collection is missing from children; cannot spawn player.")
		pass

	if npc_spawn_collection == null:
		Log.warn("npc_spawn_collection is missing from children; cannot spawn NPCs.")
		pass
	
	if enemy_spawn_collection == null:
		Log.warn("enemy_spawn_collection is missing from children; cannot spawn enemies.")
		pass
	
	if camera_focus_collection == null:
		Log.warn("camera_focus_collection is missing from children; camera may behave unnaturally.")
		pass
	
	else:
		if camera_focus_collection.get_child_count() > 0:
			var camera_focus_points: Array[Node2D] = []
			camera_focus_points.assign(camera_focus_collection.get_children())

			if camera_focus_points.size() > 0:
				var first_focus: Node2D = camera_focus_points[0]
				camera.set_target_topleft(first_focus.global_position, true)
				pass
			pass

		else: camera.set_target_topleft(camera_focus_collection.global_position, true)
		pass	

	# IRL DOMAIN
	if irl_domain == null:
		Log.warn("irl_domain is not set; cannot switch to IRL view.")
		pass
	
	else: irl_domain.level = self

	# VR DOMAIN
	if vr_domain == null:
		Log.err("vr_domain is not set; cannot switch to fantasy view.")
		return
	
	else: vr_domain.level = self

	#set_domain_view(true)
	AudioManager.stream_audio("music", AudioManager.AudioChannels.MUSIC_IRL)

	Log.me("Done!", log_ready, false)
	return


func _process(delta) -> void:
	_update_camera_focus(delta)
	_check_domain_switch_trigger(delta)
	return
