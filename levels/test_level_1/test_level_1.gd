class_name TestLevel1
extends Level

func _ready() -> void:
	super._ready()
	#camera.set_target_topleft(Vector2.ZERO, true)
	
	var player: Player = real_domain.world_objects.get_child(0) as Player
	Log.me("Setting player %s as the target..." % player.name)
	camera.set_target_centered(player.global_position, true)
	pass
