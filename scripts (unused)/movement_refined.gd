extends CharacterBody2D

const accel = 1000.0
const JUMP_VELOCITY = -350.0
const friction = 400.0
const gravity = 1200

@export var SPEED = 130.0

var last_on_floor = false
var is_jumping = false
var facing_direction: int = 1


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer
#@onready var combat_manager: CombatManager = $CombatManager #something something
var combat_manager = null
var input_buffer: InputBuffer = null
@onready var camera: Camera2D = $Camera2D


func _ready():
	print("PLAYER READY")
	#if combat_manager:
		#combat_manager.combat_started.connect(_on_combat_started)
		#combat_manager.combat_ended.connect(_on_combat_ended)


func _physics_process(delta: float) -> void:
	# Add the gravity.

	print(is_on_floor())
	print(velocity)
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	var direction = Input.get_axis("move_left", "move_right")
		
	if combat_manager == null or combat_manager.can_move():
		
		if direction !=0:
			facing_direction = sign(direction)
		
		velocity.x = move_toward(velocity.x, direction * SPEED, accel * delta)
		
	else:
		velocity.x = move_toward(velocity.x, 0 , friction * delta)
		
	
	if input_buffer.consume("jump") and (is_on_floor() or not coyote_timer.is_stopped()):
		velocity.y = JUMP_VELOCITY
		camera.apply_shake(5.0)
		coyote_timer.stop()
		is_jumping = true
		
	if last_on_floor and not is_on_floor() and not is_jumping:
		coyote_timer.start()
		
	if is_on_floor():
		last_on_floor = true
		is_jumping = false
	else:
		last_on_floor = false
		
	
	if combat_manager:
		combat_manager.set_facing_direction(facing_direction)
		
	move_and_slide()
	
	if facing_direction > 0:
		animated_sprite.flip_h = false
	elif facing_direction < 0:
		animated_sprite.flip_h = true
		
		update_animation()
		
	
func update_animation():
		
		if combat_manager and combat_manager.is_in_combat():
			return
		
		if not is_on_floor():
			animated_sprite.play("Jump")
		elif abs(velocity.x) > 10:
			animated_sprite.play("Run")
		else:
			animated_sprite.play("Idle")
			
func _input(event):
	if Input.is_action_just_pressed("jump"):
		input_buffer.buffer_action("jump")
	
func get_facing_direction() -> int:
	return facing_direction
	
func _on_combat_started():
	print("combat started")
	
func _on_combat_ended():
	print("combat ended")
