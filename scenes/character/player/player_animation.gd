class_name PlayerAnimation
extends CharacterAnimation

@export var vr_animated_sprite: AnimatedSprite2D

# ---------- GODOT CALLBACKS ----------
func _ready() -> void:
	super._ready()

	if character == null:
		Log.err("character is missing; animation won't work.")
		return
		
	if irl_animated_sprite == null:
		Log.warn("irl_animated_sprite missing; IRL animations won't work.")
		pass
	
	if vr_animated_sprite == null:
		Log.warn("vr_animated_sprite missing; VR animations won't work.")
		pass

	# Defer connection to avoid a race condition where Level._ready() hasn't run yet.
	_connect_to_level_signals.call_deferred()

	Log.me("Done!", log_ready)
	return

# ---------- ANIMATION HANDLING ----------
func _connect_to_level_signals() -> void:
	var level: Level = character.current_level
	if not is_instance_valid(level):
		Log.err("Cannot connect to level signals: character.current_level is null or invalid.", true, true)
		return
	
	Log.me("Connecting to domain_switched signal...", true, true)
	level.domain_switched.connect(_on_level_domain_switched)


func _on_level_domain_switched(switched_to_vr: bool) -> void:
	if switched_to_vr:
		vr_animated_sprite.show()
		irl_animated_sprite.hide()
		pass
	
	else:
		vr_animated_sprite.hide()
		irl_animated_sprite.show()
		pass
	return
