extends Cuttable
class_name ChainLink

var which_saber: int
var _mesh: Mesh
var _mat: ShaderMaterial
@export var min_speed := 0.5

@onready var mi := $Mesh as MeshInstance3D

var piece_left : CutPiece = null
var piece_right : CutPiece = null

func _ready() -> void:
	_mat = mi.material_override as ShaderMaterial
	_mesh = mi.mesh
	
	# init our cut pieces with unique copies of our own material for reference,
	# and disable "bouncy" physics behavior
	piece_left = CutPiece.new(self, _mesh, _mat.duplicate(true) as ShaderMaterial, false)
	piece_right = CutPiece.new(self, _mesh, _mat.duplicate(true) as ShaderMaterial, false)
	piece_left.set_chain_head(false)
	piece_right.set_chain_head(false)

static func construct_chain(chain_info: ChainInfo, current_beat: float, note_info_refs: Array[ColorNoteInfo], cube_refs: Array[BeepCube]) -> void:
	# instead of just making a new note head for a new chain, beat saber
	# modifies an already-existing note to be the head, which is why we have to
	# do all this garbage with keeping references to other notes that were
	# spawned this frame.
	var i := 0
	while i < note_info_refs.size():
		var info_ref := note_info_refs[i]
		if (
			info_ref.beat == chain_info.head_beat
			and info_ref.line_index == chain_info.head_line_index
			and info_ref.line_layer == chain_info.head_line_layer
		):
			cube_refs[i].make_chain_head()
		i += 1
	
	# the curve of the chain is gotten from a 3-point bezier curve.  the first
	# point is the head position, the last point is the tail position, and the
	# mid point is based on the head and tail points.
	#
	# to get the mid point, draw a straight line from the head note, in the
	# direction the head note is pointing, with length equal to half the length
	# of a straight line from the head to the tail.  the end point of the line
	# you just drew is the mid point of the curve.
	var head_pos := Vector2(
		Settings.LANE_DISTANCE_X * float(chain_info.head_line_index) + Settings.LANE_ZERO_X,
		Constants.LANE_DISTANCE_Y * float(chain_info.head_line_layer) + Constants.LAYER_ZERO_Y
	)
	var tail_pos := Vector2(
		Settings.LANE_DISTANCE_X * float(chain_info.tail_line_index) + Settings.LANE_ZERO_X,
		Constants.LANE_DISTANCE_Y * float(chain_info.tail_line_layer) + Constants.LAYER_ZERO_Y
	)
	var mid_pos := head_pos + Utils.rotation_unit_vector(chain_info.head_cut_angle) * head_pos.distance_to(tail_pos) * 0.5
	i = 1
	while i < chain_info.slice_count:
		var chain_link := GlobalReferences.link_pool.acquire() as ChainLink
		chain_link.spawn(chain_info, current_beat, head_pos, tail_pos, mid_pos, i)
		i += 1

func spawn(chain_info: ChainInfo, current_beat: float, head_pos: Vector2, tail_pos: Vector2, mid_pos: Vector2, link_index: int) -> void:
	# re-enable our process_mode first otherwise it seems like Godot-internals
	# can behave weirdly (ex. AnimationPlayer won't always play correctly)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var color := Map.color_left if chain_info.color == 0 else Map.color_right
	speed = Constants.BEAT_DISTANCE * Map.current_info.beats_per_minute * 0.016666666666666667
	which_saber = chain_info.color
	
	var lerp_factor := float(link_index) / float(chain_info.slice_count - 1) * chain_info.squish_factor
	beat = lerpf(chain_info.head_beat, chain_info.tail_beat, lerp_factor)
	
	var q0 := head_pos.lerp(mid_pos, lerp_factor)
	var q1 := mid_pos.lerp(tail_pos, lerp_factor)
	var bezier_pos := q0.lerp(q1, lerp_factor)
	
	# TODO: USE THIS
	#scale = Vector3(Settings.block_size,Settings.block_size,Settings.block_size)/100.
	
	transform.origin.x = bezier_pos.x
	transform.origin.y = bezier_pos.y
	transform.origin.z = -(beat - current_beat) * Constants.BEAT_DISTANCE
	
	add_lane_rotation(chain_info.rotation)
	
	rotation.z = q0.angle_to_point(q1) - TAU*0.25
	
	# little bit of forgiveness.  if the chain link is more than a meter away
	# from the chain head, its hitbox is extended to halfway between the link
	# and the head.
	var z_distance_from_head := (beat - chain_info.head_beat) * Constants.BEAT_DISTANCE
	if z_distance_from_head > 1.0:
		var collision := $Area3D/CollisionShape3D as CollisionShape3D
		var new_size := z_distance_from_head * 0.5
		(collision.shape as BoxShape3D).size.z = new_size
		collision.transform.origin.z = new_size * 0.5 - 0.25
	
	piece_left.set_color(color, false) # TODO: can it be true?
	piece_right.set_color(color, false)
	_mat.set_shader_parameter(&"color", color)
	
	var anim := $AnimationPlayer as AnimationPlayer
	var anim_speed := Map.current_difficulty.note_jump_movement_speed / 9.0
	anim.speed_scale = maxf(min_speed,anim_speed)
	anim.play(&"Spawn")
	
	mi.visible = true

# call this when clearing the track
func clear_from_track() -> void:
	hide_cube()
	piece_left.hide_piece()
	piece_right.hide_piece()
	if ! is_released():
		release()

func hide_cube() -> void:
	mi.visible = false
	set_collision_disabled(true)
	# disable processing on this node and all children to help with performance
	process_mode = Node.PROCESS_MODE_DISABLED # disable to help with performance

func cut(saber: LightSaber, _cut_speed: Vector3, cut_plane: Plane, _controller: BeepSaberController) -> void:
	#_cut_speed = _cut_speed.rotated(Vector3(0,1,0),-rotation.x)
	if saber.type == which_saber or Map.one_saber or Settings.handedness != 0:
		Scoreboard.chain_link_cut(transform.origin, lane_rotation)
	else:
		Scoreboard.bad_cut(transform.origin, lane_rotation, "wrong saber")
	
	hide_cube()
	if Settings.cube_cuts_falloff:
		_start_cut_pieces(cut_plane)
		# release() will be called by Cuttable class when it sees both pieces die
	else:
		release()# release now instead of waiting for cut pieces to die off

func on_miss() -> void:
	Scoreboard.bad_cut(transform.origin, lane_rotation, "miss")
	hide_cube()
	release()

func set_collision_disabled(value: bool) -> void:
	($Area3D/CollisionShape3D as CollisionShape3D).disabled = value

func _start_cut_pieces(cutplane: Plane) -> void:
	piece_left.global_transform = global_transform
	piece_right.global_transform = global_transform
	
	# calculate angle and position of the cut
	var cut_angle_abs := Vector2(cutplane.normal.x, cutplane.normal.y).angle()
	var cut_dist_from_center := cutplane.distance_to(transform.origin)
	var cut_angle_rel := cut_angle_abs - global_rotation.z
	
	_piece_death_count = 0
	var p := global_transform * cutplane
	piece_left.start_cut_plane(-p.normal, -p.d)
	piece_right.start_cut_plane(p.normal, p.d)

	# some impulse so the cube half moves
	var split_vector := p.normal * 2.0
	piece_left.apply_central_impulse(piece_left.transform * -split_vector)
	piece_right.apply_central_impulse(piece_right.transform * split_vector)
