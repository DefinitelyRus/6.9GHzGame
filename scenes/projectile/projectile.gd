class_name Projectile
extends RigidBody2D

# ---------- PROPERTIES ----------
var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var damage: float = 20.0
var is_long_throw: bool = false

# ---------- INTERNAL STATE ----------
var _lifetime_timer: float = 0.0
var _lifetime_max: float = 5.0
var _has_hit: bool = false

# ---------- REFERENCES ----------
@export_group("References")
@export var sprite: AnimatedSprite2D
@export var hitbox_area: Area2D

# ---------- SIGNALS ----------
signal hit_enemy(enemy: Enemy, hit_position: Vector2)
signal hit_platform(platform_position: Vector2)
signal despawned()

# ---------- GODOT CALLBACKS ----------
func _ready() -> void:
	# Set initial velocity based on direction and speed
	if linear_velocity == Vector2.ZERO:
		linear_velocity = direction * speed
	
	# Connect collision signals
	if hitbox_area:
		hitbox_area.area_entered.connect(_on_hitbox_area_entered)
	
	# Connect to body_entered for TileMapLayer collisions
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_lifetime_timer += delta
	
	# Despawn if lifetime exceeded
	if _lifetime_timer >= _lifetime_max:
		_despawn_quiet()


# ---------- INITIALIZATION ----------
func initialize(p_direction: Vector2, p_speed: float, p_damage: float, p_is_long: bool) -> void:
	direction = p_direction.normalized()
	speed = p_speed
	damage = p_damage
	is_long_throw = p_is_long
	
	# Set initial velocity
	linear_velocity = direction * speed


# ---------- COLLISION HANDLING ----------
func _on_hitbox_area_entered(area: Area2D) -> void:
	if _has_hit:
		return
	
	# Check if it's an enemy
	var parent = area.get_parent()
	if parent is Enemy:
		_hit_enemy(parent, area.global_position)
		return
	
	# Check if it's a weakpoint on an enemy
	if parent and parent.has_method("take_damage") and parent is Enemy:
		_hit_enemy(parent, area.global_position)
		return


func _on_body_entered(body: Node2D) -> void:
	if _has_hit:
		return
	
	# Check if it's a TileMapLayer (platform)
	if body is TileMapLayer:
		_hit_platform(global_position)


# ---------- HIT RESPONSES ----------
func _hit_enemy(enemy: Enemy, hit_position: Vector2) -> void:
	if _has_hit:
		return
	
	_has_hit = true
	
	# Determine hit type based on collision area
	var is_weakpoint: bool = false
	if enemy.weakpoint_area:
		# Could expand this logic to check which area was hit
		pass
	
	# Apply damage to enemy
	enemy.take_damage(damage, is_weakpoint)
	
	# Apply knockback
	var knockback_dir = (enemy.global_position - global_position).normalized()
	enemy.apply_knockback(knockback_dir * damage)
	
	emit_signal("hit_enemy", enemy, hit_position)
	_despawn_quiet()


func _hit_platform(hit_position: Vector2) -> void:
	if _has_hit:
		return
	
	_has_hit = true
	
	emit_signal("hit_platform", hit_position)
	
	# TODO: Play sound effect on platform hit
	
	_despawn_on_impact()


# ---------- DESPAWN LOGIC ----------
func _despawn_on_impact() -> void:
	# Despawn immediately after hitting something
	emit_signal("despawned")
	queue_free()


func _despawn_quiet() -> void:
	# Despawn quietly after timeout
	emit_signal("despawned")
	queue_free()

