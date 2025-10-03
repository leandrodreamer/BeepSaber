extends Node

var config := ConfigFile.new()

const SECTION := "OpenSaber"
const CONFIG_PATH := "user://config.ini"
const OLD_CONFIG_PATH := "user://config.dat"
var SABER_VISUALS: Array[PackedStringArray] = [
	PackedStringArray(["Default saber","res://game/sabers/default/default_saber.tscn"]),
	PackedStringArray(["Particle sword","res://game/sabers/particles/particles_saber.tscn"])
]

signal changed(name: StringName)

var thickness: float:
	set(value):
		thickness = value
		set_and_emit(&"thickness", value)
var color_left: Color:
	set(value):
		color_left = value
		set_and_emit(&"color_left", value)
var color_right: Color:
	set(value):
		color_right = value
		set_and_emit(&"color_right", value)
var saber_visual: int:
	set(value):
		saber_visual = value
		set_and_emit(&"saber_visual", value)
var ui_volume: float:
	set(value):
		ui_volume = value
		set_and_emit(&"ui_volume", value)
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
var audio_music: float:
	set(value):
		audio_music = value
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"), linear_to_db(value))
		set_and_emit(&"audio_music", value)
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



func _ready() -> void:
	if OS.get_name() in platform_default_values.keys():
		for key in platform_default_values[OS.get_name()].keys():
			default_values[key] = platform_default_values[OS.get_name()][key]
	
	if FileAccess.file_exists(CONFIG_PATH):
		reload()
	elif FileAccess.file_exists(OLD_CONFIG_PATH):
		load_old_config()
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
	color_left = Color("ff1a1a"),
	color_right = Color("1a1aff"),
	saber_tail = true,
	glare = true,
	show_debug_info = false,
	bombs_enabled = true,
	events = true,
	saber_visual = 0,
	ui_volume = 10.0,
	left_saber_offset_pos = Vector3.ZERO,
	left_saber_offset_rot = Vector3.ZERO,
	right_saber_offset_pos = Vector3.ZERO,
	right_saber_offset_rot = Vector3.ZERO,
	disable_map_color = false,
	player_height_offset = 0.0,
	audio_master = 0.8,
	audio_music = 0.8,
	audio_sfx = 0.8,
	spectator_view = false,
	spectator_hud = true,
	obstacle_color = Color(1,0,0)
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

func load_old_config() -> void:
	var file := FileAccess.open(OLD_CONFIG_PATH, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		vr.log_file_error(FileAccess.get_open_error(), OLD_CONFIG_PATH, "load_old_config() in Settings.gd")
		return
	var settings_var: Variant = file.get_var(true)
	file.close()
	if not settings_var is Dictionary:
		restore_defaults()
		return
	var settings_dict := settings_var as Dictionary
	thickness = Utils.get_float(settings_dict, "thickness", 1)
	if settings_dict.has("COLOR_LEFT") and settings_dict["COLOR_LEFT"] is Color:
		@warning_ignore("unsafe_cast")
		color_left = settings_dict["COLOR_LEFT"] as Color
	else:
		color_left = Color("ff1a1a")
	if settings_dict.has("COLOR_RIGHT") and settings_dict["COLOR_RIGHT"] is Color:
		@warning_ignore("unsafe_cast")
		color_right = settings_dict["COLOR_RIGHT"] as Color
	else:
		color_right = Color("1a1aff")
	saber_visual = int(Utils.get_float(settings_dict, "saber", 0))
	ui_volume = Utils.get_float(settings_dict, "ui_volume", 10.0)
	left_saber_offset_pos = Vector3.ZERO
	left_saber_offset_rot = Vector3.ZERO
	if settings_dict.has("left_saber_offset") and settings_dict["left_saber_offset"] is Array:
		@warning_ignore("unsafe_cast")
		var left_array: Array = settings_dict["left_saber_offset"] as Array
		if left_array.size() == 2:
			if left_array[0] is Vector3:
				@warning_ignore("unsafe_cast")
				left_saber_offset_pos = left_array[0] as Vector3
			if left_array[1] is Vector3:
				@warning_ignore("unsafe_cast")
				left_saber_offset_rot = left_array[1] as Vector3
	right_saber_offset_pos = Vector3.ZERO
	right_saber_offset_rot = Vector3.ZERO
	if settings_dict.has("right_saber_offset") and settings_dict["right_saber_offset"] is Array:
		@warning_ignore("unsafe_cast")
		var right_array: Array = settings_dict["right_saber_offset"] as Array
		if right_array.size() == 2:
			if right_array[0] is Vector3:
				@warning_ignore("unsafe_cast")
				right_saber_offset_pos = right_array[0] as Vector3
			if right_array[1] is Vector3:
				@warning_ignore("unsafe_cast")
				right_saber_offset_rot = right_array[1] as Vector3
	cube_cuts_falloff = Utils.get_bool(settings_dict, "cube_cuts_falloff", true, {"Web": false})
	saber_tail = Utils.get_bool(settings_dict, "saber_tail", true, {"Web": false})
	glare = Utils.get_bool(settings_dict, "glare", true, {"Android": false, "Web": false})
	show_debug_info = Utils.get_bool(settings_dict, "show_debug_info", false)
	bombs_enabled = Utils.get_bool(settings_dict, "bombs_enabled", true)
	events = Utils.get_bool(settings_dict, "events", true, {"Web": false})
	disable_map_color = Utils.get_bool(settings_dict, "disable_map_color", false)
	player_height_offset = Utils.get_float(settings_dict, "player_height_offset", 0.0)

func save() -> void:
	var error := config.save(CONFIG_PATH)
	if error != OK:
		vr.log_file_error(error, CONFIG_PATH, "save() in Settings.gd")
		return
	# remove old config
	if FileAccess.file_exists(OLD_CONFIG_PATH):
		error = DirAccess.open("user://").remove(OLD_CONFIG_PATH)
		if error != OK:
			vr.log_file_error(error, OLD_CONFIG_PATH, "save() in Settings.gd")

func restore_defaults() -> void:
	config.clear()
	save()
	reload()
