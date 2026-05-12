class_name FlyingEnemy
extends Enemy

# ---------- EXPORTS ----------
@export_group("Flying Behaviors")
@export var fly_speed: float = 80.0
@export var return_speed: float = 60.0
@export var swoop_speed: float = 250.0
@export var hover_height: float = 80.0
@export var hover_amplitude: float = 10.0
@export var hover_frequency: float = 1.5
@export var swoop_cooldown: float = 2.0
@export var swoop_distance: float = 200.0
@export var hover_side_offset: float = 60.0

# ---------- STATE ----------
var hover_origin: Vector2
var hover_time: float = 0.0
var can_swoop: bool = true
var swoop_cooldown_timer: float = 0.0

# ---------- GODOT CALLBACKS ----------
func initialize_enemy() -> void:
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
	if current_state == _get_return_state():
		_return_home(_delta)
	return

# ---------- FLYING BEHAVIOR ----------
func _get_return_state() -> int:
	return State.IDLE

func _idle_hover(_delta: float) -> void:
	# Gentle bob at spawn
	pass

func _chase_behavior() -> void:
	# Implement chase logic
	pass

func _swoop_towards_target() -> void:
	# Implement swoop logic
	pass

func _return_home(_delta: float) -> void:
	# Return to hover_origin
	pass
