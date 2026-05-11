class_name DataManager
extends Node

# ---------- COMPONENTS ----------
@onready var instance: DataManager = self

# ---------- DEBUGGING ----------
@export var log_ready: bool = false


# ---------- DATA HANDLING ----------

## A class designed to carry any Variant object
class Data:
	var id: String
	var value: Variant
	var owner_id: String
	
	func _init(i: String, v: Variant, o: String) -> void:
		id = i
		owner_id = o
		value = v

## Stores all the live game data.
static var _database: Array[Data] = []

# ----- INDIVIDUAL DATA -----

## Writes the given data to the database, overwriting if an existing id and owner_id already exists.
static func write(id: String, value: Variant = null, owner_id: String = "") -> void:
	var index: int = 0
	var exists: bool = false
	
	for data: Data in _database:
		index += 1
		
		if data.id == id and data.owner_id == owner_id:
			_database[index].value = value
			exists = true
			break
		pass
	
	if not exists:
		var new_data: Data = Data.new(id, value, owner_id)
		_database.append(new_data)
		pass
	return


## Reads the data from the given id and owner_id.
## Returns null if no such entry exists, with an option to push an error.
static func read(id: String, owner_id: String = "", error_if_nonexistent: bool = false) -> Variant:
	var to_return: Variant = null
	
	for data: Data in _database:
		if data.id == id and data.owner_id == owner_id:
			to_return = data
			break
		pass
	
	if to_return == null and error_if_nonexistent:
		Log.err("Data with id %s from owner %s does not exist." % [id, owner_id])
		pass
	return to_return


## Deletes the given data to the database.
static func delete(id: String, owner_id: String = "", warn_if_nonexistent: bool = false) -> void:
	var index: int = 0
	var exists: bool = false
	
	for data: Data in _database:
		index += 1
		
		if data.id == id and data.owner_id == owner_id:
			exists = true
			_database.remove_at(index)
			break
		pass
	
	if not exists and warn_if_nonexistent:
		Log.me("Data with id %s from owner %s does not exist." % [id, owner_id])
		pass
	return


## Logs the data from the given id and owner_id.
static func log(id: String, owner_id: String = "", warn_if_nonexistent: bool = false) -> void:
	var to_log: Variant = null
	
	for data: Data in _database:
		if data.id == id and data.owner_id == owner_id:
			to_log = data
			break
		pass
	
	if to_log == null and warn_if_nonexistent:
		Log.err("Data with id %s from owner %s does not exist." % [id, owner_id])
		return
	
	Log.me("Data > Owner = %s > ID = %s > Value = %s" % [to_log.owner_id, to_log.id, str(to_log.value)])
	return



# ----- BULK DATA -----

## Writes the given data to the database, overwriting if an existing id and owner_id already exists.
static func write_all(input_data: Array[Data]) -> void:
	for data: Data in input_data:
		write(data.id, data.value, data.owner_id)
		pass
	return


## Reads all data from the given id.
## Returns null if no such entry exists, with an option to push an error.
static func read_all_by_id(id: String, error_if_nonexistent: bool = false) -> Array[Variant]:
	var to_return: Array[Variant] = []
	
	for data: Data in _database:
		if data.id == id:
			to_return.append(data)
			pass
		pass
	
	if to_return.size() == 0 and error_if_nonexistent:
		Log.err("Data with id does not exist." % [id])
		pass
	return to_return


## Reads all data from the given owner_id.
## Returns null if no such entry exists, with an option to push an error.
static func read_all_by_owner(owner_id: String = "", error_if_nonexistent: bool = false) -> Array[Variant]:
	var to_return: Array[Variant] = []
	
	for data: Data in _database:
		if data.owner_id == owner_id:
			to_return.append(data)
			pass
		pass
	
	if to_return.size() == 0 and error_if_nonexistent:
		Log.err("Data from owner %s does not exist." % [owner_id])
		pass
	return to_return


## Deletes all data from the given id.
static func delete_all_by_id(id: String, warn_if_nonexistent: bool = false) -> void:
	var index: int = 0
	var exists: bool = false
	
	for data: Data in _database:
		index += 1
		if data.id == id:
			exists = true
			_database.remove_at(index)
			pass
		pass
	
	if not exists and warn_if_nonexistent:
		Log.warn("Data with id does not exist." % [id])
		pass
	return


## Deletes all data from the given owner_id.
static func delete_all_by_owner(owner_id: String = "", warn_if_nonexistent: bool = false) -> void:
	var index: int = 0
	var exists: bool = false
	
	for data: Data in _database:
		index += 1
		if data.owner_id == owner_id:
			exists = true
			_database.remove_at(index)
			pass
		pass
	
	if not exists and warn_if_nonexistent:
		Log.warn("Data from owner %s does not exist." % [owner_id])
		pass
	return


## Logs all data from the given id.
static func log_all_by_id(id: String, warn_if_nonexistent: bool = false) -> void:
	var exists: bool = false
	
	for data: Data in _database:
		if data.id == id:
			Log.me("Data > Owner = %s > ID = %s > Value = %s" % [data.owner_id, data.id, str(data.value)])
			exists = true
			break
		pass
	
	if not exists and warn_if_nonexistent:
		Log.warn("Data with id %s does not exist." % [id])
		pass
	return


## Logs all data from the given id.
static func log_all_by_owner(owner_id: String, warn_if_nonexistent: bool = false) -> void:
	var exists: bool = false
	
	for data: Data in _database:
		if data.owner_id == owner_id:
			Log.me("Data > Owner = %s > ID = %s > Value = %s" % [data.owner_id, data.id, str(data.value)])
			exists = true
			break
		pass
	
	if not exists and warn_if_nonexistent:
		Log.warn("Data from owner %s does not exist." % [owner_id])
		pass
	return


## Clears all data from the database.
static func clear_database() -> void:
	_database.clear()
	return


# ---------- FILE HANDLING ----------

## Writes the provided String to the specified file.
## This file is located at USER/Documents/GAME_TITLE
static func write_file(file_name: String, json_content: String) -> void:
	# TODO: Write a save-to-file function.
	pass


## Reads the specified file and returns its contents as a String.
## This file is located at USER/Documents/GAME_TITLE
static func read_file(file_name: String) -> String:
	# TODO: Write a read-from-file function.
	return ""



# ---------- GODOT CALLBACKS ----------
func _ready() -> void:
	pass
