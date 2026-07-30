extends Node3D
class_name Arc

static var left_material := load("res://game/Arc/Arc.material").duplicate() as ShaderMaterial
static var right_material := left_material.duplicate() as ShaderMaterial

static var left_material_magnet := left_material.duplicate() as ShaderMaterial
static var right_material_magnet := right_material.duplicate() as ShaderMaterial

@onready var visual: CSGPolygon3D = $Path3D/Visual

var arc_info: ArcInfo
var activator_cube: BeepCube

var speed: float
var despawn_z: float

func spawn(info: ArcInfo, current_beat: float, _activator_cube: BeepCube = null) -> void:
	arc_info = info
	
	if abs(arc_info.head_rotation-arc_info.tail_rotation) > Constants.ROTATION_EPS: # or abs(arc_info.tail_rotation) > Constants.ROTATION_EPS:
		# TODO: arcs will twist if rotations are different
		queue_free()
		return
	
	speed = Constants.BEAT_DISTANCE * Map.current_info.beats_per_minute * 0.016666666666666667
	var path := $Path3D as Path3D
	visual = $Path3D/Visual
	visual.material_override = right_material if arc_info.color == 1 else left_material
	activator_cube = _activator_cube
	if activator_cube:
		activator_cube.cutted.connect(_on_activator_cube_cutted)
	else:
		start_magnet()
	
	path.set_curve(info.curve)
	despawn_z = Constants.MISS_Z - info.tail_pos.z - current_beat*Constants.BEAT_DISTANCE
	
	path.set_curve(arc_info.curve)
	# sets the origin of the tail at the tail point to use in the shader for a fade out effect
	path.position =  info.tail_pos + Vector3(0,0,current_beat*Constants.BEAT_DISTANCE)
	rotation.y = -arc_info.head_rotation

func _on_activator_cube_cutted(correct_saber: bool) -> void:
	if activator_cube and activator_cube.cutted.is_connected(_on_activator_cube_cutted):
		activator_cube.cutted.disconnect(_on_activator_cube_cutted)
	if correct_saber:
		start_magnet()

# sets the magnet version of the material (and ensures correct magnet parameter)
func start_magnet() -> void:
	visual.material_override = right_material_magnet if arc_info.color == 1 else left_material_magnet
	visual.material_override.set_shader_parameter(&"saber_magnet", arc_info.color+1)

func _process(delta: float) -> void:
	if Scoreboard.paused or not is_visible_in_tree() or not Map.current_info: return
	transform.origin += speed * delta * transform.basis.z
	if transform.origin.dot(transform.basis.z) >= despawn_z:
		if activator_cube and activator_cube.cutted.is_connected(_on_activator_cube_cutted):
			activator_cube.cutted.disconnect(_on_activator_cube_cutted)
		queue_free()
