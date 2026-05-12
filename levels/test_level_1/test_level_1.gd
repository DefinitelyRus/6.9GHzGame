class_name TestLevel1
extends Level

func _ready() -> void:
	super._ready()
	
	var player: Player = irl_domain.world_objects.get_child(0) as Player
	Log.me("Setting %s as the target..." % player.name)
	camera.set_target_centered(player.global_position, true)
	pass
