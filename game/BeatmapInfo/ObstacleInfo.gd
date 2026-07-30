extends RefCounted
class_name ObstacleInfo

var beat: float
var duration: float
var line_index: float
var line_layer: float
var width: float
var height: float
var rotation: = 0.

@warning_ignore("shadowed_variable")
func _init(beat: float, duration: float, line_index: float, line_layer: float, 
		width: float, height: float, rotation_degrees: float) -> void:
	self.beat = beat
	self.duration = duration
	self.width = width
	if Settings.flip & Constants.FLIP_HORIZONTAL:
		self.line_index = (3+1)-line_index-width
	else:
		self.line_index = line_index
	self.height = height
	if Settings.flip & Constants.FLIP_VERTICAL:
		self.line_layer = (2+1)-line_layer-height
	else:
		self.line_layer = line_layer
	self.rotation = Utils.adjust_lane_rotation(rotation_degrees * (PI/180.))
	if abs(Settings.gradual_rotation) > 1e-5:
		self.rotation += Settings.gradual_rotation * beat

static func new_v2(obstacle_dict: Dictionary) -> ObstacleInfo:
	var y: float = 0
	var h: float = 0
	match int(Utils.get_float(obstacle_dict, "_type", 0)):
		0: # full height
			y = 0
			h = 5
		1: # crouch
			y = 2
			h = 3
		2: # free
			y = Utils.precise_measurement(Utils.get_float(obstacle_dict, "_lineLayer", 0))
			h = Utils.precise_measurement(Utils.get_float(obstacle_dict, "_height", 0))
	return ObstacleInfo.new(
		Utils.get_float(obstacle_dict, "_time", 0.0),
		Utils.get_float(obstacle_dict, "_duration", 0.0),
		Utils.precise_measurement(Utils.get_float(obstacle_dict, "_lineIndex", 0)),
		y,
		Utils.precise_measurement(Utils.get_float(obstacle_dict, "_width", 0)),
		h,
		Utils.get_float(obstacle_dict, "r", 0)
	)

static func new_v3(obstacle_dict: Dictionary) -> ObstacleInfo:
	return ObstacleInfo.new(
		Utils.get_float(obstacle_dict, "b", 0.0),
		Utils.get_float(obstacle_dict, "d", 0.0),
		Utils.precise_measurement(Utils.get_float(obstacle_dict, "x", 0)),
		Utils.precise_measurement(Utils.get_float(obstacle_dict, "y", 0)),
		Utils.precise_measurement(Utils.get_float(obstacle_dict, "w", 0)),
		Utils.precise_measurement(Utils.get_float(obstacle_dict, "h", 0)),
		Utils.get_float(obstacle_dict, "r", 0)
	)
