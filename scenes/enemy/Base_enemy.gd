extends CharacterBody2D
class_name BaseEnemy

##All enemies will inherit from this

@export_group("Stats")
@export var max_health: float = 100.0
@export var damage: float = 10.0
@export var knockback_resistance: float = 0.0

@export_group("Detection")
@export var detection_range: float = 200.0
@export var attack_range: float = 50.0
@export var lose_aggro_range: float = 200.0

@export_group("References")
@export var sprite: AnimatedSprite2D
@export var detection_area: Area2D
@export var attack_area: Area2D
## Assign in scene: Area2D child positioned over the enemy's weak spot (e.g. head)
@export var weakpoint_area: Area2D

@export_group("Combat Feel")
@export var hitstop_duration: float = 0.06
@export var hitstop_duration_weakpoint: float = 0.12
@export var hit_particles_scene: PackedScene
@export var weakpoint_particles_scene: PackedScene

## Seconds between enemy attacks (prevents spam damage)
@export var attack_cooldown: float = 1.0

enum State { IDLE, CHASE, ATTACK, PATROL, HURT, DEAD, KNOCKED_OUT }

var current_state: State = State.IDLE
var current_health: float
var target: Node2D = null
var is_stunned: bool = false
var is_knocked_out: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var facing_direction: int = 1

var _hitstop_active: bool = false
var _attack_cooldown_timer: float = 0.0
var _can_attack: bool = true

signal health_changed(current_health, max_health)
signal died()
signal damaged(amount)
signal state_changed(new_state)
signal player_detected(player)
signal weakpoint_hit()


func _ready():
	current_health = max_health
	setup_detection()
	initialize_enemy()


func setup_detection():
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)

	if attack_area:
		# Layer 5 = Player body; body_entered fires when player walks into attack range
		attack_area.area_entered.connect(_on_attack_area_entered_area)
		attack_area.body_entered.connect(_on_attack_area_entered_body)


func initialize_enemy():
	#inherit
	pass


func _physics_process(delta):
	if current_state == State.DEAD:
		return

	if _hitstop_active:
		return

	# Tick attack cooldown
	if not _can_attack:
		_attack_cooldown_timer -= delta
		if _attack_cooldown_timer <= 0.0:
			_can_attack = true

	if current_state == State.KNOCKED_OUT:
		velocity.x = move_toward(velocity.x, 0, 300 * delta)
		if knockback_velocity.length() > 0:
			velocity = knockback_velocity
			knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10 * delta)
		move_and_slide()
		update_sprite_direction()
		return

	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10 * delta)
	else:
		update_ai(delta)

	move_and_slide()
	update_sprite_direction()


func update_ai(delta):
	pass


func update_sprite_direction():
	if sprite and facing_direction != 0:
		sprite.flip_h = facing_direction < 0



# DAMAGE SYSTEM
func take_damage(amount: float, hit_position: Vector2 = Vector2.INF):
	if current_state == State.DEAD or current_state == State.KNOCKED_OUT:
		return

	var on_weakpoint := false
	if hit_position != Vector2.INF and weakpoint_area != null:
		on_weakpoint = _is_position_in_area(hit_position, weakpoint_area)

	_apply_damage(amount, on_weakpoint, hit_position)


func take_damage_from_area(amount: float, source_area: Area2D):
	if current_state == State.DEAD or current_state == State.KNOCKED_OUT:
		return

	var on_weakpoint := (weakpoint_area != null and source_area == weakpoint_area)
	_apply_damage(amount, on_weakpoint, global_position)


func _apply_damage(amount: float, on_weakpoint: bool, particle_pos: Vector2):
	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health, max_health)
	emit_signal("damaged", amount)

	_spawn_hit_particles(particle_pos if particle_pos != Vector2.INF else global_position, on_weakpoint)
	_play_hit_flash(on_weakpoint)
	_do_hitstop(hitstop_duration_weakpoint if on_weakpoint else hitstop_duration)

	if current_health <= 0:
		die()
		return

	if on_weakpoint:
		emit_signal("weakpoint_hit")
		_enter_knockout(randf_range(6.0, 12.0))
		return

	else:
		enter_hurt_state()
	
	return

# HIT FLASH

func _play_hit_flash(is_weakpoint: bool = false):

	if not sprite:
		return
		
	var flash_color := Color(1.5, 1.2, 0.0) if is_weakpoint else Color(2.0, 2.0, 2.0)
	var flash_duration := 0.12 if is_weakpoint else 0.08

	if is_weakpoint:
		for _i in range(2):
			sprite.modulate = flash_color
			await get_tree().create_timer(flash_duration * 0.5).timeout
			sprite.modulate = Color.WHITE
			await get_tree().create_timer(0.03).timeout
	else:
		sprite.modulate = flash_color
		await get_tree().create_timer(flash_duration).timeout
		if sprite and current_state != State.DEAD:
			sprite.modulate = Color.WHITE


