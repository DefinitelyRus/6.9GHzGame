# SFX Integration Summary
This document outlines all the SFX calls that have been integrated throughout the game code using the `AudioManager` system.

All sound effects are routed through `AudioManager.stream_audio("sfx_name", channel)`. Yall can assign audio files to these SFX names in the `AudioManager.sfx_library` dictionary.


## Player Sounds
### character.gd
- **`player_jump`** - Played when the player jumps
  - Location: `_handle_jump()` method
  - Channel: SFX
  
- **`player_land`** - Played when the player lands on the ground
  - Location: `_update_floor_state()` method
  - Channel: SFX


## Combat Sounds
### character_combat.gd
- **`combat_start`** - Played when combat begins
  - Location: `start_combat()` method
  - Channel: SFX

- **`combat_end`** - Played when combat ends
  - Location: `end_combat()` method
  - Channel: SFX


## Enemy Base Sounds
### enemy.gd
- **`enemy_hit`** - Played when an enemy takes damage (non-weakpoint)
  - Location: `take_damage()` method
  - Channel: SFX

- **`enemy_weakpoint_hit`** - Played when an enemy's weakpoint is hit
  - Location: `take_damage()` method (when `is_weakpoint == true`)
  - Channel: SFX

- **`enemy_hurt`** - Played when an enemy enters the hurt state
  - Location: `enter_hurt_state()` method
  - Channel: SFX

- **`enemy_knockout`** - Played when an enemy is knocked out
  - Location: `_enter_knockout()` method
  - Channel: SFX

- **`enemy_death`** - Played when an enemy dies
  - Location: `die()` method
  - Channel: SFX

- **`enemy_attack`** - Played when an enemy attacks the player
  - Location: `attack_player()` method
  - Channel: SFX


## Flying Enemy Sounds
### flying_enemy.gd
- **`flying_enemy_swoop`** - Played when a flying enemy initiates a swoop attack
  - Location: `_initiate_swoop()` method
  - Channel: SFX


## Platform Enemy Sounds
### platform_enemy.gd
- **`enemy_footstep`** - Played while patrolling between waypoints
  - Location: `patrol_between_points()` method
  - Channel: SFX

- **`enemy_chase`** - Played while chasing the player
  - Location: `chase_behavior()` method
  - Channel: SFX

- **`enemy_turn`** - Played when the enemy turns around at a patrol boundary
  - Location: `turn_around()` method
  - Channel: SFX


## Static Enemy Sounds
### static_enemy.gd
- **`static_enemy_attack`** - Played when a static enemy performs a melee attack
  - Location: `_perform_attack()` method
  - Channel: SFX

- **`static_enemy_hurt`** - Played when a static enemy is hurt
  - Location: `_play_hurt()` method
  - Channel: SFX

- **`static_enemy_death`** - Played when a static enemy dies
  - Location: `_trigger_death()` method
  - Channel: SFX


## Projectile Sounds
### projectile.gd
- **`projectile_hit_enemy`** - Played when a projectile hits an enemy
  - Location: `_hit_enemy()` method
  - Channel: SFX

- **`projectile_impact`** - Played when a projectile hits a platform
  - Location: `_hit_platform()` method
  - Channel: SFX


## Level/Domain Sounds
### level.gd
- **`domain_switch_to_vr`** - Played when switching to VR domain
  - Location: `set_domain_view()` method (when `use_vr_domain == true`)
  - Channel: MUSIC
  - Note: Fades out all previous audio with `AudioManager.fade_out_audio()`

- **`domain_switch_to_irl`** - Played when switching to IRL domain
  - Location: `set_domain_view()` method (when `use_vr_domain == false`)
  - Channel: MUSIC
  - Note: Fades out all previous audio with `AudioManager.fade_out_audio()`
