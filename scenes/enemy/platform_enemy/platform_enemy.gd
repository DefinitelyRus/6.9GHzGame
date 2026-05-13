class_name PlatformEnemy
extends Enemy

# Enemy AI patroller on platforms

@export_group("Platform Behaviors")
@export var patrol_speed: float = 40.0
@export var chase_speed: float = 150.0
@export var gravity: float = 500.0
@export var respected_edges: bool = true
@export var turn_at_walls: bool = true
@export var patrol_wait_time: float = 1.0

# Patroller
@export var patrol_points: Array[Marker2D] = []
var current_patrol_index: int = 0
var patrol_direction: int = 1
var is_waiting: bool = false
var wait_timer: float = 0.0

# Raycasting
var edge_check: RayCast2D
var wall_check: RayCast2D

# ---------- GODOT CALLBACKS ----------
func _initialize_enemy() -> void:
	setup_raycasts()
	current_state = State.PATROL
	return

func setup_raycasts() -> void:
	edge_check = RayCast2D.new()
	add_child(edge_check)
	edge_check.position = Vector2(20, 0)
	edge_check.target_position = Vector2(0, 30)
	edge_check.enabled = true
	edge_check.collision_mask = 1

	wall_check = RayCast2D.new()
	add_child(wall_check)
	wall_check.position = Vector2(0, -10)
	wall_check.target_position = Vector2(25, 0)
	wall_check.enabled = true
	wall_check.collision_mask = 1
	return

func update_ai(_delta: float) -> void:
	if is_stunned or current_state == State.HURT:
		velocity.x = 0
		return

	if is_waiting:
		wait_timer -= _delta
		if wait_timer <= 0:
			is_waiting = false
		velocity.x = 0
		return

	match current_state:
		State.IDLE:
			velocity.x = 0
			play_animation("idle")
		State.PATROL:
			patrol_behavior(_delta)
			play_animation("walk")
		State.CHASE:
			chase_behavior(_delta)
			play_animation("walk")
		State.ATTACK:
			attack_behavior(_delta)
			play_animation("attack")
	return

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if _hitstop_active:
		return

	# Tick attack cooldown
	if not _can_attack:
		_attack_cooldown_timer -= delta
		if _attack_cooldown_timer <= 0.0:
			_can_attack = true

	if not is_on_floor():
		velocity.y += gravity * delta

	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10 * delta)
	else:
		update_ai(delta)

	move_and_slide()
	update_sprite_direction()

	if global_position.y > 2000:
		queue_free()
	return

# ---------- PATROL BEHAVIOR ----------
func patrol_behavior(_delta: float) -> void:
	update_raycast_positions()

	if respected_edges and not edge_check.is_colliding():
		turn_around()

	if turn_at_walls and wall_check.is_colliding():
		turn_around()

	if not patrol_points.is_empty():
		patrol_between_points()
	else:
		velocity.x = patrol_speed * patrol_direction
		facing_direction = patrol_direction
	return

func patrol_between_points() -> void:
	if patrol_points.is_empty():
		return

	var target_point = patrol_points[current_patrol_index]
	var distance = abs(global_position.x - target_point.global_position.x)

	if distance < 10:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		start_waiting()
		return

	var direction_to_point = sign(target_point.global_position.x - global_position.x)
	velocity.x = direction_to_point * patrol_speed
	facing_direction = direction_to_point
	patrol_direction = direction_to_point
	AudioManager.stream_audio("enemy_footstep", AudioManager.AudioChannels.SFX_IRL)
	return

# ---------- CHASE BEHAVIOR ----------
func chase_behavior(_delta: float) -> void:
	if not target:
		current_state = State.PATROL
		return

	if is_target_in_range(attack_range):
		current_state = State.ATTACK
		emit_signal("state_changed", current_state)
		return

	var direction_to_target = sign(target.global_position.x - global_position.x)
	update_raycast_positions()

	var can_move = true
	if respected_edges and not edge_check.is_colliding():
		can_move = false

	if turn_at_walls and wall_check.is_colliding():
		can_move = false

	if can_move:
		velocity.x = direction_to_target * chase_speed
		facing_direction = direction_to_target
		AudioManager.stream_audio("enemy_chase", AudioManager.AudioChannels.SFX_IRL)
	else:
		velocity.x = 0
	return

# ---------- ATTACK BEHAVIOR ----------
func attack_behavior(_delta: float) -> void:
	if not target:
		current_state = State.PATROL
		return

	velocity.x = 0
	facing_direction = sign(target.global_position.x - global_position.x)

	if not is_target_in_range(attack_range):
		current_state = State.CHASE
		emit_signal("state_changed", current_state)
	return

# ---------- UTILITY ----------
func turn_around() -> void:
	patrol_direction *= -1
	facing_direction = patrol_direction
	AudioManager.stream_audio("enemy_turn", AudioManager.AudioChannels.SFX_IRL)
	start_waiting()
	return

func start_waiting() -> void:
	is_waiting = true
	wait_timer = patrol_wait_time
	return

func update_raycast_positions() -> void:
	if edge_check:
		edge_check.position.x = abs(edge_check.position.x) * facing_direction

	if wall_check:
		wall_check.target_position.x = abs(wall_check.target_position.x) * facing_direction
	return

func play_animation(anim_name: String) -> void:
	if sprite and sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)
	return


   
