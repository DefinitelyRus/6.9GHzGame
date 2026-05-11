## Manages audio playback across different channels.
## Handles SFX, music, and ambient sounds.
## Also supports dynamic volume adjustment, fading, and spatial (2D) audio.
class_name AudioManager
extends Node2D

# ---------- ENUMS ----------

## The different audio channels available for playback.
enum AudioChannels {
	MASTER,
	MUSIC,
	SFX,
	AMBIENT
}


# ---------- COMPONENTS ----------

## The singleton instance of the AudioManager.
static var instance: AudioManager

## Reference to the Master node.
@onready var m: Master = get_node("/root/Master")


# ---------- DEBUGGING ----------

## Whether to log when the AudioManager is ready.
@export var log_ready: bool = true

## Whether to log audio playback events.
@export var log_playback: bool = false


# ---------- PROPERTIES ----------

## The master volume multiplier.
@export var universal_volume: float = 0.4

## The sound effects volume multiplier.
@export var sfx_volume: float = 0.7

## The music volume multiplier.
@export var music_volume: float = 0.3

## The ambient sound volume multiplier.
@export var ambient_volume: float = 0.8

## The speed at which audio fades out.
@export var fade_out_speed: float = 1.0

## A dictionary storing audio streams by name.
@export var sfx_library: Dictionary = {}

## An array of currently playing audio streams.
var audio_streams: Array[AudioStreamPlayer] = []

## Streams queued for removal during fade out.
static var streams_to_remove: Array[AudioStreamPlayer] = []

## Whether the audio manager is currently fading out all audio.
var _is_fading_out: bool = false


# ---------- GODOT CALLBACKS ----------

func _enter_tree() -> void:
	Log.me("AudioManager entered the tree. Checking properties...", log_ready, true)
	instance = self
	Log.me("Done!", true)
	return


func _process(delta: float) -> void:
	if Master.is_paused:
		return
	update_fade_out(delta)
	return


# ---------- AUDIO PLAYBACK ----------

## Plays an audio stream from the library by name.
static func stream_audio(sfx_name: String, channel: int = AudioChannels.SFX, volume: float = 1.0) -> AudioStreamPlayer:
	if not instance.sfx_library.has(sfx_name):
		Log.warn("SFX '" + sfx_name + "' not found in SFX Library!", true, true)
		return null
		
	var stream: AudioStream = instance.sfx_library[sfx_name]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var suffix: int = rng.randi_range(0, 99999)
	var id: String = sfx_name + "#%05d" % suffix
	
	var player: AudioStreamPlayer = stream_audio_by_stream(stream, id, channel, volume)
	return player


## Plays a specific AudioStream object.
static func stream_audio_by_stream(stream: AudioStream, unique_name: String = "", channel: int = AudioChannels.SFX, volume: float = 1.0) -> AudioStreamPlayer:
	if unique_name == "":
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		var rand_suffix: int = rng.randi_range(0, 999999)
		unique_name = "audio_" + str(rand_suffix)
		pass
		
	var final_vol: float = volume * instance.universal_volume
	
	if channel == AudioChannels.MUSIC:
		final_vol *= instance.music_volume
		pass

	elif channel == AudioChannels.SFX:
		final_vol *= instance.sfx_volume
		pass

	elif channel == AudioChannels.AMBIENT:
		final_vol *= instance.ambient_volume
		pass
		
	var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
	audio_player.name = unique_name
	audio_player.stream = stream
	
	var db_vol: float = linear_to_db(final_vol)
	audio_player.volume_db = db_vol
	audio_player.autoplay = false
	
	instance.audio_streams.append(audio_player)
	instance.add_child(audio_player)
	
	var cb: Callable = func() -> void:
		instance.audio_streams.erase(audio_player)
		audio_player.queue_free()
		return
		
	audio_player.finished.connect(cb)
	audio_player.play()
	return audio_player


## Plays an audio stream from the library by name in 2D space.
static func stream_audio_2d(sfx_name: String, pos: Vector2, channel: int, volume: float = 1.0) -> AudioStreamPlayer2D:
	if not instance.sfx_library.has(sfx_name):
		Log.warn("SFX '" + sfx_name + "' not found in SFX Library!", true, true)
		return null
		
	var stream: AudioStream = instance.sfx_library[sfx_name]
	var player: AudioStreamPlayer2D = stream_audio_2d_by_stream(stream, pos, channel, volume)
	return player


## Plays a specific AudioStream object in 2D space at the given position.
static func stream_audio_2d_by_stream(stream: AudioStream, pos: Vector2, channel: int, volume: float = 1.0) -> AudioStreamPlayer2D:
	var final_vol: float = volume * instance.universal_volume
	
	if channel == AudioChannels.MUSIC:
		final_vol *= instance.music_volume
		pass
		
	elif channel == AudioChannels.SFX:
		final_vol *= instance.sfx_volume
		pass
		
	elif channel == AudioChannels.AMBIENT:
		final_vol *= instance.ambient_volume
		pass
		
	var sfx_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	sfx_player.stream = stream
	sfx_player.position = pos
	sfx_player.autoplay = false
	
	var db_vol: float = linear_to_db(final_vol)
	sfx_player.volume_db = db_vol
	
	var cb: Callable = func() -> void:
		sfx_player.queue_free()
		return
		
	sfx_player.finished.connect(cb)
	instance.add_child(sfx_player)
	sfx_player.play()
	return sfx_player


# ---------- AUDIO CONTROL ----------

## Stops playing a specific audio stream by its unique name.
static func stop_music(unique_name: String) -> void:
	var player: AudioStreamPlayer = null
	
	for stream: AudioStreamPlayer in instance.audio_streams:
		if stream.name == unique_name:
			player = stream
			break
		pass
			
	if player == null:
		Log.warn("No audio stream with the name '" + unique_name + "' is currently playing.")
		return
		
	player.stop()
	instance.audio_streams.erase(player)
	player.queue_free()
	return


## Triggers an audio fade-in. (Currently unimplemented)
static func fade_in_audio() -> void:
	# TODO: Implement audio fade-in logic
	pass


## Triggers an audio fade-out for all currently playing streams.
static func fade_out_audio() -> void:
	instance._is_fading_out = true
	return


## Processes the fade-out logic for all active audio streams.
static func update_fade_out(delta: float) -> void:
	if not instance._is_fading_out:
		return
		
	for player: AudioStreamPlayer in instance.audio_streams:
		var dec: float = instance.fade_out_speed * delta
		var cur_lin: float = db_to_linear(player.volume_db)
		var next_lin: float = clampf(cur_lin - dec, 0.0, 1.0)
		
		player.volume_db = linear_to_db(next_lin)
		
		if next_lin <= 0.0:
			player.volume_db = linear_to_db(0.0)
			player.stop()
			streams_to_remove.append(player)
			player.queue_free()
			pass
		pass
			
	for player: AudioStreamPlayer in streams_to_remove:
		instance.audio_streams.erase(player)
		pass
		
	streams_to_remove.clear()
	
	var still_playing: bool = instance.audio_streams.size() > 0
	instance._is_fading_out = still_playing
	return
