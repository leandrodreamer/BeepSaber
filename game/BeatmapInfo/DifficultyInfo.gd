extends RefCounted
class_name DifficultyInfo

var difficulty: String
var difficulty_rank: int
var characteristic: String
var beatmap_filename: String
var note_jump_movement_speed: float
var note_jump_start_beat_offset: float
var custom_data: Dictionary
# not officially part of the spec, but used by mods a lot
var custom_name: String

func _init(
	difficulty: String, difficulty_rank: int, beatmap_filename: String,
	note_jump_movement_speed: float, note_jump_start_beat_offset: float,
	custom_data: Dictionary, custom_name: String, characteristic: String
) -> void:
	self.difficulty = difficulty
	self.difficulty_rank = difficulty_rank
	self.beatmap_filename = beatmap_filename
	self.note_jump_movement_speed = note_jump_movement_speed
	self.note_jump_start_beat_offset = note_jump_start_beat_offset
	self.custom_data = custom_data
	# not officially part of the spec, but used by mods a lot
	self.custom_name = custom_name
	self.characteristic = characteristic

func get_display_name() -> String:
	var name := ""
	if self.custom_name != null and custom_name.length() > 0:
		name = self.custom_name
	else:
		name = self.difficulty
	if self.characteristic != "" and self.characteristic != "Standard":
		return name + " " + self.characteristic
	else:
		return name

static func load_v2(diff_dict: Dictionary, characteristic: String) -> DifficultyInfo:
	var diff := Utils.get_str(diff_dict, "_difficulty", "")
	var data := Utils.get_dict(diff_dict, "_customData", {})
	
	var name := ""
	# not officially part of the spec, but used by mods a lot
	if not data.is_empty():
		name = Utils.get_str(data, "_difficultyLabel", "")
	if name.is_empty():
		name = diff
	
	return DifficultyInfo.new(
		diff,
		int(Utils.get_float(diff_dict, "_difficultyRank", 0)),
		Utils.get_str(diff_dict, "_beatmapFilename", ""),
		Utils.get_float(diff_dict, "_noteJumpMovementSpeed", 1.0),
		Utils.get_float(diff_dict, "_noteJumpStartBeatOffset", 0.0),
		data,
		name,
		characteristic
	)

static func load_v4(diff_dict: Dictionary) -> DifficultyInfo:
	var diff := Utils.get_str(diff_dict, "difficulty", "")
	var data := Utils.get_dict(diff_dict, "customData", {})
	
	var name := ""
	# not officially part of the spec, but used by mods a lot
	if not data.is_empty():
		name = Utils.get_str(data, "difficultyLabel", "")
	if name.is_empty():
		name = diff
	
	return DifficultyInfo.new(
		diff,
		0, # TODO: difficulty rank
		Utils.get_str(diff_dict, "beatmapDataFilename", ""), # TODO: lightshow
		Utils.get_float(diff_dict, "noteJumpMovementSpeed", 1.0),
		Utils.get_float(diff_dict, "noteJumpStartBeatOffset", 0.0),
		data,
		name,
		Utils.get_str(diff_dict, "characteristic", "")
	)
