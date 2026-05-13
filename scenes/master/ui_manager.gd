class_name UIManager
extends CanvasLayer

# ---------- COMPONENTS ----------
static var instance: UIManager = null

# ---------- NODES ----------
@export var hud_node: MarginContainer = null
@export var popup_node: Control = null
@export var help_node: Control = null
@export var transition_node: TextureRect = null
@export var on_screen_text_node: Control = null
@export var main_menu_node: Control = null
@export var fade_overlay_node: TextureRect = null
@export var white_fade_overlay_node: TextureRect = null


# ---------- GODOT CALLBACKS ----------
func _enter_tree() -> void:
	if instance != null:
		Log.err("Existing instance of UIManager detected.")
		queue_free()
		return
		
	instance = self
	
	if hud_node == null:
		Log.err("hud_node is null in UIManager. Please assign it in the inspector.")
		pass
	
	if popup_node == null:
		Log.err("popup_node is null in UIManager. Please assign it in the inspector.")
		pass
	
	if help_node == null:
		Log.err("help_node is null in UIManager. Please assign it in the inspector.")
		pass
	
	if transition_node == null:
		Log.err("transition_node is null in UIManager. Please assign it in the inspector.")
		pass
	
	if fade_overlay_node == null:
		Log.err("fade_overlay_node is null in UIManager. Please assign it in the inspector.")
		pass
	
	if white_fade_overlay_node == null:
		Log.err("white_fade_overlay_node is null in UIManager. Please assign it in the inspector.")
		pass
	
	if main_menu_node == null:
		Log.err("main_menu_node is null in UIManager. Please assign it in the inspector.")
		pass
	return


func _ready() -> void:
	pass


# ---------- UI CONTROL ----------

## Enables or disables the visibility of the UI Manager itself.
static func enable_ui(enable: bool) -> void:
	if instance != null:
		instance.visible = enable
		pass
	return


# ----- POPUP -----

## Sets the visibility of the popup node.
static func set_popup_visible(enable: bool) -> void:
	if instance != null and instance.popup_node != null:
		instance.popup_node.visible = enable
		pass
	return


## Sets the text of the popup node with a header and message.
static func set_popup_text(header: String, message: String) -> void:
	if instance != null and instance.popup_node != null:
		instance.popup_node.set_text(header, message)
		pass
	return


## Enables or disables a specific button on the popup node.
static func set_button_enabled(row: int, index: int, is_enabled: bool) -> void:
	if instance != null and instance.popup_node != null:
		instance.popup_node.set_btn(is_enabled, row, index)
		pass
	return


## Sets the text of a specific button on the popup node.
static func set_button_text(row: int, index: int, text: String) -> void:
	if instance != null and instance.popup_node != null:
		instance.popup_node.set_btn_text(text, row, index)
		pass
	return


static var _help_visible: bool = false

## Toggles the visibility of the help node and pauses the game if it is shown.
static func toggle_help() -> void:
	Log.me("Setting help visibility to %s." % [str(not _help_visible)])
	
	if _help_visible:
		_help_visible = false
		Master.is_paused = false
		
		if instance != null:
			if instance.help_node != null:
				instance.help_node.visible = false
				pass
			
			end_transition()
			
			if SceneLoader.instance.loaded_scene == null:
				if instance.main_menu_node != null:
					instance.main_menu_node.visible = true
					pass
				pass
			else:
				if instance.hud_node != null:
					instance.hud_node.visible = true
					pass
				pass
			pass
		pass
	
	else:
		Master.is_paused = true
		start_transition()
		
		if instance != null:
			if SceneLoader.loaded_scene == null:
				if instance.main_menu_node != null:
					instance.main_menu_node.visible = false
					pass
				pass
				
			else:
				if instance.hud_node != null:
					instance.hud_node.visible = false
					pass
				pass
			
			await instance.get_tree().create_timer(1.0).timeout
			
			if instance.help_node != null:
				instance.help_node.visible = true
				pass
			pass
		
		_help_visible = true
		pass
	
	return


# ----- HUD -----

## Sets the visibility of the HUD node or specific segments of it.
static func set_hud_visible(enable: bool, segment: int = 0) -> void:
	if instance != null and instance.hud_node != null:
		if segment == -1:
			instance.hud_node.visible = enable
			instance.hud_node.set_visibility(enable, 0)
			instance.hud_node.set_visibility(enable, 1)
			instance.hud_node.set_visibility(enable, 2)
			return
		
		instance.hud_node.set_visibility(enable, segment)
		pass
	return


## Sets the health values on the HUD node.
static func set_health(health: float, max_health: float) -> void:
	if instance != null and instance.hud_node != null:
		instance.hud_node.update_health(health, max_health)
		pass
	return


## Sets the color of the health bar on the HUD node.
static func set_health_color(color: Color) -> void:
	if instance != null and instance.hud_node != null:
		instance.hud_node.set_health_color(color)
		pass
	return


## Sets the timer visibility on the on-screen text node.
static func set_timer_enabled(is_enabled: bool) -> void:
	if instance != null and instance.on_screen_text_node != null:
		instance.on_screen_text_node.set_timer_enabled(is_enabled)
		pass
	return


