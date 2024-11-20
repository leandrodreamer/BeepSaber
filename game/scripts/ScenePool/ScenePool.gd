extends Node
class_name BeepCubePool

# emitted when the pool intances a scene for the first time
signal scene_instanced(cube: BeepCube)

var scene := load("res://game/BeepCube/BeepCube.tscn") as PackedScene
var _free_list: Array[BeepCube] = []

func _ready() -> void:
	print("creating initial cube pool")
	await get_tree().process_frame
	var init_cubes: Array[BeepCube] = []
	const pre_pool := 100
	for pp in pre_pool:
		var cube := acquire()
		cube.visible = true
		cube.position.z = -2
		init_cubes.append(cube)
		if pp%4 == 0:
			await get_tree().process_frame
	#this forces the game to render all of the cubes in a couple of frames to prevent slow downs in the first pool cycle
	for cube in init_cubes:
		cube.release()
	print("cubes in pool: ",_free_list.size())

func acquire() -> BeepCube:
	var cube := _free_list.pop_front() as BeepCube
	if not cube:
		var new_cube := scene.instantiate() as BeepCube
		new_cube.scene_released.connect(_on_scene_released)
		scene_instanced.emit(new_cube)
		cube = new_cube
	return cube

func _on_scene_released(cube: BeepCube) -> void:
	_free_list.push_back(cube)
