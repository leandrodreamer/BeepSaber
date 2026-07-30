extends RefCounted
class_name ChainInfo

var color: int
var head_beat: float
var head_line_index: float
var head_line_layer: float
var head_cut_angle: float
var tail_beat: float
var tail_line_index: float
var tail_line_layer: float
var slice_count: int
var squish_factor: float
var rotation: float

@warning_ignore("shadowed_variable")
func _init(
	color: int, head_beat: float, head_line_index: float, head_line_layer: float,
	head_cut_angle: float, tail_beat: float, tail_line_index: float,
	tail_line_layer: float, slice_count: int, squish_factor: float,
	rotation_degrees: float
) -> void:
	self.color = Utils.adjust_color(color)
	self.head_beat = head_beat
	self.head_line_index = Utils.adjust_horizontal(head_line_index)
	self.head_line_layer = Utils.adjust_vertical(head_line_layer)
	self.head_cut_angle = head_cut_angle
	self.tail_beat = tail_beat
	self.tail_line_index = Utils.adjust_horizontal(tail_line_index)
	self.tail_line_layer = Utils.adjust_vertical(tail_line_layer)
	self.slice_count = slice_count
	self.squish_factor = squish_factor
	self.rotation = Utils.adjust_lane_rotation(rotation_degrees * (PI/180.))
	if abs(Settings.gradual_rotation) > 1e-5:
		self.rotation += Settings.gradual_rotation * head_beat


static func new_v3(chain_dict: Dictionary) -> ChainInfo:
	return ChainInfo.new(
		int(Utils.get_float(chain_dict, "c", 0)),
		Utils.get_float(chain_dict, "b", 0.0),
		Utils.precise_measurement(Utils.get_float(chain_dict, "x", 0)),
		Utils.precise_measurement(Utils.get_float(chain_dict, "y", 0)),
		Utils.precise_angle_rad(Utils.get_float(chain_dict, "d", 0), Utils.get_float(chain_dict, "a", 0)),
		Utils.get_float(chain_dict, "tb", 0.0),
		Utils.precise_measurement(Utils.get_float(chain_dict, "tx", 0)),
		Utils.precise_measurement(Utils.get_float(chain_dict, "ty", 0)),
		int(Utils.get_float(chain_dict, "sc", 0)),
		Utils.get_float(chain_dict, "s", 1.0),
		Utils.get_float(chain_dict, "r", 0)
	)
