extends RefCounted
class_name ObstacleInfo

var beat: float
var duration: float
var line_index: int
var line_layer: int
var width: int
var height: int
var custom_data: Dictionary
var type: int

@warning_ignore("shadowed_variable")
func _init(beat: float, duration: float, line_index: int, line_layer: int, width: int, height: int, custom_data: Dictionary, type: int) -> void :
	self.beat = beat
	self.duration = duration
	self.line_index = line_index
	self.line_layer = line_layer
	self.width = width
	self.height = height
	self.custom_data = custom_data
	self.type = type

static func new_v2(obstacle_dict: Dictionary) -> ObstacleInfo:
	var y: int = 0
	var h: int = 0
	if int(Utils.get_float(obstacle_dict, "_type", 0)) == 0:
		y = 0
		h = 5
	if int(Utils.get_float(obstacle_dict, "_type", 0)) == 1:
		y = 2
		h = 3
	if int(Utils.get_float(obstacle_dict, "_type", 0)) >= 2:
		y = int(Utils.get_float(obstacle_dict, "_lineLayer", 0))
		h = int(Utils.get_float(obstacle_dict, "_height", 0))
	return ObstacleInfo.new(
		Utils.get_float(obstacle_dict, "_time", 0.0), 
		Utils.get_float(obstacle_dict, "_duration", 0.0), 
		int(Utils.get_float(obstacle_dict, "_lineIndex", 0)), 
		y, 
		int(Utils.get_float(obstacle_dict, "_width", 0)), 
		h, 
		Utils.get_dict(obstacle_dict, "_customData", {}), 
		int(Utils.get_float(obstacle_dict, "_type", 0))
	)

static func new_v3(obstacle_dict: Dictionary) -> ObstacleInfo:
	return ObstacleInfo.new(
		Utils.get_float(obstacle_dict, "b", 0.0), 
		Utils.get_float(obstacle_dict, "d", 0.0), 
		int(Utils.get_float(obstacle_dict, "x", 0)), 
		int(Utils.get_float(obstacle_dict, "y", 0)), 
		int(Utils.get_float(obstacle_dict, "w", 0)), 
		int(Utils.get_float(obstacle_dict, "h", 0)), 
		Utils.get_dict(obstacle_dict, "_customData", {}), 
		int(Utils.get_float(obstacle_dict, "_type", 0))
	)
