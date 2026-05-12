extends Node2D

class_name CombatManager

# Slingshot system — hold M1 to charge, release to fire
# Short throw: >= 0.5s held | Long throw: >= 1.0s held | < 0.5s: fizzle (tweakable)

enum CombatState { IDLE, CHARGING, FIRING, STUNNED }

#Slingshot tuning
@export_group("Slingshot")
@export var short_throw_damage: float = 20.0 ## Damage for a short throw (0.5s–0.99s hold)
@export var long_throw_damage: float = 45.0 ## Damage for a long throw (1.0s+ hold)
@export var short_throw_threshold: float = 0.5
@export var long_throw_threshold: float = 1.0
@export var short_throw_speed: float = 600.0
@export var long_throw_speed: float = 950.0
@export var knockback_force: float = 280.0
@export var projectile_scene: PackedScene ## Packed scene for the projectile (RigidBody2D or Area2D with a script)

#References
@export_group("References")
@export var sprite: AnimatedSprite2D
@export var slingshot_indicator: Node2D #Optional lvisual indicator nodeshowing pull direction/power

#Internal state
var current_state: CombatState = CombatState.IDLE
var facing_direction: int = 1

var _charge_time: float = 0.0 # How long M1 has been held this charge
var _passed_first_threshold: bool = false ## becomes True once the button is held past the first threshold
var _is_charging: bool = false

signal shot_fired(damage, is_long_throw)
signal shot_fizzled()
signal state_changed(new_state)


#cycle
func _ready() -> void:
	if slingshot_indicator:
		slingshot_indicator.visible = false
	return

func _physics_process(delta: float) -> void:
	_handle_slingshot_input(delta)
	_update_indicator()
	return


func _handle_slingshot_input(delta: float) -> void:

	if current_state == CombatState.STUNNED:
		return

	# Begin charging
	if Input.is_action_just_pressed("attack") and current_state == CombatState.IDLE:
		_start_charge()
		return

	# While held — accumulate charge time
	if _is_charging and Input.is_action_pressed("attack"):
		_charge_time += delta
		
		if _charge_time >= short_throw_threshold and not _passed_first_threshold:
			_passed_first_threshold = true
			_on_first_threshold_reached()

	# Released projectile
	if _is_charging and Input.is_action_just_released("attack"):
		_release_slingshot()


func _start_charge() -> void:
	_is_charging = true
	_charge_time = 0.0
	_passed_first_threshold = false
	current_state = CombatState.CHARGING
	emit_signal("state_changed", current_state)

	if sprite and sprite.sprite_frames.has_animation("slingshot_charge"):
		sprite.play("slingshot_charge")
		pass

	if slingshot_indicator:
		slingshot_indicator.visible = true
		pass
	return


func _on_first_threshold_reached() -> void:
	# Optional: play a click sound / haptic / visual cue here
	if sprite and sprite.sprite_frames.has_animation("slingshot_ready"):
		sprite.play("slingshot_ready")
		pass


func _release_slingshot() -> void:
	_is_charging = false

	if _charge_time < short_throw_threshold:
		# Didn't hold long enough — fizzle
		_fizzle()
		return

	var is_long_throw := _charge_time >= long_throw_threshold
	_fire(is_long_throw)
	
	return


# FIZZLE (not enough charge/cancel draw)
func _fizzle() -> void:
	emit_signal("shot_fizzled")
	current_state = CombatState.IDLE
	emit_signal("state_changed", current_state)

	if slingshot_indicator:
		slingshot_indicator.visible = false
		pass

	if sprite and sprite.sprite_frames.has_animation("slingshot_fizzle"):
		sprite.play("slingshot_fizzle")
		pass

	elif sprite and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
		pass
	return


#Fire
func _fire(is_long_throw: bool) -> void:
	current_state = CombatState.FIRING
	emit_signal("state_changed", current_state)

	if slingshot_indicator:
		slingshot_indicator.visible = false

	var damage := long_throw_damage if is_long_throw else short_throw_damage
	var speed  := long_throw_speed  if is_long_throw else short_throw_speed

	# Aim toward mouse in world space
	var aim_dir := (get_global_mouse_position() - global_position).normalized()
	_spawn_projectile(aim_dir, speed, damage, is_long_throw)
	emit_signal("shot_fired", damage, is_long_throw)

	# Play fire animation then return to idle
	if sprite:
		var anim := "slingshot_fire_long" if is_long_throw else "slingshot_fire_short"
		if sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)
			await sprite.animation_finished
			pass

		elif sprite.sprite_frames.has_animation("slingshot_fire"):
			sprite.play("slingshot_fire")
			await sprite.animation_finished
			pass
		
	current_state = CombatState.IDLE
	emit_signal("state_changed", current_state)
	
	return


#Projectile
func _spawn_projectile(direction: Vector2, speed: float, damage: float, is_long: bool) -> void:
	if projectile_scene == null:
		push_warning("CombatManager: projectile_scene is not assigned!")
		return

	var proj = projectile_scene.instantiate()

	# Add to the world so it isn't parented to the player (avoids transform issues)
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position

	if proj.has_method("initialize"):
		proj.initialize(direction, speed, damage, is_long)
		pass

	else:
		if "direction" in proj:
			proj.direction = direction
			pass
			
		if "speed" in proj:
			proj.speed = speed
			pass
			
		if "damage" in proj:
			proj.damage = damage
			pass
			
		if "is_long_throw" in proj:
			proj.is_long_throw = is_long
			pass
			
		if proj is RigidBody2D:
			proj.linear_velocity = direction * speed
		pass
		
	return

# Indicator 
func _update_indicator() -> void:

	if not slingshot_indicator or not _is_charging:
		return

	var to_mouse := get_global_mouse_position() - global_position # Point indicator toward mouse and scale by charge progress
	slingshot_indicator.rotation = to_mouse.angle()

	var progress := clampf(_charge_time / long_throw_threshold, 0.0, 1.0) # Charge progress 0→1 clamped at long threshold
	slingshot_indicator.scale = Vector2(progress, progress)

	if slingshot_indicator is CanvasItem: # Tint indicator: grey → yellow (short) → red (long)
		if _charge_time >= long_throw_threshold:
			slingshot_indicator.modulate = Color(1.0, 0.3, 0.2)   # red — max power
			pass

		elif _charge_time >= short_throw_threshold:
			slingshot_indicator.modulate = Color(1.0, 0.9, 0.2)   # yellow — short throw ready
			pass

		else:
			slingshot_indicator.modulate = Color(0.8, 0.8, 0.8)   # grey — charging
			pass
		return

# queried by movement_refined.gd
func can_move() -> bool:
	# Player can still move while charging
	# Set to false if shooting needs to be stationary
	return current_state != CombatState.STUNNED


func is_in_combat() -> bool:
	return current_state != CombatState.IDLE


func set_facing_direction(direction: int) -> void:
	facing_direction = direction
	if sprite:
		sprite.flip_h = facing_direction < 0


func get_current_state() -> CombatState:
	return current_state
