extends RefCounted
class_name ColorNoteInfo

var beat: float
var line_index: int
var line_layer: int
var color: int
var cut_direction: int
var angle_offset: int
var custom_data: Dictionary

@warning_ignore("shadowed_variable")
func _init(beat: float, line_index: int, line_layer: int, color: int, cut_direction: int, angle_offset: int, custom_data: Dictionary) -> void :
	self.beat = beat
	self.line_index = line_index
	self.line_layer = line_layer
	self.color = color
	self.cut_direction = cut_direction
	self.angle_offset = angle_offset
	self.custom_data = custom_data

static func new_v2(note_dict: Dictionary) -> ColorNoteInfo:
	return ColorNoteInfo.new(
		Utils.get_float(note_dict, "_time", 0.0), 
		int(Utils.get_float(note_dict, "_lineIndex", 0)), 
		int(Utils.get_float(note_dict, "_lineLayer", 0)), 
		int(Utils.get_float(note_dict, "_type", -1.0)), 
		int(Utils.get_float(note_dict, "_cutDirection", 0)), 
		0, 
		Utils.get_dict(note_dict, "_customData", {})
	)

static func new_v3(note_dict: Dictionary) -> ColorNoteInfo:
	return ColorNoteInfo.new(
		Utils.get_float(note_dict, "b", 0.0), 
		int(Utils.get_float(note_dict, "x", 0)), 
		int(Utils.get_float(note_dict, "y", 0)), 
		int(Utils.get_float(note_dict, "c", -1)), 
		int(Utils.get_float(note_dict, "d", 0)), 
		int(Utils.get_float(note_dict, "a", 0)), 
		Utils.get_dict(note_dict, "_customData", {})
	)
