extends PooledNode3D
class_name Cuttable

var speed: float
var beat: float
var lane_rotation := 0.

# used to release the cube once both of it's cut pieces have died off
# Note: serves no purpose for bombs
var _piece_death_count := 0

# overridden by bombs and cubes
@warning_ignore("unused_parameter")
func set_collision_disabled(value: bool) -> void:
	return

# overriden by bombs and cubes
@warning_ignore("unused_parameter")
func cut(saber: LightSaber, cut_speed: Vector3, cut_plane: Plane, controller: BeepSaberController) -> void:
	return

# this too
func on_miss() -> void:
	return

func _on_cut_piece_died():
	_piece_death_count += 1
	if _piece_death_count >= 2:
		release()
		
func add_lane_rotation(angle):
	var c := cos(angle)
	var s := sin(angle)
	
	var x := transform.origin.x
	var z := transform.origin.z
	transform.origin.x = c * x - s * z
	transform.origin.z = s * x + c * z
	
	rotation.y = -angle
	
	lane_rotation = angle

func _physics_process(delta: float) -> void:
	if Scoreboard.paused or not is_visible_in_tree() or not Map.current_info: return
	
	transform.origin += speed * delta * transform.basis.orthonormalized().z
	var rz := global_transform.origin.dot(transform.basis.orthonormalized().z)
	
	if rz > -3.0:
		set_collision_disabled(false)
	if rz > Constants.MISS_Z:
		on_miss()

	# enable collisions when cuttable gets close enough to player
	#if global_transform.origin.z > -3.0:
	#	set_collision_disabled(false)
	
	# remove children that go to far
	#if global_transform.origin.z > Constants.MISS_Z:
	#	on_miss()

	#var rz := global_transform.rotated(Vector3(0,1,0), -rotation.y).origin.z
