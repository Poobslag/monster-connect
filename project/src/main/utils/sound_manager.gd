@tool
extends Node
## Plays sound effects from a library.

## Number of milliseconds before the same sound can play a second time.
const DEFAULT_SUPPRESS_MSEC := 20

## Amplify spatial sounds to compensate for attenuation
const SPATIAL_VOLUME_DB_OFFSET := 8.0

const DEFAULT_VOLUME_DB := -4.0

## Size of the AudioStreamPlayer pool.[br]
## [br]
## A larger pool allows more simultaneous sounds but uses more resources.
const POOL_SIZE := 32

## Root directory to load .wav files from.
const BASE_DIR := "res://assets/main/sfx"

const MAX_DISTANCE := 2500.0

## Optional per-sound configuration.[br]
## [br]
## Supports keys:[br]
## - "semitones" (float): Semitones adjustment (0.0 = normal pitch)[br]
## - "semitones_randomness" (float): Random semitones variation. 2.0 = up to +/-2.0 semitones.[br]
## - "source" (String): Asset path. Lets multiple sounds reuse the same asset[br]
## - "suppress_msec" (int): Minimum milliseconds between repeated plays[br]
## - "volume_db" (float): Volume in decibels (0.0 = normal volume)[br]
## - "volume_db_randomness" (float): Random volume variation. 1.0 = up to -1.0 dB added to volume.
const SOUND_CONFIGS: Dictionary[String, Dictionary] = {
	"button_hover": {
		"source": "button_click",
		"semitones": -2.0,
	},
	"cheat_enabled": {
		"source": "surround_island_release",
	},
	"cheat_disabled": {
		"source": "surround_island_release",
		"semitones": -2.0
	},
	"cursor_move": {
		"source": "button_click",
		"volume_db": -24.0,
	},
	"drop_island_press": {
		"volume_db": -12.0,
	},
	"drop_island_release": {
		"semitones": 2.0,
		"source": "drop_island_press",
		"volume_db": -12.0,
	},
	"drop_wall_press": {
		"volume_db": -8.0,
	},
	"drop_wall_release": {
		"semitones": 2.0,
		"source": "drop_wall_press",
		"volume_db": -8.0,
	},
	"redo": {
		"source": "undo",
		"semitones": 2.0,
	},
	"surround_island_fail": {
		"source": "rule_broken",
		"semitones": -2.0,
	},
	"surround_island_press": {
		"source": "drop_wall_press",
	},
	"surround_island_release": {
		"volume_db": -8.0,
	},
	"win": {
		"volume_db": -12.0,
	},
}

## Players that are currently playing a sound.
var _in_use_player_2ds: Dictionary[AudioStreamPlayer2D, bool] = {}
var _in_use_players: Dictionary[AudioStreamPlayer, bool] = {}

## Players that are idle and available to play a sound.
var _available_player_2ds: Dictionary[AudioStreamPlayer2D, bool] = {}
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
	for player_2d: AudioStreamPlayer2D in _in_use_player_2ds.keys():
		if not player_2d.playing:
			_in_use_player_2ds.erase(player_2d)
			_available_player_2ds[player_2d] = true


func play_sfx_at(sound_key: String, pos: Vector2) -> AudioStreamPlayer2D:
	var sfx_distance: float = pos.distance_to(get_viewport().get_camera_2d().global_position)
	var config: Dictionary[Variant, Variant] = SOUND_CONFIGS.get(sound_key, {})
	var source_key: String = config.get("source", sound_key)
	var stream: AudioStream = sounds.get(source_key)
	if sfx_distance > MAX_DISTANCE:
		return null
	
	if stream == null:
		push_warning("Invalid sound key: %s" % [source_key])
		return null
	
	if _available_player_2ds.is_empty():
		push_warning("AudioStreamPlayer2D pool is empty.")
		return null
	
	var now: int = Time.get_ticks_msec()
	var last_played: int = _last_played_msec_by_key.get(source_key, 0)
	var suppress_msec: int = SOUND_CONFIGS.get(source_key, {}).get("suppress_msec", DEFAULT_SUPPRESS_MSEC)
	if last_played + suppress_msec > now:
		# suppress sound effect; sound was played too recently
		return null
	
	if sfx_distance < MAX_DISTANCE * 0.5:
		# only suppress repeat sfx for sounds that are loud enough
		_last_played_msec_by_key[source_key] = now
	
	var player: AudioStreamPlayer2D = _available_player_2ds.keys()[0]
	_available_player_2ds.erase(player)
	_in_use_player_2ds[player] = true
	player.global_position = pos
	player.volume_db = _volume_db_from_config(config) + SPATIAL_VOLUME_DB_OFFSET
	player.pitch_scale = _pitch_scale_from_config(config)
	player.stream = stream
	player.play()
	
	return player


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
	player.volume_db = _volume_db_from_config(config)
	player.pitch_scale = _pitch_scale_from_config(config)
	player.stream = stream
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
	
	for _i in POOL_SIZE:
		var player_2d := AudioStreamPlayer2D.new()
		player_2d.finished.connect(func() -> void:
			# Return the player to the available pool.
			#
			# Note: The 'finished' signal is only emitted when the sound ends naturally. If a sound is stopped
			# manually using AudioStreamPlayer.stop(), it will not emit 'finished'. The [method _process] method
			# handles detection of manually stopped sounds.
			_in_use_player_2ds.erase(player_2d)
			_available_player_2ds[player_2d] = true)
		player_2d.bus = "Sfx"
		player_2d.attenuation = 1.5
		player_2d.max_distance = MAX_DISTANCE
		player_2d.panning_strength = 0.5
		add_child(player_2d)
		_available_player_2ds[player_2d] = true


## Recursively loads all .wav files from [constant BASE_DIR] into the [member sounds] cache.
func _fill_sounds_cache() -> void:
	var sfx_paths: Array[String] = Utils.find_imported_files(BASE_DIR, "wav")
	
	for sfx_path: String in sfx_paths:
		var source_key: String = sfx_path
		source_key = source_key.trim_prefix(BASE_DIR)
		source_key = source_key.lstrip("/")
		source_key = source_key.trim_suffix(".wav")
		sounds[source_key] = load(sfx_path)


func _pitch_scale_from_config(config: Dictionary[Variant, Variant]) -> float:
	var base_semitones: float = config.get("semitones", 0.0)
	if config.has("semitones_randomness"):
		var semitones_randomness: float = config.get("semitones_randomness")
		base_semitones += randf_range(-semitones_randomness, semitones_randomness)
	return pow(2.0, base_semitones / 12.0)


func _volume_db_from_config(config: Dictionary[Variant, Variant]) -> float:
	var volume_db: float = config.get("volume_db", DEFAULT_VOLUME_DB)
	if config.has("volume_db_randomness"):
		var volume_db_randomness: float = config.get("volume_db_randomness")
		volume_db += randf_range(0, -volume_db_randomness)
	return volume_db
