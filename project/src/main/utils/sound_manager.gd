@tool
extends Node
## Plays sound effects from a library.

## Number of milliseconds before the same sound can play a second time.
const DEFAULT_SUPPRESS_MSEC := 20

const DEFAULT_VOLUME_DB := -4.0

## Size of the AudioStreamPlayer pool.[br]
## [br]
## A larger pool allows more simultaneous sounds but uses more resources.
const POOL_SIZE := 32

## Root directory to load .wav files from.
const BASE_DIR := "res://assets/main/sfx"

## Optional per-sound configuration.[br]
## [br]
## Supports keys:[br]
## - "pitch_scale" (float): Pitch multiplier (1.0 = normal pitch)[br]
## - "pitch_scale_randomness" (float): Random pitch variation. 0.04 = +/-0.04 added to the base pitch scale.
## - "source" (String): Asset path. Lets multiple sounds reuse the same asset[br]
## - "suppress_msec" (int): Minimum milliseconds between repeated plays[br]
## - "volume_db" (float): Volume in decibels (0.0 = normal volume)[br]
## - "volume_db_randomness" (float): Random volume variation. 1.0 = up to -1.0 dB added to volume.
const SOUND_CONFIGS: Dictionary[String, Dictionary] = {
	"cursor_move": {
		"volume_db": -12.0,
	},
	"drop_island_press": {
		"volume_db": -8.0,
	},
	"drop_island_release": {
		"pitch_scale": 1.2,
		"source": "drop_island_press",
		"volume_db": -8.0,
	},
	"drop_wall_release": {
		"pitch_scale": 1.2,
		"source": "drop_wall_press",
	},
	"redo": {
		"source": "undo",
		"pitch_scale": 1.2,
	},
	"surround_island_press": {
		"source": "drop_wall_press",
	},
	"surround_island_release": {
		"volume_db": -8.0,
	},
}

## Players that are currently playing a sound.
var _in_use_players: Dictionary[AudioStreamPlayer, bool] = {}

## Players that are idle and available to play a sound.
var _available_players: Dictionary[AudioStreamPlayer, bool] = {}

## Tracks last playback time for each sound key to suppress repeat sfx.
var _last_played_msec_by_key: Dictionary[String, int]

## Cache of all loaded sounds, keyed by their relative path (e.g. "ui/click")
var sounds: Dictionary[String, AudioStream] = {}

func _ready() -> void:
	_fill_audio_stream_player_pool()
	_fill_sounds_cache()


## Checks for completed sounds and returns their players to the available pool.
func _process(_delta: float) -> void:
	for player: AudioStreamPlayer in _in_use_players.keys():
		if not player.playing:
			_in_use_players.erase(player)
			_available_players[player] = true


## Plays the specified sound.[br]
## [br]
## The returned [AudioStreamPlayer] can be modified to tweak the sound's properties, but it's preferred to add an[br]
## entry to [member SOUND_CONFIGS].
func play_sfx(sound_key: String) -> AudioStreamPlayer:
	var config: Dictionary[Variant, Variant] = SOUND_CONFIGS.get(sound_key, {})
	var source_key: String = config.get("source", sound_key)
	var stream: AudioStream = sounds.get(source_key)
	if stream == null:
		push_warning("Invalid sound key: %s" % [source_key])
		return null
	
	if _available_players.is_empty():
		push_warning("AudioStreamPlayer pool is empty.")
		return null
	
	var now: int = Time.get_ticks_msec()
	var last_played: int = _last_played_msec_by_key.get(source_key, 0)
	var suppress_msec: int = SOUND_CONFIGS.get(source_key, {}).get("suppress_msec", DEFAULT_SUPPRESS_MSEC)
	if last_played + suppress_msec > now:
		# suppress sound effect; sound was played too recently
		return null
	
	_last_played_msec_by_key[source_key] = now
	var player: AudioStreamPlayer = _available_players.keys()[0]
	_available_players.erase(player)
	_in_use_players[player] = true
	var sound: AudioStream = sounds[source_key]
	player.volume_db = config.get("volume_db", DEFAULT_VOLUME_DB)
	if config.has("volume_db_randomness"):
		var volume_db_randomness: float = config.get("volume_db_randomness")
		player.volume_db += randf_range(0, -volume_db_randomness)
	player.pitch_scale = config.get("pitch_scale", 1.0)
	if config.has("pitch_scale_randomness"):
		var pitch_scale_randomness: float = config.get("pitch_scale_randomness")
		player.pitch_scale += randf_range(-pitch_scale_randomness, pitch_scale_randomness)
	player.stream = sound
	player.play()
	
	return player


## Prints all loaded sound keys to the console.
func print_sound_keys() -> void:
	print("Sound keys:")
	for key: String in sounds:
		print("[\"%s\"]," % [key])


## Initializes the pool of [AudioStreamPlayer] nodes and adds them to the scene tree.
func _fill_audio_stream_player_pool() -> void:
	for _i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.finished.connect(func() -> void:
			# Return the player to the available pool.
			#
			# Note: The 'finished' signal is only emitted when the sound ends naturally. If a sound is stopped
			# manually using AudioStreamPlayer.stop(), it will not emit 'finished'. The [method _process] method
			# handles detection of manually stopped sounds.
			_in_use_players.erase(player)
			_available_players[player] = true)
		player.bus = "Sfx"
		add_child(player)
		_available_players[player] = true


## Recursively loads all .wav files from [constant BASE_DIR] into the [member sounds] cache.
func _fill_sounds_cache() -> void:
	var sfx_paths: Array[String] = Utils.find_imported_files(BASE_DIR, "wav")
	
	for sfx_path: String in sfx_paths:
		var source_key: String = sfx_path
		source_key = source_key.trim_prefix(BASE_DIR)
		source_key = source_key.lstrip("/")
		source_key = source_key.trim_suffix(".wav")
		sounds[source_key] = load(sfx_path)