## Sets the timer text on the on-screen text node from a string.
static func set_timer_text(text: String) -> void:
	if instance != null and instance.on_screen_text_node != null:
		instance.on_screen_text_node.set_timer_text(text)
		pass
	return


## Sets the timer text on the on-screen text node from a given time in seconds.
static func set_timer_text_from_time(time: float) -> void:
	var minutes: int = int(time / 60.0)
	var seconds: int = int(fmod(time, 60.0))
	var text: String = "%02d:%02d" % [minutes, seconds]
	
	if instance != null and instance.on_screen_text_node != null:
		instance.on_screen_text_node.set_timer_text(text)
		pass
	return


## Sets the timer color on the on-screen text node.
static func set_timer_color(color: Color) -> void:
	if instance != null and instance.on_screen_text_node != null:
		instance.on_screen_text_node.set_timer_color(color)
		pass
	return


# ----- TRANSITION -----

## Starts the transition animation, optionally with text.
static func start_transition(text: String = "") -> void:
	if instance != null and instance.transition_node != null:
		instance.transition_node.start_transition(text)
		pass
	return


## Ends the current transition animation.
static func end_transition() -> void:
	if instance != null and instance.transition_node != null:
		instance.transition_node.end_transition()
		pass
	return


## Resets the transition node to its default state.
static func reset_transition() -> void:
	if instance != null and instance.transition_node != null:
		instance.transition_node.reset()
		pass
	return


# ----- FADE OVERLAYS -----

## Fades in the black overlay (opacity from 0 to 1) over the specified duration.
static func fade_in_black(duration: float = 0.5) -> void:
	if instance != null and instance.fade_overlay_node != null:
		var tween: Tween = instance.create_tween()
		var modulate: Color = instance.fade_overlay_node.modulate
		modulate.a = 0.0
		instance.fade_overlay_node.modulate = modulate
		tween.tween_property(instance.fade_overlay_node, "modulate:a", 1.0, duration)
	return


## Fades out the black overlay (opacity from 1 to 0) over the specified duration.
static func fade_out_black(duration: float = 0.5) -> void:
	if instance != null and instance.fade_overlay_node != null:
		var tween: Tween = instance.create_tween()
		tween.tween_property(instance.fade_overlay_node, "modulate:a", 0.0, duration)
	return


## Sets the black overlay to fully opaque instantly.
static func set_black_overlay_opaque() -> void:
	if instance != null and instance.fade_overlay_node != null:
		var modulate: Color = instance.fade_overlay_node.modulate
		modulate.a = 1.0
		instance.fade_overlay_node.modulate = modulate
	return


## Sets the black overlay to fully transparent instantly.
static func set_black_overlay_transparent() -> void:
	if instance != null and instance.fade_overlay_node != null:
		var modulate: Color = instance.fade_overlay_node.modulate
		modulate.a = 0.0
		instance.fade_overlay_node.modulate = modulate
	return


## Fades in the white overlay (opacity from 0 to 1) over the specified duration.
static func fade_in_white(duration: float = 0.5) -> void:
	if instance != null and instance.white_fade_overlay_node != null:
		var tween: Tween = instance.create_tween()
		var modulate: Color = instance.white_fade_overlay_node.modulate
		modulate.a = 0.0
		instance.white_fade_overlay_node.modulate = modulate
		tween.tween_property(instance.white_fade_overlay_node, "modulate:a", 1.0, duration)
	return


## Fades out the white overlay (opacity from 1 to 0) over the specified duration.
static func fade_out_white(duration: float = 0.5) -> void:
	if instance != null and instance.white_fade_overlay_node != null:
		var tween: Tween = instance.create_tween()
		tween.tween_property(instance.white_fade_overlay_node, "modulate:a", 0.0, duration)
	return


## Sets the white overlay to fully opaque instantly.
static func set_white_overlay_opaque() -> void:
	if instance != null and instance.white_fade_overlay_node != null:
		var modulate: Color = instance.white_fade_overlay_node.modulate
		modulate.a = 1.0
		instance.white_fade_overlay_node.modulate = modulate
	return


## Sets the white overlay to fully transparent instantly.
static func set_white_overlay_transparent() -> void:
	if instance != null and instance.white_fade_overlay_node != null:
		var modulate: Color = instance.white_fade_overlay_node.modulate
		modulate.a = 0.0
		instance.white_fade_overlay_node.modulate = modulate
	return


# ----- OVERLAY TEXT -----

## Shows text in the center of the screen for a specified duration.
static func set_center_overlay_text(text: String, duration: float = 2.0) -> void:
	if instance != null and instance.on_screen_text_node != null:
		instance.on_screen_text_node.show_center_text(text, duration)
		pass
	return


## Shows text at the bottom of the screen for a specified duration.
static func set_bottom_overlay_text(text: String, duration: float = 2.0) -> void:
	if instance != null and instance.on_screen_text_node != null:
		instance.on_screen_text_node.show_subtitle(text, duration)
		pass
	return
