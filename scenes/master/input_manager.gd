## A globally accessible singleton that reads and interprets player input.
## It converts raw inputs into usable data like move_vector, is_jumping, etc.
## This class does not pass data itself; instead, other classes pull data from here.
class_name InputManager
extends Node

# ---------- COMPONENTS ----------
static var instance: InputManager

# ---------- DEBUGGING ----------
@export_group("Debugging")
@export var log_ready: bool = true
@export var log_process: bool = false
@export var log_input: bool = false

# ---------- STATE ----------
static var allow_override: bool = true
var _exit_hold_timer: float = 0.0

static var buffered_actions: Dictionary = {}
static var default_buffer_time: float = 0.2

# ---------- CONSTANTS ----------
const MOVE_LEFT: String = "move_left"
const MOVE_RIGHT: String = "move_right"
const MOVE_UP: String = "move_up"
const MOVE_DOWN: String = "move_down"
const JUMP: String = "jump"
const DASH: String = "dash"
const ATTACK: String = "attack"
const INTERACT: String = "interact"
const CANCEL: String = "cancel"
const PAUSE: String = "pause"

# ---------- INPUT DATA ----------
static var move_vector: Vector2 = Vector2.ZERO
static var is_jumping: bool = false
static var is_dashing: bool = false
static var is_attacking: bool = false
static var is_interacting: bool = false

# ---------- GODOT CALLBACKS ----------
func _enter_tree() -> void:
	if instance != null:
		Log.err("Multiple instances of InputManager detected.")
		queue_free()
		return

	instance = self
	return


func _ready() -> void:
	Log.me("InputManager is ready.", log_ready)
	return


func _process(delta: float) -> void:
	Log.me("InputManager is processing.", log_process)
		
	_handle_system_inputs(delta)
	_update_gameplay_inputs()
	_process_buffered_actions(delta)
	return


func _input(event: InputEvent) -> void:
	Log.me("Input event received: %s" % [str(event)], log_input)
	return

# ---------- INPUT HANDLING ----------

## Handles system-level inputs such as holding the CANCEL action to quit the game.
func _handle_system_inputs(delta: float) -> void:
	if Input.is_action_just_released(CANCEL): _exit_hold_timer = 0.0
		
	if Input.is_action_pressed(CANCEL):
		_exit_hold_timer += delta
		
		if _exit_hold_timer >= 2.0:
			var tree: SceneTree = get_tree()
			tree.quit()
			pass
		pass
	return


## Reads all gameplay-related actions (movement, jumping, dashing, attacking, etc.) 
## and updates the static variables for other classes to pull from.
func _update_gameplay_inputs() -> void:
	if not allow_override:
		move_vector = Vector2.ZERO
		is_jumping = false
		is_dashing = false
		is_attacking = false
		is_interacting = false
		return
	
	var left: float = Input.get_action_strength(MOVE_LEFT)
	var right: float = Input.get_action_strength(MOVE_RIGHT)
	var up: float = Input.get_action_strength(MOVE_UP)
	var down: float = Input.get_action_strength(MOVE_DOWN)
	
	var x_axis: float = right - left
	var y_axis: float = down - up
	
	move_vector = Vector2(x_axis, y_axis)
	
	is_jumping = Input.is_action_just_pressed(JUMP)
	if is_jumping: buffer_action(JUMP)
		
	is_dashing = Input.is_action_just_pressed(DASH)
	if is_dashing: buffer_action(DASH)
		
	is_attacking = Input.is_action_just_pressed(ATTACK)
	if is_attacking: buffer_action(ATTACK)
		
	is_interacting = Input.is_action_just_pressed(INTERACT)
	if is_interacting: buffer_action(INTERACT)
		
	return

# ---------- BUFFERING LOGIC ----------

func _process_buffered_actions(delta: float) -> void:
	for action: String in buffered_actions.keys().duplicate():
		var time_left: float = buffered_actions[action]
		time_left -= delta
		
		if time_left <= 0.0:
			buffered_actions.erase(action)
			pass

		else:
			buffered_actions[action] = time_left
			pass
		pass
	return


static func buffer_action(action: String, duration: float = -1.0) -> void:
	var final_duration: float = duration
	if final_duration < 0.0: final_duration = default_buffer_time
		
	buffered_actions[action] = final_duration
	return


static func is_buffered(action: String) -> bool:
	return buffered_actions.has(action)


static func consume_action(action: String) -> bool:
	if buffered_actions.has(action):
		buffered_actions.erase(action)
		return true
	return false
