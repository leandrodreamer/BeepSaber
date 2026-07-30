extends Node

var config := ConfigFile.new()

const SECTION := "OpenSaber"
var CONFIG_PATH := Constants.CONFIG_ROOT_PATH + "config.ini"
var SABER_VISUALS: Array[PackedStringArray] = [
	PackedStringArray(["Default saber","res://game/sabers/default/default_saber.tscn"]),
	PackedStringArray(["Particle sword","res://game/sabers/particles/particles_saber.tscn"])
]

const BACKGROUND_TEXTURES := [ ["res://game/data/background/fractal.jpg", "Fractal 1"],
		["res://game/data/background/fractal2.jpg", "Fractal 2"],
		["res://game/data/background/nightsky.jpg", "Night Sky (credit: ESA/S. Brunier)"],
		["res://game/data/background/bg_base.jpg", "Original Open Saber"] ]

const BACKGROUND_MODES := [ ["dynamic", "*Dynamic"],
		["simple", "Simple"],
		["static", "Static"] ]

signal changed(name: StringName)

var LANE_DISTANCE_X := Constants.DEFAULT_LANE_DISTANCE_X
var LANE_ZERO_X := Constants.DEFAULT_LANE_ZERO_X

var preloaded_songs: bool:
	set(value):
		preloaded_songs = value
var thickness: float:
	set(value):
		thickness = value
		set_and_emit(&"thickness", value)
var claws: bool:
	set(value):
		claws = value
		set_and_emit(&"claws", value)
var color_left: Color:
	set(value):
		color_left = value
		set_and_emit(&"color_left", value)
var color_right: Color:
	set(value):
		color_right = value
		set_and_emit(&"color_right", value)
var gradual_rotation: float:
	set(value):
		gradual_rotation = value
		set_and_emit(&"gradual_rotation", value)
var saber_visual: int:
	set(value):
		saber_visual = value
		set_and_emit(&"saber_visual", value)
var ui_volume: float:
	set(value):
		ui_volume = value
		set_and_emit(&"ui_volume", value)
var width: int:
	set(value):
		width = value
		LANE_DISTANCE_X = Constants.DEFAULT_LANE_DISTANCE_X * width / 100.
		LANE_ZERO_X = Constants.DEFAULT_LANE_ZERO_X * width / 100.
		set_and_emit(&"width", value)
var flip: int:
	set(value):
		flip = value
		set_and_emit(&"flip", value)
var handedness: int:
	set(value):
		handedness = value
		set_and_emit(&"handedness", value)
var left_saber_offset_pos: Vector3:
	set(value):
		left_saber_offset_pos = value
		set_and_emit(&"left_saber_offset_pos", value)
var left_saber_offset_rot: Vector3:
	set(value):
		left_saber_offset_rot = value
		set_and_emit(&"left_saber_offset_rot", value)
var right_saber_offset_pos: Vector3:
	set(value):
		right_saber_offset_pos = value
		set_and_emit(&"right_saber_offset_pos", value)
var right_saber_offset_rot: Vector3:
	set(value):
		right_saber_offset_rot = value
		set_and_emit(&"right_saber_offset_rot", value)
var cube_cuts_falloff: bool:
	set(value):
		cube_cuts_falloff = value
		set_and_emit(&"cube_cuts_falloff", value)
var saber_tail: bool:
	set(value):
		saber_tail = value
		set_and_emit(&"saber_tail", value)
var glare: bool:
	set(value):
		glare = value
		set_and_emit(&"glare", value)
var show_debug_info: bool:
	set(value):
		show_debug_info = value
		set_and_emit(&"show_debug_info", value)
var mixed_reality: bool:
	set(value):
		mixed_reality = value
		set_and_emit(&"mixed_reality", value)
var explain: bool:
	set(value):
		explain = value
		set_and_emit(&"explain", value)
var left_handed: bool:
	set(value):
		left_handed = value
		set_and_emit(&"left_handed", value)
var not_music_dl: bool:
	set(value):
		not_music_dl = value
		set_and_emit(&"not_music_dl", value)
var swing_scoring: bool:
	set(value):
		swing_scoring = value
		set_and_emit(&"swing_scoring", value)
var bombs_enabled: bool:
	set(value):
		bombs_enabled = value
		set_and_emit(&"bombs_enabled", value)
var events: bool:
	set(value):
		events = value
		set_and_emit(&"events", value)
var disable_map_color: bool:
	set(value):
		disable_map_color = value
		set_and_emit(&"disable_map_color", value)
var player_height_offset: float:
	set(value):
		player_height_offset = value
		set_and_emit(&"player_height_offset", value)
