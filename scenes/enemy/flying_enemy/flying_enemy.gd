class_name FlyingEnemy
extends Enemy

# ---------- EXPORTS ----------
@export_group("Flying Behaviors")
@export var fly_speed: float = 80.0
@export var return_speed: float = 60.0      # speed when returning home (calmer than chase)
@export var swoop_speed: float = 250.0
@export var hover_height: float = 80.0
@export var hover_amplitude: float = 10.0
@export var hover_frequency: float = 1.5
@export var swoop_cooldown: float = 2.0
@export var swoop_distance: float = 200.0
@export var hover_side_offset: float = 60.0

 # ---------- STATE ----------
enum FlyingState { HOVERING, SWOOPING, RETREATING }

var flying_state: FlyingState = FlyingState.HOVERING
var hover_origin: Vector2
var hover_time: float = 0.0
var can_swoop: bool = true
var swoop_cooldown_timer: float = 0.0
var _retreat_target: Vector2 = Vector2.ZERO
var _is_returning: bool = false

# ---------- GODOT CALLBACKS ----------
func _initialize_enemy() -> void:
	hover_origin = global_position
	current_state = State.PATROL
	return

func update_ai(_delta: float) -> void:
	hover_time += _delta
	
	if swoop_cooldown_timer > 0.0:
		swoop_cooldown_timer -= _delta
		if swoop_cooldown_timer <= 0.0:
			can_swoop = true
			
	if is_stunned or current_state == State.HURT:
		velocity = velocity.lerp(Vector2.ZERO, 15.0 * _delta)
		return
		
	match current_state:
		State.IDLE, State.PATROL:
			_idle_hover(_delta)
		State.CHASE:
			_chase_behavior()
		State.ATTACK:
			_swoop_towards_target()
	return
	


# ---------- FLYING BEHAVIOR ----------
func _get_return_state() -> int:
	return State.IDLE

func _idle_hover(_delta: float) -> void:
	if _is_returning:
		_return_home(_delta)
		return

	var bob := sin(hover_time * hover_frequency) * hover_amplitude
	var dest := hover_origin + Vector2(0.0, bob)
	# Smooth lerp, not raw multiply — no violent snapping
	velocity = velocity.lerp((dest - global_position) * 4.0, 0.1)


func _return_home(_delta: float) -> void:
	var to_home := hover_origin - global_position
	var dist := to_home.length()

	if dist < 12.0:
		# Arrived — resume idle bob
		_is_returning = false
		velocity = velocity.lerp(Vector2.ZERO, 10.0 * _delta)
		return

	# Ease in proportionally, cap at return_speed
	var speed := minf(return_speed, dist * 3.0)
	velocity = velocity.lerp(to_home.normalized() * speed, 0.08)

func _chase_behavior() -> void:
	if not target:
		_begin_return()
		return

	facing_direction = -1 if target.global_position.x < global_position.x else 1

	var dist := get_distance_to_target()
	if dist <= swoop_distance and can_swoop and flying_state == FlyingState.HOVERING:
		_initiate_swoop()
		return

	match flying_state:
		FlyingState.HOVERING:
			_hover_near_player()
		FlyingState.RETREATING:
			_retreat_to_hover()
		FlyingState.SWOOPING: _swoop_towards_target()


func _hover_near_player() -> void:
	if not target:
		return

	var bob := sin(hover_time * hover_frequency) * hover_amplitude
	var offset_vector := Vector2(
		facing_direction * hover_side_offset,
		-hover_height + bob
	)
	var dest := target.global_position + offset_vector
	var to_dest := dest - global_position
	var dist := to_dest.length()

	if dist > 5.0:
		var speed := minf(fly_speed, dist * 4.0)
		velocity = velocity.lerp(to_dest.normalized() * speed, 0.15)
	else:
		velocity = velocity.lerp(Vector2.ZERO, 0.3)


func _initiate_swoop() -> void:
	flying_state = FlyingState.SWOOPING
	current_state = State.ATTACK
	emit_signal("state_changed", current_state)
	AudioManager.stream_audio("flying_enemy_swoop", AudioManager.AudioChannels.SFX_IRL)
	if sprite and sprite.sprite_frames.has_animation("Swoop"):
		sprite.play("Swoop")

func _swoop_towards_target():
	if not target:
		if not target:
			flying_state = FlyingState.HOVERING
			current_state = State.CHASE
		return

	velocity = get_direction_to_target() * swoop_speed

	if get_distance_to_target() > swoop_distance * 1.5 or is_on_floor():
		_start_retreat()


func _start_retreat() -> void:
	flying_state = FlyingState.RETREATING
	current_state = State.CHASE
	can_swoop = false
	swoop_cooldown_timer = swoop_cooldown
	_retreat_target = global_position + Vector2(facing_direction * -120.0, -160.0)
	if sprite and sprite.sprite_frames.has_animation("Fly"):
		sprite.play("Fly")


func _retreat_to_hover() -> void:
	var to_dest := _retreat_target - global_position
	var dist := to_dest.length()

	if dist < 30.0:
		flying_state = FlyingState.HOVERING
		current_state = State.CHASE
		return

	var speed := minf(fly_speed, dist * 4.0)
	velocity = velocity.lerp(to_dest.normalized() * speed, 0.15)


func _begin_return() -> void:
	# Reset combat flying state so next aggro starts fresh
	flying_state = FlyingState.HOVERING
	can_swoop = true
	swoop_cooldown_timer = 0.0
	target = null
	_is_returning = true
	current_state = State.IDLE
	emit_signal("state_changed", current_state)

	if sprite and sprite.sprite_frames.has_animation("Fly"):
		sprite.play("Fly")


func _on_detection_area_exited(body: Node2D) -> void:
	if body == target:
		_begin_return()


func attack_player(player: Node2D) -> void:
	if flying_state == FlyingState.SWOOPING:
		super.attack_player(player)
		_start_retreat()


func _physics_process(_delta: float) -> void:
	if current_state == State.DEAD:
		return

	if _hitstop_active:
		return

	# Tick attack cooldown
	if not _can_attack:
		_attack_cooldown_timer -= _delta
		if _attack_cooldown_timer <= 0.0:
			_can_attack = true

	if swoop_cooldown_timer > 0.0:
		swoop_cooldown_timer -= _delta
		if swoop_cooldown_timer <= 0.0:
			can_swoop = true

	if current_state == State.KNOCKED_OUT:
		velocity = velocity.lerp(Vector2.ZERO, 5.0 * _delta)

		if knockback_velocity.length() > 0:
			velocity = knockback_velocity
			knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10.0 * _delta)
		move_and_slide()
		update_sprite_direction()
		return

	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10.0 * _delta)

	else:
		update_ai(_delta)

	move_and_slide()
	update_sprite_direction()
