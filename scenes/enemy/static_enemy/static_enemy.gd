extends Enemy


@export var health: float = 60.0
@export var critical_immunity_duration: float = 2.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _melee_zone: Area2D = $AttackArea

var _is_critical_immune: bool = false
var _player_in_melee_range: Node2D = null
var _attacking: bool = false


func _ready() -> void:
	super()

	if detection_area:
		detection_area.monitoring = false
		detection_area.monitorable = false
		pass

	if attack_area:
		if attack_area.body_entered.is_connected(_on_attack_area_entered_body):
			attack_area.body_entered.disconnect(_on_attack_area_entered_body)
		if attack_area.area_entered.is_connected(_on_attack_area_entered_area):
			attack_area.area_entered.disconnect(_on_attack_area_entered_area)
			pass

	if _melee_zone:
		_melee_zone.body_entered.connect(_on_melee_range_entered)
		_melee_zone.body_exited.connect(_on_melee_range_exited)
		pass

	else:
		push_warning("StaticEnemy: $MeleeDamageZone not found — check scene hierarchy")
		pass

	anim.play("Idle")
	return


func _physics_process(_delta: float) -> void:
	if current_state == State.DEAD:
		return

	velocity = Vector2.ZERO

	if _player_in_melee_range != null and _can_attack and not _attacking:
		_perform_attack()
		pass
	return


func _on_melee_range_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("Player"):
		_player_in_melee_range = body
		facing_direction = sign(body.global_position.x - global_position.x)
		update_sprite_direction()
		pass
	return


func _on_melee_range_exited(body: Node2D) -> void:
	if body == _player_in_melee_range:
		_player_in_melee_range = null
		pass
	return



func _perform_attack() -> void:
	if current_state == State.DEAD or _attacking:
		return

	_attacking = true
	_can_attack = false
	current_state = State.ATTACK
	anim.play("Attack")

	await get_tree().create_timer(0.2).timeout

	print("attack firing — target: ", _player_in_melee_range)  # add this

	if _player_in_melee_range and is_instance_valid(_player_in_melee_range):
		print("calling take_fatal_damage on ", _player_in_melee_range.name)  # add this
		if _player_in_melee_range.has_method("take_fatal_damage"):
			_player_in_melee_range.take_fatal_damage()
			pass

		elif _player_in_melee_range.has_method("take_damage"):
			_player_in_melee_range.take_damage(damage)
			pass
		

	await anim.animation_finished

	_attacking = false

	if current_state == State.DEAD:
		return

	current_state = State.IDLE
	anim.play("Idle")

	await get_tree().create_timer(attack_cooldown).timeout
	if current_state != State.DEAD:
		_can_attack = true
		pass
	return


func take_damage(amount: float, on_weakpoint: bool = false) -> void:
	if _is_critical_immune or current_state == State.DEAD:
		return
	health -= amount
	if health <= 0:
		_trigger_death()
		return
	_play_hurt()

	health -= amount

	if health <= 0:
		_trigger_death()
		return
	_play_hurt()

	return



func take_damage_from_area(amount: float, area: Area2D) -> void:
	if _is_critical_immune or current_state == State.DEAD:
		return
	if area == weakpoint_area:
		_is_critical_immune = true
		var crit := amount * 1.5
		health -= crit
		if health <= 0:
			_trigger_death()
			return
		_start_immunity_timer()
		_play_hurt()
		pass
	return


func _play_hurt() -> void:
	if current_state == State.DEAD or current_state == State.ATTACK:
		return
	# Only play Hurt animation if it actually exists — otherwise just flash.
	
	if anim.sprite_frames.has_animation("Hurt"):
		anim.play("Hurt")
		await anim.animation_finished
		if current_state != State.DEAD:
			anim.play("Idle")
			pass

	else:
		# No Hurt animation — do a quick white flash instead
		anim.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if current_state != State.DEAD:
			anim.modulate = Color.WHITE
			pass
		return


# DEATH
func _trigger_death() -> void:
	if current_state == State.DEAD:
		return

	current_state = State.DEAD
	emit_signal("died")
	_attacking = false
	_player_in_melee_range = null
	velocity = Vector2.ZERO

	call_deferred("set_collision_layer_value", 2, false)
	call_deferred("set_collision_mask_value", 1, false)
	call_deferred("set_collision_mask_value", 3, false)

	if _melee_zone:
		_melee_zone.monitoring = false
		_melee_zone.monitorable = false
		pass

	if anim.sprite_frames.has_animation("Death"):
		anim.play("Death")
		await anim.animation_finished
		pass

	else:
		# Fade out if no Death animation
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.4)
		await tween.finished
		pass
	
	queue_free()


#unused for this type of enemy
func apply_knockback(_force: Vector2) -> void:
	pass


func _start_immunity_timer() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.5, 0.1)
	await get_tree().create_timer(critical_immunity_duration).timeout
	if current_state != State.DEAD:
		_is_critical_immune = false
		modulate.a = 1.0
		pass
	return
