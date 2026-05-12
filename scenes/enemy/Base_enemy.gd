extends CharacterBody2D
class_name BaseEnemy

##All enemies will inherit from this

#stats
@export_group("Stats")
@export var max_health: float = 100.0
@export var damage: float = 10.0
@export var knockback_resistance: float = 1.0

#detection
@export_group("Detection")
@export var detection_range: float = 200.0
@export var attack_range: float = 50.0
@export var lose_aggro_range: float = 200.0

@export_group("References")
@export var sprite: AnimatedSprite2D
@export var detection_area: Area2D
@export var attack_area: Area2D

enum State{
	IDLE, CHASE, ATTACK, PATROL, HURT, DEAD
}

var current_state: State = State.IDLE
var current_health: float 
var target: Node2D = null
var is_stunned: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var facing_direction: int = 1

#signals
signal health_changed(current_health, max_health)
signal died()
signal damaged(amount)
signal state_changed(new_state)
signal player_detected(player)

func _ready():
	current_health = max_health

	setup_detection()
	initialize_enemy()
	return


func setup_detection():
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
	
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_entered)

	return


func initialize_enemy():
	#overridden by specific enemy types for unique setup
	pass


func _physics_process(delta):
	if current_state == State.DEAD:
		return

	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10 * delta)

	update_ai(delta)
	move_and_slide()
	update_sprite_direction()

	return


func update_ai(delta):
	#override in child
	pass


func update_sprite_direction():
	if sprite and facing_direction != 0:
		sprite.flip_h = facing_direction < 0


#DMG SYS
func take_damage(amount: float):
	if current_state == State.DEAD:
		return

	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health, max_health)
	emit_signal("damaged", amount)

	flash_sprite()

	if current_health > 0:
		enter_hurt_state()
	else:
		die()

	return


func flash_sprite():
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		pass
		
		if sprite:
			sprite.modulate = Color.WHITE
			pass
		return

func enter_hurt_state():

	var previous_state = current_state
	current_state = State.HURT
	emit_signal("state_changed", current_state)

	await get_tree().create_timer(0.5).timeout

	if target:
		current_state = State.CHASE
		pass

	else:
		current_state = previous_state	
		pass

	return


func apply_knockback(force: Vector2):
	knockback_velocity += force * (1 - knockback_resistance)
	return

func stun(duration: float):
	is_stunned = true
	if sprite:
		sprite.modulate = Color.BLUE
		pass

	await get_tree().create_timer(duration).timeout
	is_stunned = false

	if sprite and current_state != State.DEAD:
		sprite.modulate = Color.WHITE
		pass
	return

func die():
	current_state = State.DEAD
	emit_signal("died")
	emit_signal("state_changed", current_state)

	if sprite:
		sprite.play("death")
		sprite.modulate = Color.GRAY
		pass

	set_collision_layer_value(2, false)
	set_collision_mask_value(3, false)

	await get_tree().create_timer(2.0).timeout
	queue_free()

	return

#DETECTION HANDLING

func _on_detection_area_entered(body):
	# Check all possible player detection methods
	var is_player = (
		body.is_in_group("Player") or 
		body.is_in_group("player") or 
		body.name == "Player" or
		body.name.to_lower() == "player"
	)
	
	if is_player:
		target = body
		emit_signal("player_detected", body)
		pass

		if current_state == State.IDLE or current_state == State.PATROL:
			current_state = State.CHASE
			emit_signal("state_changed", current_state)
			pass
	return


func _on_detection_area_exited(body: Node2D):
	if body == target:
		if global_position.distance_to(target.global_position) > lose_aggro_range:
		
			target = null
			current_state = State.IDLE
			emit_signal("state_changed", current_state)
			pass
	return

func _on_attack_area_entered(body: Node2D):
	var is_player = (
		body.is_in_group("player") or 
		body.is_in_group("Player") or 
		body.name == "Player"
	)
	
	if is_player and body.has_method("take_damage"):
		attack_player(body)
		pass
	return


func attack_player(player: Node2D):
	if player.has_method("take_damage"):
		player.take_damage(damage)
		pass
	return

#MISC
func get_direction_to_target() -> Vector2:
	if target:
		return (target.global_position - global_position).normalized()
	return Vector2.ZERO


func get_distance_to_target() -> float:
	if target:
		return global_position.distance_to(target.global_position)
	return INF


func is_target_in_range(range_value: float) -> bool:
	return get_distance_to_target() <= range_value
