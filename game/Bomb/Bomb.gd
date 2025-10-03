extends Cuttable
class_name Bomb

@export var min_speed := 0.5
@onready var collision_shape := $Area3D/CollisionShape3D as CollisionShape3D

func set_collision_disabled(value: bool) -> void:
	collision_shape.disabled = value

@warning_ignore("unused_parameter")
func cut(saber_type: int, cut_speed: Vector3, cut_plane: Plane, controller: BeepSaberController) -> void:
	Scoreboard.bad_cut(transform.origin)
	queue_free()

func on_miss() -> void:
	queue_free()

func spawn(info: BombInfo, current_beat: float) -> void:
	speed = Constants.BEAT_DISTANCE * Map.current_info.beats_per_minute / 60.0
	beat = info.beat
	
	var distance: float = info.beat - current_beat
	
	if info.line_index > 3 or info.line_index < 0 or info.line_layer > 2 or info.line_layer < 0:
		var noteLineIndex = info.line_index
		var noteLayerIndex = info.line_layer
		var leftSide = false
		var flipLineIndex = noteLineIndex * -1
		var newLaneCount = 1000
		if noteLineIndex >= 1000 or noteLineIndex <= -1000:
			if sign(info.line_index) == 1:
				transform.origin.x = (info.line_index / 1000.0) - 2.5
			else:
				transform.origin.x = (info.line_index / 1000.0) - 0.5
			transform.origin.y = (noteLayerIndex - 1000.0) / 1000.0 + Constants.LAYER_ZERO_Y
		else:
			transform.origin.x = (info.line_index * 0.6) + Constants.LANE_ZERO_X
			transform.origin.y = (info.line_layer * 0.6) + Constants.LAYER_ZERO_Y

		transform.origin.z = - (info.beat - current_beat) * Constants.BEAT_DISTANCE
		#if info.cut_direction < 9:
			#rotation.z = Constants.CUBE_ROTATIONS[info.cut_direction] + deg_to_rad(info.angle_offset)
		#else:
			#rotation.z = deg_to_rad((info.cut_direction - 1000) * -1)
	#else:
		#transform.origin.x = Constants.LANE_X[info.line_index]
		#transform.origin.y = Constants.LAYER_Y[info.line_layer]
		#transform.origin.z = - (info.beat - current_beat) * Constants.BEAT_DISTANCE
		#rotation.z = Constants.CUBE_ROTATIONS[info.cut_direction] + deg_to_rad(info.angle_offset)
	
	var anim := $AnimationPlayer as AnimationPlayer
	var anim_speed := Map.current_difficulty.note_jump_movement_speed / 9.0
	anim.speed_scale = maxf(min_speed, anim_speed)
	anim.play(&"Spawn")
