extends MarginContainer

@export_group("Main Screen")
@export var reality_ver: NinePatchRect
@export var vr_ver: NinePatchRect

@export var min_wait: int = 0
@export var max_wait: int = 9

@export var flash_duration: float = 1

# ---------- FLSH LOOP ----------
func start_flash_loop() -> void:
	while true:
		var wait_time = randf_range(min_wait, max_wait)
		await get_tree().create_timer(wait_time).timeout
		
		reality_ver.visible = false
		vr_ver.visible = true
		
		await get_tree().create_timer(flash_duration).timeout
		
		reality_ver.visible = true
		vr_ver.visible = false

# ---------- GODOT CALLBACKS ----------
func _ready() -> void:
	randomize()
	start_flash_loop()
	
	vr_ver.visible = false
