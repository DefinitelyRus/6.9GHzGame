extends Node2D

class_name CombatManager

enum CombatState{IDLE, MELEE_ATTACK, PARRYING, RANGED_ATTACK, STUNNED}

#VARIABLES
@export_group("Melee")
@export var melee_damage: float = 25.0
@export var melee_range: float = 60.0
@export var melee_attack_duration: float = 0.4
@export var melee_knockback: float = 200.0

#@export var melee_combo_window: float = 0.5

@export_group("References")
@export var sprite: AnimatedSprite2D
@export var melee_hitbox: Area2D

#projectilebox
#parrybox

var current_state: CombatState = CombatState.IDLE
var facing_direction: int = 1

#init combo count
#bool sate parry active/ parry
#bool state ranged
#init ammo

##Timers
var attack_timer: float = 0.0

#combo, parry, ranged attack timers
#cooldown timers

#signals
signal attack_hit(target, damage)
signal state_changed(new_state)

func _ready():
   setup_hitboxes()
   return
     

func setup_hitboxes():
    if melee_hitbox:
        melee_hitbox.monitoring = false
        melee_hitbox.area_entered.connect(_on_melee_hit)
        pass
    return

    #connect projectile and parry hitboxes

func _physics_process(delta):
  
    update_timers(delta)
    handle_combat_input()
    update_combat_state(delta)
    return
    #ammo and other stat update if projectiles or parry are used


func update_timers(delta):
    if attack_timer > 0:
        attack_timer -= delta
        pass
    return


func update_combat_state(delta):
    match current_state:
        CombatState.MELEE_ATTACK:
            
            if attack_timer <= 0:
                current_state = CombatState.IDLE
                pass

                if melee_hitbox:
                    melee_hitbox.monitoring = false
                    pass

                emit_signal("state_changed", current_state)
                return


func handle_combat_input():
    if Input.is_action_just_pressed("melee_attack"):
        attempt_melee_attack()
        pass
    return


func update_facing_direction():
    var mouse_pos = get_global_mouse_position()

    if mouse_pos.x > global_position.x:
        facing_direction = 1
        pass

    elif mouse_pos.x < global_position.x:
        facing_direction = -1
        pass

    if sprite:
        sprite.flip_h = facing_direction < 0
        pass
    return


func attempt_melee_attack():
    if current_state in [CombatState.IDLE, CombatState.MELEE_ATTACK]:
        perform_melee_attack()
        pass
    return


func perform_melee_attack():
    current_state = CombatState.MELEE_ATTACK
    emit_signal("state_changed", current_state)
    attack_timer = melee_attack_duration

    if sprite:
        sprite.play("Melee")
        pass

    if melee_hitbox:
        melee_hitbox.monitoring = true
        melee_hitbox.position.x = abs(melee_hitbox.position.x) * facing_direction
        pass
    return

    # Hitbox will be disabled automatically after attack_timer expires in update_combat_state
func _on_melee_hit(area: Area2D):
     var target = area.get_parent() # Assuming the hitbox is a child of the target
    
     if target and target.has_method("take_damage"):
        var damage = melee_damage # Could be modified based on combos or other factors
        target.take_damage(damage)
        pass

        if target.has_method("apply_knockback"):
            var knockback_vector = Vector2(melee_knockback * facing_direction,-melee_knockback / 2)
            target.apply_knockback(knockback_vector)
            pass
        return
           
        emit_signal("attack_hit", target, damage)

           
# STATE MANAGEMENT
func can_move() -> bool:
    return current_state not in [CombatState.MELEE_ATTACK, CombatState.STUNNED]
    

func is_in_combat() -> bool:
    return current_state != CombatState.IDLE
    

func set_facing_direction(direction: int):
    facing_direction = direction
    
    if sprite:
        sprite.flip_h = facing_direction < 0    
        pass
    return
    

func get_current_state() -> CombatState:
    return current_state
