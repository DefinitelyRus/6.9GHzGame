class_name SlingshotCombat
extends CharacterCombat

# ---------- CONSTANTS ----------
enum CombatState { IDLE, CHARGING, FIRING, STUNNED }

# ---------- COMPONENTS ----------
@export_group("References")
@export var sprite: AnimatedSprite2D
@export var slingshot_indicator: Node2D
@export var projectile_scene: PackedScene

# ---------- CONFIGURATION ----------
@export_group("Slingshot")
@export var short_throw_damage: float = 20.0
@export var long_throw_damage: float = 45.0
@export var short_throw_threshold: float = 0.5
@export var long_throw_threshold: float = 1.0
@export var short_throw_speed: float = 600.0
@export var long_throw_speed: float = 950.0
@export var knockback_force: float = 280.0

# ---------- STATE ----------
var current_state: CombatState = CombatState.IDLE

var _charge_time: float = 0.0
var _passed_first_threshold: bool = false
var _is_charging: bool = false

# ---------- SIGNALS ----------
signal shot_fired(damage: float, is_long_throw: bool)
signal shot_fizzled()
signal state_changed(new_state: int)

# ---------- GODOT CALLBACKS ----------
func _ready() -> void:
	Log.me("Readying slingshot combat %s. Scanning properties..." % name, log_ready)
	super._ready()

	if slingshot_indicator != null:
		slingshot_indicator.visible = false
		pass
		
	if projectile_scene == null:
		Log.warn("projectile_scene is not assigned!", true, false)
		pass

	if sprite == null:
		Log.warn("sprite is not assigned!", true, false)
		pass

	Log.me("Done!", log_ready)
	return


func _physics_process(delta: float) -> void:
	_handle_slingshot_input(delta)
	_update_indicator()
	return

# ---------- INPUT HANDLING ----------
func _handle_slingshot_input(delta: float) -> void:
	if current_state == CombatState.STUNNED:
		return

	if InputManager.is_buffered(InputManager.ATTACK) and current_state == CombatState.IDLE:
		InputManager.consume_action(InputManager.ATTACK)
		_start_charge()
		return

	if _is_charging and Input.is_action_pressed(InputManager.ATTACK):
		_charge_time += delta
		
		if _charge_time >= short_throw_threshold and not _passed_first_threshold:
			_passed_first_threshold = true
			_on_first_threshold_reached()
			pass
		pass

	if _is_charging and Input.is_action_just_released(InputManager.ATTACK):
		_release_slingshot()
		pass
		
	return

# ---------- PURPOSE-SPECIFIC METHODS ----------
func _start_charge() -> void:
	_is_charging = true
	_charge_time = 0.0
	_passed_first_threshold = false
	current_state = CombatState.CHARGING
	state_changed.emit(current_state)

	if sprite != null:
		if sprite.sprite_frames.has_animation("slingshot_charge"):
			sprite.play("slingshot_charge")
			pass
		pass

	if slingshot_indicator != null:
		slingshot_indicator.visible = true
		pass
		
	return


func _on_first_threshold_reached() -> void:
	if sprite != null:
		if sprite.sprite_frames.has_animation("slingshot_ready"):
			sprite.play("slingshot_ready")
			pass
		pass
	return


func _release_slingshot() -> void:
	_is_charging = false

	if _charge_time < short_throw_threshold:
		_fizzle()
		return

	var is_long_throw: bool = _charge_time >= long_throw_threshold
	_fire(is_long_throw)
	return


func _fizzle() -> void:
	shot_fizzled.emit()
	current_state = CombatState.IDLE
	state_changed.emit(current_state)

	if slingshot_indicator != null:
		slingshot_indicator.visible = false
		pass

	if sprite != null:
		if sprite.sprite_frames.has_animation("slingshot_fizzle"):
			sprite.play("slingshot_fizzle")
			pass
		elif sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
			pass
		pass
		
	return


func _fire(is_long_throw: bool) -> void:
	current_state = CombatState.FIRING
	state_changed.emit(current_state)

	if slingshot_indicator != null:
		slingshot_indicator.visible = false
		pass

	var damage: float = short_throw_damage
	var speed: float = short_throw_speed
	
	if is_long_throw:
		damage = long_throw_damage
		speed = long_throw_speed
		pass

	var mouse_pos: Vector2 = get_global_mouse_position()
	var pos_diff: Vector2 = mouse_pos - global_position
	var aim_dir: Vector2 = pos_diff.normalized()
	
	_spawn_projectile(aim_dir, speed, damage, is_long_throw)
	shot_fired.emit(damage, is_long_throw)

	if sprite != null:
		var anim: String = "slingshot_fire_short"
		if is_long_throw:
			anim = "slingshot_fire_long"
			pass
			
		if sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)
			await sprite.animation_finished
			pass
		elif sprite.sprite_frames.has_animation("slingshot_fire"):
			sprite.play("slingshot_fire")
			await sprite.animation_finished
			pass
		pass
		
	current_state = CombatState.IDLE
	state_changed.emit(current_state)
	return


func _spawn_projectile(direction: Vector2, speed: float, damage: float, is_long: bool) -> void:
	if projectile_scene == null:
		return

	var proj: Node = projectile_scene.instantiate()
	var tree: SceneTree = get_tree()
	var current_scene: Node = tree.current_scene
	
	current_scene.add_child(proj)
	
	if proj is Node2D:
		proj.global_position = global_position
		pass

	if proj.has_method("initialize"):
		proj.initialize(direction, speed, damage, is_long)
		pass
	else:
		if "direction" in proj:
			proj.set("direction", direction)
			pass
			
		if "speed" in proj:
			proj.set("speed", speed)
			pass
			
		if "damage" in proj:
			proj.set("damage", damage)
			pass
			
		if "is_long_throw" in proj:
			proj.set("is_long_throw", is_long)
			pass
			
		if proj is RigidBody2D:
			var proj_vel: Vector2 = direction * speed
			proj.linear_velocity = proj_vel
			pass
		pass
		
	return


func _update_indicator() -> void:
	if slingshot_indicator == null or not _is_charging:
		return

	var mouse_pos: Vector2 = get_global_mouse_position()
	var to_mouse: Vector2 = mouse_pos - global_position
	slingshot_indicator.rotation = to_mouse.angle()

	var charge_ratio: float = _charge_time / long_throw_threshold
	var progress: float = clampf(charge_ratio, 0.0, 1.0)
	slingshot_indicator.scale = Vector2(progress, progress)

	if slingshot_indicator is CanvasItem:
		if _charge_time >= long_throw_threshold:
			slingshot_indicator.modulate = Color(1.0, 0.3, 0.2)
			pass
		elif _charge_time >= short_throw_threshold:
			slingshot_indicator.modulate = Color(1.0, 0.9, 0.2)
			pass
		else:
			slingshot_indicator.modulate = Color(0.8, 0.8, 0.8)
			pass
		pass
		
	return


func can_move() -> bool:
	return current_state != CombatState.STUNNED


func is_in_combat() -> bool:
	return current_state != CombatState.IDLE


func set_facing_direction(direction: int) -> void:
	facing_direction = direction
	if sprite != null:
		sprite.flip_h = facing_direction < 0
		pass
	return


func get_current_state() -> CombatState:
	return current_state
