class_name SceneLoader
extends Node

@export_group("Components")
@export var theatre: Node
@export var main_menu: PackedScene
@export var dev_scene: PackedScene
@export var levels: Array[PackedScene] = []

static var instance: SceneLoader = self
static var level_index: int = 0
static var loaded_scene: Node = null

@export_group("Debugging")
@export var log_ready: bool = false
@export var suppress_warnings: bool = false


# ---------- GODOT CALLBACKS ----------
func _enter_tree() -> void:
	Log.me("A SceneLoader has entered the tree. Checking properties...", log_ready)

	if instance != null:
		Log.err("Multiple instances of SceneLoader detected. There should only be one SceneLoader in the scene.")
		queue_free()
		return
	
	instance = self

	if theatre == null:
		Log.err("Theatre is not assigned. Nowhere to put loaded scenes into.")
		return
	
	if levels.size() == 0 and not suppress_warnings:
		Log.warn("No levels assigned.")
		pass

	for i: int in range(levels.size()):
		if levels[i] == null:
			Log.warn("Level of index " + str(i) + " is not assigned.")
			pass
		pass

	Log.me("Done!", log_ready)


func _ready() -> void:
	Log.me("Readying SceneLoader...", log_ready, true)
		
	if dev_scene != null:
		if not suppress_warnings:
			Log.warn("Currently using `DevScene`. `MainMenu` will not be loaded.", log_ready)
			pass
		
		load_scene(dev_scene)
		pass
		
	Log.me("Done!", log_ready)
	return


# ---------- LOADING LEVELS ----------
### Finds a level at the specified index and returns it as a PackedScene.
static func get_level(index: int) -> PackedScene:
	var retrieved_level: PackedScene = null
	if index >= 0 and index < instance.levels.size():
		retrieved_level = instance.levels[index]
		pass
	
	if retrieved_level == null:
		Log.err("Level of index %d not found." % index)
		pass
		
	return retrieved_level


### Finds a level at the specified index and loads it.
static func load_level_from_index(index: int) -> void:
	var level_to_load: PackedScene = get_level(index)

	if level_to_load == null:
		Log.err("Level of index " + str(index) + " not found.")
		return
	
	level_index = index
	load_scene(level_to_load)
	return


### Loads a level using the provided PackedScene.
static func load_scene(level_scene: PackedScene) -> void:
	var level: Node = level_scene.instantiate()
		
	unload_level(false)
	instance.theatre.add_child(level)
	instance.loaded_scene = level

	#Master.instance.background.visible = false
	return


### Unloads the currently-loaded level.
static func unload_level(return_to_main_menu: bool = true) -> void:
	if instance.loaded_scene == null or instance.theatre.get_child_count() == 0:
		return
		
	instance.theatre.remove_child(instance.loaded_scene)
	instance.loaded_scene.queue_free()
	instance.loaded_scene = null
	
	if return_to_main_menu:
		Master.instance.background.visible = true
		instance.loaded_scene = null
		pass
	return


### Loads the next level on the levels list.
static func next_level() -> void:
	if instance.loaded_scene != null:
		load_level_from_index(instance.loaded_scene.level_index + 1)
		pass
	return


### Loads the previous level on the levels list.
static func previous_level() -> void:
	if instance.loaded_scene != null:
		if instance.loaded_scene.level_index == 0:
			return

		load_level_from_index(instance.loaded_scene.level_index - 1)
		pass
	return