# HITSTOP
func _do_hitstop(duration: float):
	if duration <= 0.0:
		return
		
	_hitstop_active = true
	var saved_velocity := velocity

	velocity = Vector2.ZERO
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true).timeout  # true = ignore time scale
	
	Engine.time_scale = 1.0
	_hitstop_active = false
	velocity = saved_velocity


# PARTICLES
func _spawn_hit_particles(pos: Vector2, is_weakpoint: bool):
	var scene := weakpoint_particles_scene if (is_weakpoint and weakpoint_particles_scene) else hit_particles_scene
	if scene == null:
		return

	var particles = scene.instantiate()
	get_parent().add_child(particles)
	particles.global_position = pos

	if particles.has_method("restart"):
		particles.one_shot = true
		particles.emitting = true

		var lifetime: float = (particles.lifetime as float) if "lifetime" in particles else 1.0
		await get_tree().create_timer(lifetime + 0.1).timeout

		if is_instance_valid(particles):
			particles.queue_free()

# STATES

func enter_hurt_state():
	var previous_state := current_state
	current_state = State.HURT
	emit_signal("state_changed", current_state)
	is_stunned = true

	if sprite:
		sprite.modulate = Color(0.4, 0.8, 1.0)

	await get_tree().create_timer(0.6).timeout  # actual stun window
	is_stunned = false

	if sprite and current_state != State.DEAD and current_state != State.KNOCKED_OUT:
		sprite.modulate = Color.WHITE

	if current_state == State.DEAD or current_state == State.KNOCKED_OUT:
		return

	current_state = State.CHASE if target else previous_state
	emit_signal("state_changed", current_state)


func _enter_knockout(duration: float):
	is_knocked_out = true
	current_state = State.KNOCKED_OUT
	emit_signal("state_changed", current_state)

	if sprite:
		sprite.modulate = Color(0.6, 0.6, 1.0)
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("knocked_out"):
			sprite.play("knocked_out")

	await get_tree().create_timer(duration).timeout

	if current_state == State.DEAD:
		return

	is_knocked_out = false
	current_state = State.IDLE if not target else State.CHASE
	emit_signal("state_changed", current_state)

	if sprite:
		sprite.modulate = Color.WHITE


func apply_knockback(force: Vector2):
	knockback_velocity += force * (1.0 - knockback_resistance)


func stun(duration: float):
	is_stunned = true
	if sprite:
		sprite.modulate = Color(0.4, 0.8, 1.0)

	await get_tree().create_timer(duration).timeout
	is_stunned = false

	if sprite and current_state != State.DEAD and current_state != State.KNOCKED_OUT:
		sprite.modulate = Color.WHITE


func die():
	current_state = State.DEAD
	emit_signal("died")
	emit_signal("state_changed", current_state)

	if sprite:
		sprite.play("death")
		sprite.modulate = Color.GRAY

	set_collision_layer_value(2, false)
	set_collision_mask_value(3, false)

	await get_tree().create_timer(2.0).timeout
	queue_free()



# ENEMY ATTACKS PLAYER — one-hit kill with cooldown
func _on_attack_area_entered_area(area: Area2D):
	var body = area.get_parent()
	_try_attack_player(body)


func _on_attack_area_entered_body(body: Node2D):
	_try_attack_player(body)


func _try_attack_player(body: Node2D):
	if not _can_attack:
		return
		
	if current_state == State.DEAD or current_state == State.KNOCKED_OUT:
		return

	var is_player = (
		body.is_in_group("player") or
		body.is_in_group("Player") or
		body.name == "Player" or
		body.name.to_lower() == "player"
	)

	if is_player:
		_can_attack = false
		_attack_cooldown_timer = attack_cooldown
		attack_player(body)
	return


func attack_player(player: Node2D):
	## One-hit kill: drain all health at once
	if player.has_method("take_fatal_damage"):
		player.take_fatal_damage()
	elif player.has_method("take_damage"):
		# Pass the player's full health so it always kills regardless of current HP
		var player_health = player.health if "health" in player else 9999.0
		player.take_damage(player_health)


# DETECTION
func _on_detection_area_entered(body):
	var is_player = (
		body.is_in_group("Player") or
		body.is_in_group("player") or
		body.name == "Player" or
		body.name.to_lower() == "player"
	)

	if is_player:
		target = body
		emit_signal("player_detected", body)
		
		if current_state == State.IDLE or current_state == State.PATROL:
			current_state = State.CHASE
			emit_signal("state_changed", current_state)


func _on_detection_area_exited(body: Node2D):
	if body == target:
		target = null
		current_state = State.IDLE
		emit_signal("state_changed", current_state)


# MISC
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


func _is_position_in_area(world_pos: Vector2, area: Area2D) -> bool:
	for child in area.get_children():
		if child is CollisionShape2D and child.shape != null:
			var local_pos := area.to_local(world_pos)
			if child.shape.get_rect().has_point(local_pos - child.position):
				return true
	return false