var audio_master: float:
	set(value):
		audio_master = value
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"), linear_to_db(value))
		set_and_emit(&"audio_master", value)
		Utils.update_bus_speed(&"Music")
		Utils.update_bus_speed(&"MusicPreview")
var audio_music: float:
	set(value):
		audio_music = value
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"), linear_to_db(value))
		set_and_emit(&"audio_music", value)
		Utils.update_bus_speed(&"Music")
var music_speed: int:
	set(value):
		music_speed = value
		set_and_emit(&"music_speed", value)
		Utils.update_bus_speed(&"Music")
		Utils.update_bus_speed(&"MusicPreview")
var audio_music_preview: float:
	set(value):
		audio_music_preview = value
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"MusicPreview"), linear_to_db(value))
		set_and_emit(&"audio_music_preview", value)
		Utils.update_bus_speed(&"MusicPreview")
var audio_sfx: float:
	set(value):
		audio_sfx = value
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"SFX"), linear_to_db(value))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"UI"), linear_to_db(value))
		set_and_emit(&"audio_sfx", value)
var spectator_view: bool:
	set(value):
		spectator_view = value
		set_and_emit(&"spectator_view", value)
var spectator_hud: bool:
	set(value):
		spectator_hud = value
		set_and_emit(&"spectator_hud", value)
var background: String:
	set(value):
		background = value
		set_and_emit(&"background", value)
var background_texture: String:
	set(value):
		background_texture = value
		set_and_emit(&"background_texture", value)
var health_mode: bool:
	set(value):
		health_mode = value
		set_and_emit(&"health_mode", value)
var arrows_enabled: bool:
	set(value):
		arrows_enabled = value
		set_and_emit(&"arrows_enabled", value)
var block_size: int:
	set(value):
		block_size = value
		set_and_emit(&"block_size", value)
var last_map: String:
	set(value):
		last_map = value
		set_and_emit(&"last_map", value)
	
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(Constants.CONFIG_ROOT_PATH)

	if OS.get_name() in platform_default_values.keys():
		for key in platform_default_values[OS.get_name()].keys():
			default_values[key] = platform_default_values[OS.get_name()][key]
	
	if FileAccess.file_exists(CONFIG_PATH):
		reload()
	else:
		restore_defaults()
		save()

const platform_default_values = {
	Android = {
		glare = false,
	},
	Web = {
		glare = false,
		saber_tail = false,
		cube_cuts_falloff = false,
		events = false,
	},
}

var default_values = {
	thickness = 1.0,
	cube_cuts_falloff = true,
	color_left = Color("1a1aff"),
	color_right = Color("ff1a1a"),
	saber_tail = true,
	gradual_rotation = 0,
	glare = true,
	show_debug_info = false,
	mixed_reality = false,
	explain = false,
	left_handed = false,
	not_music_dl = false,
	swing_scoring = true,
	bombs_enabled = true,
	events = true,
	saber_visual = 0,
	ui_volume = 10.0,
	width = 100,
	flip = 0,
	handedness = 0,
	left_saber_offset_pos = Vector3.ZERO,
	left_saber_offset_rot = Vector3.ZERO,
	right_saber_offset_pos = Vector3.ZERO,
	right_saber_offset_rot = Vector3.ZERO,
	disable_map_color = false,
	player_height_offset = 0.0,
	audio_master = 0.8,
	audio_music = 0.8,
	music_speed = 100,
	audio_music_preview = 0.6,
	audio_sfx = 0.8,
	spectator_view = false,
	spectator_hud = true,
	background = "dynamic",
	background_texture = "res://game/data/background/nightsky.jpg",
	health_mode = false,
	arrows_enabled = true,
	block_size = 100,
	last_map = "",
	claws = false,
	preloaded_songs = false
}

func cast_or_default(key: String, to_type: int = -1) -> Variant:
	var default = default_values[key] if key in default_values else null
	return convert(config.get_value(SECTION, key, default), typeof(default) if to_type < 0 else to_type)

func set_and_emit(key: StringName, value: Variant) -> void:
	config.set_value(SECTION, String(key), value if default_values[key] != value else null)
	changed.emit(key)

# load() is the name of a built-in function,
# so i went with the next best thing.
func reload() -> void:
	var config_error := config.load(CONFIG_PATH)
	if config_error != OK:
		vr.log_file_error(config_error, CONFIG_PATH, "reload() in Settings.gd")
		return
	
	for key in default_values:
		set(key, cast_or_default(key))

func save() -> void:
	var error := config.save(CONFIG_PATH)
	if error != OK:
		vr.log_file_error(error, CONFIG_PATH, "save() in Settings.gd")
		return

func restore_defaults() -> void:
	config.clear()
	save()
	reload()
	
func get_saber_visuals() -> String:
	return SABER_VISUALS[saber_visual if not claws else 0][1]
