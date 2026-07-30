extends Node3D

var text_mesh: TextMesh
var player: AnimationPlayer

func _ready():
	player = $AnimationPlayer as AnimationPlayer
	# gotta make a new text mesh for each one, otherwise they will all ref
	# the same one.  the result of that is if you change the text of one, you
	# change the text of all.
	var instance := $mesh_instance as MeshInstance3D
	instance.mesh = instance.mesh.duplicate(true) as TextMesh
	text_mesh = instance.mesh as TextMesh

func show_points(_position: Vector3, _rotation:float, value: String, color: Color):
	global_position = _position
	text_mesh.text = value
	(text_mesh.material as StandardMaterial3D).albedo_color = color
	player.stop()
	player.play("hit")
	rotation.y = -_rotation
