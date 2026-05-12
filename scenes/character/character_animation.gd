class_name CharacterAnimation
extends Node

@export var character: Character
@export var animated_sprite: AnimatedSprite2D


func _ready() -> void:
	Log.me("Readying character animation %s. Scanning properties..." % name)
	_resolve_dependencies()

	if character == null:
		Log.err("character is missing; animation won't work.", true, false)
		return

	if animated_sprite == null:
		Log.warn("AnimatedSprite2D missing; animations won't work.", true, false)
		pass

	Log.me("Done!", true, false)
	return


func _process(_delta: float) -> void:
	_update_facing_direction()
	_update_animation_state()
	return


func _resolve_dependencies() -> void:
	if character == null: character = get_parent() as Character
		
	if character != null and animated_sprite == null:
		var n: Node = character.get_node_or_null("AnimatedSprite2D")
		animated_sprite = n as AnimatedSprite2D
		pass

	return


func _update_facing_direction() -> void:
	if character == null or animated_sprite == null: return
		
	var facing_direction: int = character.facing_direction
	if facing_direction > 0: animated_sprite.flip_h = false
	elif facing_direction < 0: animated_sprite.flip_h = true
	return


func _update_animation_state() -> void:
	if character == null or animated_sprite == null: return
		
	var combat_handler: Node = character.combat_handler
	if combat_handler != null:
		if combat_handler.has_method("is_in_combat"):
			if combat_handler.is_in_combat(): return
			pass
		pass

	if not character.is_on_floor(): animated_sprite.play("Jump")
	elif abs(character.velocity.x) > 10.0: animated_sprite.play("Run")
	else: animated_sprite.play("Idle")
	return
