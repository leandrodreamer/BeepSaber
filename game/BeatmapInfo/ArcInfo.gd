extends RefCounted
class_name ArcInfo

const MID_ANCHOR_MODE_STRAIGHT := 0
const MID_ANCHOR_MODE_CLOCKWISE := 1
const MID_ANCHOR_MODE_COUNTERCLOCKWISE := 2

const arc_angle_force := 2.0
const mid_points := 3

var color: int
var head_beat: float
var head_line_index: float
var head_line_layer: float
var head_cut_angle: float
var head_control_point_length_multiplier: float
var tail_beat: float
var tail_line_index: float
var tail_line_layer: float
var tail_cut_angle: float
var tail_control_point_length_multiplier: float
var mid_anchor_mode: int
var head_rotation: float
var tail_rotation: float
var curve: Curve3D
var tail_pos: Vector3
var head_pos: Vector3

@warning_ignore("shadowed_variable")
func _init(
	color: int, head_beat: float, head_line_index: float, head_line_layer: float,
	head_cut_angle: float, head_control_point_length_multiplier: float,
	tail_beat: float, tail_line_index: float, tail_line_layer: float,
	tail_cut_angle: float, tail_control_point_length_multiplier: float,
	mid_anchor_mode: int, head_rotation_degrees: float, tail_rotation_degrees: float
) -> void:
	self.color = Utils.adjust_color(color)
	self.head_beat = head_beat
	self.head_line_index = Utils.adjust_horizontal(head_line_index)
	self.head_line_layer = Utils.adjust_vertical(head_line_layer)
	self.head_cut_angle = head_cut_angle
	self.head_control_point_length_multiplier = head_control_point_length_multiplier
	self.tail_beat = tail_beat
	self.tail_line_index = Utils.adjust_horizontal(tail_line_index)
	self.tail_line_layer = Utils.adjust_vertical(tail_line_layer)
	self.tail_cut_angle = tail_cut_angle
	self.tail_control_point_length_multiplier = tail_control_point_length_multiplier
	self.mid_anchor_mode = mid_anchor_mode
	self.head_rotation = Utils.adjust_lane_rotation(head_rotation_degrees * (PI/180.))
	self.tail_rotation = Utils.adjust_lane_rotation(tail_rotation_degrees * (PI/180.))
	if abs(Settings.gradual_rotation) > 1e-5:
		self.head_rotation += Settings.gradual_rotation * head_beat
		self.tail_rotation += Settings.gradual_rotation * tail_beat
		
	create_curve()
	
func create_curve() -> void:
	head_pos = Vector3(
		Settings.LANE_DISTANCE_X * float(head_line_index) + Settings.LANE_ZERO_X,
		Constants.LANE_DISTANCE_Y * float(head_line_layer) + Constants.LAYER_ZERO_Y,
		-head_beat * Constants.BEAT_DISTANCE
	)
	tail_pos = Vector3(
		Settings.LANE_DISTANCE_X * float(tail_line_index) + Settings.LANE_ZERO_X,
		Constants.LANE_DISTANCE_Y * float(tail_line_layer) + Constants.LAYER_ZERO_Y,
		-tail_beat * Constants.BEAT_DISTANCE
	)	
	
	var head_cut_rotation: Vector2
	var tail_cut_rotation: Vector2
	if head_cut_angle >= Constants.DIRECTION8_COMPARE:
		head_cut_rotation = Vector2.ZERO
	else:
		head_cut_rotation = Utils.rotation_unit_vector(head_cut_angle) * head_control_point_length_multiplier
	if tail_cut_angle >= Constants.DIRECTION8_COMPARE:
		tail_cut_rotation = Vector2.ZERO
	else:
		tail_cut_rotation = -Utils.rotation_unit_vector(tail_cut_angle) * tail_control_point_length_multiplier
		
	curve = Curve3D.new()
	
	curve.add_point(head_pos - tail_pos, Vector3.ZERO, Vector3(head_cut_rotation.x, head_cut_rotation.y, 0.0) * arc_angle_force)
	
	if mid_anchor_mode > 0:
		for midpoint_id in range(mid_points):
			var range : float = (float(midpoint_id+1) / (mid_points+1))
			#var head_rot := Utils.rotation_unit_vector(info.head_cut_angle)
			## TODO: head_rot not used?!
			
			var point_pos :=  head_pos.lerp(tail_pos, range)
			point_pos += Vector3(head_cut_rotation.x, head_cut_rotation.y, 0.0).rotated(Vector3(0,0,1), 
					(
						(PI if Utils.close_angle(head_cut_angle, tail_cut_angle) else TAU)
						*(-range if mid_anchor_mode == 1 else range)
					)
				) * arc_angle_force
			
			curve.add_point(point_pos - tail_pos, Vector3.ZERO, Vector3.ZERO)
		# calculate smooth in out directions after all points have been set
		for smoothpoint_id in range(mid_points):
			var prev_point_pos := curve.get_point_position(smoothpoint_id)
			var current_point_pos := curve.get_point_position(smoothpoint_id + 1)
			var next_point_pos := curve.get_point_position(smoothpoint_id + 2)
			# Calculate vectors to previous and next points and the average direction
			var to_prev := (prev_point_pos - current_point_pos).normalized()
			var to_next := (next_point_pos - current_point_pos).normalized()
			var smooth_dir := (to_next - to_prev).normalized()
			var distance := (prev_point_pos.distance_to(current_point_pos) + 
							current_point_pos.distance_to(next_point_pos)) * 0.25
			curve.set_point_in(smoothpoint_id + 1, smooth_dir * -distance)
			curve.set_point_out(smoothpoint_id + 1, smooth_dir * distance)
	
	curve.add_point(tail_pos - tail_pos, Vector3(tail_cut_rotation.x, tail_cut_rotation.y, 0.0) * arc_angle_force, Vector3.ZERO)

