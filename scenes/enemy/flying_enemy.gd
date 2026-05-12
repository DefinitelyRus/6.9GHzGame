extends BaseEnemy
class_name FlyingEnemy

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

enum FlyingState { HOVERING, SWOOPING, RETREATING }

var flying_state: FlyingState = FlyingState.HOVERING
var hover_origin: Vector2
var hover_time: float = 0.0
var can_swoop: bool = true
var swoop_cooldown_timer: float = 0.0
var _retreat_target: Vector2 = Vector2.ZERO


func initialize_enemy():
	hover_origin = global_position
	current_state = State.PATROL


func update_ai(delta: float):
	hover_time += delta

	if swoop_cooldown_timer > 0.0:
		swoop_cooldown_timer -= delta
		if swoop_cooldown_timer <= 0.0:
			can_swoop = true

	if is_stunned or current_state == State.HURT:
		velocity = velocity.lerp(Vector2.ZERO, 15.0 * delta)
		return

	match current_state:
		State.IDLE, State.PATROL:
			_idle_hover(delta)
		State.CHASE:
			_chase_behavior()
		State.ATTACK:
			_swoop_towards_target()
		
			if current_state == _get_return_state():
				_return_home(delta)

var _is_returning: bool = false


func _get_return_state() -> int:
	return State.IDLE  


# IDLE / PATROL — gentle bob at spawn
func _idle_hover(delta: float):
	if _is_returning:
		_return_home(delta)
		return

	var bob := sin(hover_time * hover_frequency) * hover_amplitude
	var dest := hover_origin + Vector2(0.0, bob)
	# Smooth lerp, not raw multiply — no violent snapping
	velocity = velocity.lerp((dest - global_position) * 4.0, 0.1)


# RETURN HOME — called after losing aggro
func _return_home(delta: float):
	var to_home := hover_origin - global_position
	var dist := to_home.length()

	if dist < 12.0:
		# Arrived — resume idle bob
		_is_returning = false
		velocity = velocity.lerp(Vector2.ZERO, 10.0 * delta)
		return

	# Ease in proportionally, cap at return_speed
	var speed := minf(return_speed, dist * 3.0)
	velocity = velocity.lerp(to_home.normalized() * speed, 0.08)


# CHASE — circle above player, swoop when ready
func _chase_behavior():
	if not target:
		_begin_return()
		return

	facing_direction = -1 if target.global_position.x < global_position.x else 1

	var dist := get_distance_to_target()
	if dist <= swoop_distance and can_swoop and flying_state == FlyingState.HOVERING:
		_initiate_swoop()
		return

	match flying_state:
		FlyingState.HOVERING:   _hover_near_player()
		FlyingState.SWOOPING:   _swoop_towards_target()
		FlyingState.RETREATING: _retreat_to_hover()


func _hover_near_player():
	if not target:
		return

	var bob := sin(hover_time * hover_frequency) * hover_amplitude
	var dest := target.global_position + Vector2(
		facing_direction * hover_side_offset,
		-hover_height + bob
	)
	var to_dest := dest - global_position
	var dist := to_dest.length()

	if dist > 5.0:
		var speed := minf(fly_speed, dist * 4.0)
		velocity = velocity.lerp(to_dest.normalized() * speed, 0.15)
	else:
		velocity = velocity.lerp(Vector2.ZERO, 0.3)


# SWOOP/ATTAC
func _initiate_swoop():
	flying_state = FlyingState.SWOOPING
	current_state = State.ATTACK
	emit_signal("state_changed", current_state)
	if sprite and sprite.sprite_frames.has_animation("Swoop"):
		sprite.play("Swoop")


func _swoop_towards_target():
	if not target:
		flying_state = FlyingState.HOVERING
		current_state = State.CHASE
		return

	velocity = get_direction_to_target() * swoop_speed

	if get_distance_to_target() > swoop_distance * 1.5 or is_on_floor():
		_start_retreat()


func _start_retreat():
	flying_state = FlyingState.RETREATING
	can_swoop = false
	swoop_cooldown_timer = swoop_cooldown
	_retreat_target = global_position + Vector2(facing_direction * -120.0, -160.0)
	if sprite and sprite.sprite_frames.has_animation("Fly"):
		sprite.play("Fly")


func _retreat_to_hover():
	var to_dest := _retreat_target - global_position
	var dist := to_dest.length()

	if dist < 30.0:
		flying_state = FlyingState.HOVERING
		current_state = State.CHASE
		return

	var speed := minf(fly_speed, dist * 4.0)
	velocity = velocity.lerp(to_dest.normalized() * speed, 0.15)

# DE-AGGRO — called from BaseEnemy signal when player leaves detection area

func _begin_return():
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


# Override so de-aggro from BaseEnemy does graceful returns
func _on_detection_area_exited(body: Node2D):
	if body == target:
		_begin_return()

# ATTACK — only damage during swoop
func attack_player(player: Node2D):
	if flying_state == FlyingState.SWOOPING:
		super.attack_player(player)
		_start_retreat()


# PHYSICS — no gravity
func _physics_process(delta: float):
	if current_state == State.DEAD:
		return

	if _hitstop_active:
		return

	if not _can_attack:
		_attack_cooldown_timer -= delta

		if _attack_cooldown_timer <= 0.0:
			_can_attack = true

	if current_state == State.KNOCKED_OUT:
		velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)

		if knockback_velocity.length() > 0:
			velocity = knockback_velocity
			knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10.0 * delta)
		move_and_slide()
		update_sprite_direction()
		return

	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10.0 * delta)

	else:
		update_ai(delta)

	move_and_slide()
	update_sprite_direction()
