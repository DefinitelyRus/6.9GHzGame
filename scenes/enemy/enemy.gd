class_name Enemy
extends CharacterBody2D

# ---------- STATE ----------
enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }

# ---------- PROPERTIES ----------
var current_state: State = State.IDLE
var current_health: float
var target: Node2D = null
var is_stunned: bool = false
var is_knocked_out: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var facing_direction: int = 1

# ---------- EXPORTS ----------
@export_group("Stats")
@export var max_health: float = 100.0
@export var damage: float = 10.0
@export var knockback_resistance: float = 0.0

@export_group("Detection")
@export var detection_range: float = 200.0
@export var attack_range: float = 50.0
@export var lose_aggro_range: float = 400.0

@export_group("References")
@export var sprite: AnimatedSprite2D
@export var detection_area: Area2D
@export var attack_area: Area2D
@export var weakpoint_area: Area2D

@export_group("Combat Feel")
@export var hitstop_duration: float = 0.06
@export var hitstop_duration_weakpoint: float = 0.12
@export var weakpoint_particles_scene: PackedScene
@export var attack_cooldown: float = 1.0

# ---------- INTERNAL ----------
var _hitstop_active: bool = false

# ---------- SIGNALS ----------
signal health_changed(current_health: float, max_health: float)
signal damaged(amount: float)
signal state_changed(new_state: State)
signal player_detected(player: Node2D)
signal weakpoint_hit()
signal died()

# ---------- GODOT CALLBACKS ----------
func _ready() -> void:
	current_health = max_health
	_setup_detection()
	_initialize_enemy()

func _setup_detection() -> void:
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_entered)
	if weakpoint_area:
		weakpoint_area.body_entered.connect(_on_weakpoint_area_entered)

func _initialize_enemy() -> void:
	# To be overridden by subclasses for custom initialization
	pass

# ---------- AI & STATE ----------
func update_ai(_delta: float) -> void:
	# To be overridden by subclasses
	pass

func _on_detection_area_entered(body: Node2D) -> void:
	# Using groups is more robust and standard than checking node names.
	if body.is_in_group("Player"):
		target = body
		emit_signal("player_detected", body)
		if current_state == State.IDLE or current_state == State.PATROL:
			current_state = State.CHASE
			emit_signal("state_changed", current_state)

func _on_detection_area_exited(body: Node2D) -> void:
	if body == target:
		# Use distance_squared_to for performance; it avoids a square root calculation.
		var distance_sq: float = global_position.distance_squared_to(target.global_position)
		if distance_sq > (lose_aggro_range * lose_aggro_range):
			target = null
			current_state = State.IDLE
			emit_signal("state_changed", current_state)

func _on_attack_area_entered(body: Node2D) -> void:
	# Using groups is more robust and standard than checking node names.
	if body.is_in_group("Player") and body.has_method("take_damage"):
		attack_player(body)

func _on_weakpoint_area_entered(body: Node2D) -> void:
	# Ensure the body has a 'damage' property before accessing it to prevent errors.
	if body.is_in_group("PlayerProjectile") and "damage" in body:
		take_damage(body.damage, true)
		emit_signal("weakpoint_hit")

# ---------- COMBAT ----------
func take_damage(amount: float, is_weakpoint: bool = false) -> void:
	if current_state == State.DEAD:
		return

	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health, max_health)
	emit_signal("damaged", amount)

	flash_sprite()
	
	if current_health <= 0:
		die()
	else:
		enter_hurt_state()

	if is_weakpoint:
		_hitstop(hitstop_duration_weakpoint)
	else:
		_hitstop(hitstop_duration)

func _hitstop(duration: float) -> void:
	if _hitstop_active:
		return
	_hitstop_active = true
	await get_tree().create_timer(duration).timeout
	_hitstop_active = false

func apply_knockback(force: Vector2) -> void:
	knockback_velocity += force * (1 - knockback_resistance)

func stun(duration: float) -> void:
	is_stunned = true
	if sprite:
		sprite.modulate = Color.YELLOW
	await get_tree().create_timer(duration).timeout
	is_stunned = false
	if sprite and current_state != State.DEAD:
		sprite.modulate = Color.WHITE

func flash_sprite() -> void:
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if sprite and current_state != State.DEAD:
			sprite.modulate = Color.WHITE

func enter_hurt_state() -> void:
	var previous_state = current_state
	current_state = State.HURT
	emit_signal("state_changed", current_state)
	await get_tree().create_timer(0.5).timeout
	if current_state == State.HURT:
		current_state = previous_state

func die() -> void:
	current_state = State.DEAD
	emit_signal("died")
	emit_signal("state_changed", current_state)
	if sprite:
		sprite.play("death")
	set_collision_layer_value(2, false)
	set_collision_mask_value(3, false)
	await get_tree().create_timer(2.0).timeout
	queue_free()

# ---------- UTILITY ----------
func attack_player(player: Node2D) -> void:
	if player.has_method("take_damage"):
		player.take_damage(damage)

func update_sprite_direction() -> void:
	if sprite and facing_direction != 0:
		sprite.flip_h = facing_direction < 0

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
