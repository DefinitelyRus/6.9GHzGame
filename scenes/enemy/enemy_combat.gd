class_name EnemyCombat
extends Node

# ---------- STATE ----------
enum CombatState { IDLE, CHARGING, FIRING, STUNNED }
var current_state: CombatState = CombatState.IDLE
var facing_direction: int = 1

# ---------- EXPORTS ----------
@export_group("Slingshot")
@export var short_throw_damage: float = 20.0
@export var long_throw_damage: float = 45.0
@export var short_throw_threshold: float = 0.5
@export var long_throw_threshold: float = 1.0
@export var short_throw_speed: float = 600.0
@export var long_throw_speed: float = 950.0
@export var knockback_force: float = 280.0
@export var projectile_scene: PackedScene

@export_group("References")
@export var sprite: AnimatedSprite2D
@export var slingshot_indicator: Node2D

# ---------- INTERNAL ----------
var _charge_time: float = 0.0
var _passed_first_threshold: bool = false
var _is_charging: bool = false

# ---------- SIGNALS ----------
signal state_changed(new_state)

# ---------- GODOT CALLBACKS ----------
func _ready() -> void:
	if slingshot_indicator:
		slingshot_indicator.visible = false
	return

func _physics_process(delta: float) -> void:
	_handle_slingshot_input(delta)
	_update_indicator()
	return

# ---------- SLINGSHOT LOGIC ----------
func _handle_slingshot_input(_delta: float) -> void:
	if current_state == CombatState.STUNNED:
		return
	if Input.is_action_just_pressed("attack") and current_state == CombatState.IDLE:
		_start_charge()
		return
	# ...existing code for charging/firing/fizzle...
	pass

func _start_charge() -> void:
	current_state = CombatState.CHARGING
	_charge_time = 0.0
	_passed_first_threshold = false
	_is_charging = true
	emit_signal("state_changed", current_state)
	if slingshot_indicator:
		slingshot_indicator.visible = true
	return

func _update_indicator() -> void:
	# Optional: update visual indicator for slingshot
	pass

# ---------- DEBUGGING ----------
@export_group("Debugging")
@export var log_ready: bool = false

func _log(msg: String) -> void:
	if log_ready:
		print("[EnemyCombat] %s" % msg)
	return