static func new_v2(arc_dict: Dictionary) -> ArcInfo:
	return ArcInfo.new(
		int(Utils.get_float(arc_dict, "_colorType", 0)),
		Utils.get_float(arc_dict, "_headTime", 0.0),
		Utils.precise_measurement(Utils.get_float(arc_dict, "_headLineIndex", 0)),
		Utils.precise_measurement(Utils.get_float(arc_dict, "_headLineLayer", 0)),
		Utils.precise_angle_rad(Utils.get_float(arc_dict, "_headCutDirection", 0.), 0.),
		Utils.get_float(arc_dict, "_headControlPointLengthMultiplier", 1.0),
		Utils.get_float(arc_dict, "_tailTime", 0.0),
		Utils.precise_measurement(Utils.get_float(arc_dict, "_tailLineIndex", 0)),
		Utils.precise_measurement(Utils.get_float(arc_dict, "_tailLineLayer", 0)),
		Utils.precise_angle_rad(Utils.get_float(arc_dict, "_tailCutDirection", 0), 0),
		Utils.get_float(arc_dict, "_tailControlPointLengthMultiplier", 1.0),
		int(Utils.get_float(arc_dict, "_sliderMidAnchorMode", 0)),
		Utils.get_float(arc_dict, "hr", 0),
		Utils.get_float(arc_dict, "tr", 0)
	)

static func new_v3(arc_dict: Dictionary) -> ArcInfo:
	return ArcInfo.new(
		int(Utils.get_float(arc_dict, "c", 0)),
		Utils.get_float(arc_dict, "b", 0.0),
		Utils.precise_measurement(Utils.get_float(arc_dict, "x", 0)),
		Utils.precise_measurement(Utils.get_float(arc_dict, "y", 0)),
		Utils.precise_angle_rad(Utils.get_float(arc_dict, "d", 0), Utils.get_float(arc_dict, "head_angle_offset", 0)),
		Utils.get_float(arc_dict, "mu", 1.0),
		Utils.get_float(arc_dict, "tb", 0.0),
		Utils.precise_measurement(Utils.get_float(arc_dict, "tx", 0)),
		Utils.precise_measurement(Utils.get_float(arc_dict, "ty", 0)),
		Utils.precise_angle_rad(Utils.get_float(arc_dict, "tc", 0), Utils.get_float(arc_dict, "tail_angle_offset", 0)),
		Utils.get_float(arc_dict, "tmu", 1.0),
		int(Utils.get_float(arc_dict, "m", 0)),
		Utils.get_float(arc_dict, "hr", 0),
		Utils.get_float(arc_dict, "tr", 0)
	)
