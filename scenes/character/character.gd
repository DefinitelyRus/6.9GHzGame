class_name Character
extends CharacterBody2D

# ---------- COMPONENTS ----------
var current_level: Level # Set by the level itself

@export_group("Movement")
@export var speed: float = 130.0
@export var acceleration: float = 1000.0
@export var jump_velocity: float = -350.0
@export var friction: float = 400.0
@export var gravity: float = 1200.0

var was_on_floor: bool = false
var is_jumping: bool = false
var facing_direction: int = 1

var move_direction: float = 0.0
var jump_intent: bool = false

@onready var coyote_timer: Timer = $CoyoteTimer
@onready var combat_handler: Node = get_node_or_null("CharacterCombat")
var camera: CameraManager = CameraManager.instance

# ---------- GODOT CALLBACKS ----------
func _ready() -> void:
	Log.me("Readying character %s. Scanning children and properties..." % name)

	if coyote_timer == null:
		Log.warn("coyote_timer is missing from children; coyote jump won't work.", true, false)
		pass

	if combat_handler == null:
		Log.warn("combat_handler is missing from children; combat won't work.", true, false)
		pass

	if camera == null:
		Log.warn("camera is missing; screen shake won't work.", true, false)
		pass

	Log.me("Done!", true, false)
	return


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_move_horizontal(delta)
	_handle_jump()
	_update_floor_state()
	_update_combat_direction()
	move_and_slide()
	return


# ---------- PURPOSE-SPECIFIC METHODS ----------
func _apply_gravity(delta: float) -> void:
	if not is_on_floor(): velocity += get_gravity() * delta
	return


func _move_horizontal(delta: float) -> void:
	var can_move: bool = true
	if combat_handler != null:
		if combat_handler.has_method("can_move"):
			can_move = combat_handler.can_move()
			pass
		pass

	if can_move:
		if move_direction != 0.0: facing_direction = sign(move_direction)
		
		var target_speed: float = move_direction * speed
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
		pass

	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		pass
	return


func _handle_jump() -> void:
	var can_coyote_jump: bool = is_on_floor()
	if coyote_timer != null:
		can_coyote_jump = can_coyote_jump or not coyote_timer.is_stopped()
		pass

	if jump_intent and can_coyote_jump:
		velocity.y = jump_velocity
		
		if camera != null: camera.shake(5.0)
			
		if coyote_timer != null: coyote_timer.stop()
			
		is_jumping = true
		pass
	return


func _update_floor_state() -> void:
	if was_on_floor and not is_on_floor() and not is_jumping:
		if coyote_timer != null: coyote_timer.start()
		pass

	if is_on_floor():
		was_on_floor = true
		is_jumping = false
		pass

	else:
		was_on_floor = false
		pass
	return


func _update_combat_direction() -> void:
	if combat_handler != null:
		if combat_handler.has_method("set_facing_direction"):
			combat_handler.set_facing_direction(facing_direction)
			pass
		pass
	return
