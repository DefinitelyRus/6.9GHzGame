extends BaseEnemy
class_name PlatformEnemy

#enemy AI patroller on platforms

@export_group("Platform Behaviors")
@export var patrol_speed: float = 40.0
@export var chase_speed: float = 150.0
@export var gravity: float = 500.0
@export var respected_edges: bool = true
@export var turn_at_walls: bool = true
@export var patrol_wait_time: float = 1.0

#patroller
@export var patrol_points: Array[Marker2D] = [] #can be set to empty for simple edge patrolling
var current_patrol_index: int = 0
var patrol_direction: int = 1 #1 for forward, -1 for backward
var is_waiting: bool = false
var wait_timer: float = 0.0

#raycasting
var edge_check: RayCast2D
var wall_check: RayCast2D

func initialize_enemy():
	setup_raycasts()
	current_state = State.PATROL

	if patrol_points.is_empty():
		patrol_direction = 1
		pass
		return

func setup_raycasts():
	edge_check = RayCast2D.new()
	add_child(edge_check)
	edge_check.position = Vector2(20,0) #x forward offset
	edge_check.target_position = Vector2(0, 30) #y downward offset
	edge_check.enabled = true
	edge_check.collision_mask = 1 #layer checking

	wall_check = RayCast2D.new()
	add_child(wall_check)
	wall_check.position = Vector2(0,-10)
	wall_check.target_position = Vector2(25,0)
	wall_check.enabled = true
	wall_check.collision_mask= 1
	return


func update_ai(delta):
	if is_stunned or current_state == State.HURT:
		velocity.x = 0
		return

	if is_waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			is_waiting = false
		velocity.x = 0
		return

	match current_state:
		State.IDLE:
			velocity.x = 0
			play_animation("idle")
		
		State.PATROL:
			patrol_behavior(delta)
			play_animation("walk")

		State.CHASE:
			chase_behavior(delta)
			play_animation("walk")

		State.ATTACK:
			attack_behavior(delta)
			play_animation("attack")
	return

func patrol_behavior(delta):
	update_raycast_positions()

	if respected_edges and not edge_check.is_colliding():
		turn_around()
		pass

	if turn_at_walls and wall_check.is_colliding():
		turn_around()
		pass

	if not patrol_points.is_empty():
		patrol_between_points()
		pass

	else:
		velocity.x = patrol_speed * patrol_direction
		facing_direction = patrol_direction
		pass

	return


func patrol_between_points():
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
	return

func chase_behavior(delta):
	if not target:
		current_state = State.PATROL
		return

	if is_target_in_range(attack_range):
		current_state = State.ATTACK
		emit_signal("state_changed", current_state)
		return

	#vector in on the player
	var direction_to_target = sign(target.global_position.x - global_position.x)

	update_raycast_positions()

	var can_move = true
	if respected_edges and not edge_check.is_colliding():
		can_move = false
		pass

	if turn_at_walls and wall_check.is_colliding():
		can_move = false
		pass

	if can_move:
		velocity.x = direction_to_target * chase_speed
		facing_direction = direction_to_target
		pass

	else:
		velocity.x = 0
		pass
	return

func attack_behavior(delta):
	if not target:
		current_state = State.PATROL
		pass

	velocity.x = 0

	facing_direction = sign(target.global_position.x - global_position.x)

	if not is_target_in_range(attack_range):
		current_state = State.CHASE
		emit_signal("state_changed", current_state)
		pass

	return


func turn_around():
	patrol_direction *= -1
	facing_direction = patrol_direction
	start_waiting()
	return

func start_waiting():
	is_waiting = true
	wait_timer = patrol_wait_time
	return

func update_raycast_positions():
	
	if edge_check:
		edge_check.position.x = abs(edge_check.position.x) * facing_direction
		pass

	if wall_check:
		wall_check.target_position.x = abs(wall_check.target_position.x) * facing_direction
		pass
		
func play_animation(anim_name: String):
	if sprite and sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y += gravity * delta
		pass

	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10 * delta)
		pass

	else:
		update_ai(delta)
		pass

	move_and_slide()
	update_sprite_direction()

	if global_position.y > 2000: #in case of void fall off
		queue_free()
		pass
	return


   
