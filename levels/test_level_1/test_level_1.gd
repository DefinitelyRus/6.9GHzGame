class_name TestLevel1
extends Level

func _ready() -> void:
	super._ready()
	
	var player: Player = irl_domain.world_objects.get_child(0) as Player
	#Log.me("Setting %s as the target..." % player.name)
	set_camera_focus(player, true, true)
	#camera.set_target_centered(player.global_position)
	pass


func _process(delta) -> void:
	super._process(delta)
	
	# var player: Player = irl_domain.world_objects.get_child(0) as Player
	# Log.me("Focusing on %s" % player.name)
	# camera.set_target_centered(player.global_position)
	return
