extends Node3D
class_name Wall

var despawn_z: float
var speed: float
var _mat: ShaderMaterial
var testforLayer = 0
@export var wallType : int
@export var wallWidth : float
const wallYOffset = 3.0

func _ready():
	var mi: = $WallMeshOrientation / WallMesh as MeshInstance3D
	_mat = mi.material_override as ShaderMaterial

func _physics_process(delta: float) -> void :
	if Scoreboard.paused: return
	transform.origin.z += speed * delta


	if transform.origin.z > despawn_z:
		queue_free()

func spawn(wall_info: ObstacleInfo, current_beat: float, color: Color) -> void :

	$WallMeshOrientation / WallMesh.material_override.set_shader_parameter(&"albedo_color", color)
	var mesh: = $WallMeshOrientation / WallMesh as MeshInstance3D
	var m: = mesh.mesh as BoxMesh
	var shape: = ($WallMeshOrientation / WallArea / CollisionShape3D as CollisionShape3D).shape as BoxShape3D
	if wall_info.line_layer == 0:
		testforLayer += 1



	wallWidth = wall_info.width
	var wallHeight = wall_info.height
	wallType = wall_info.type
	var startHeight = 0
	name = str(wallType)
	if Constants.usingMappingExtension:
		if wallWidth >= 1000 or wallWidth <= -1000:
			if wallWidth >= 1000 and wallWidth <= 4000:
				wallWidth = (wallWidth - 1000) / 1000.0
			elif wallWidth >= 4001 and wallWidth <= 4005000:
				#pass #do nothing?
				wallWidth /= 1000
			elif wallWidth <= -1000:
				wallWidth = ((wallWidth + 2000) - 1000) / 1000.0
		
		
		
		wallHeight = PostfixWallHeight(wallType, wallHeight)
		wallHeight = PrefixWallHeight(wallType, wallHeight, wall_info.line_layer, wall_info.height)
		startHeight = PostfixstartHeight(wallType, startHeight)
		
		wallHeight = wallHeight / 1000.0 * 5 * 1000 + 1000
		# Convert values to match game world scale
		wallHeight = ((wallHeight / 1000.0) * 5.0) #/ 10000.0
		startHeight = ((startHeight / 1000.0) * 5.0) #/ 10000.0  # Convert start height
		
		var wallCheckedType = PostfixWallType(wall_info.type, wallHeight, startHeight)
		
		print("before ", wall_info.type,",",wall_info.height,",",wallHeight,",",startHeight,",",wall_info.width)
		#HOW DO I GET YOU TO ONLY ACTIVATE IF IT IS ULTRA PERSISION MODE?????
		if wallCheckedType >= 1000:
			wallHeight = (wallHeight * 1000.0 + startHeight + 4001) / 10000.0
			wallHeight /= 4
		print("after ",wallCheckedType,",",wall_info.height,",",wallHeight * Constants.LANE_DISTANCE,",",startHeight,",",wallWidth)



	var x = wallWidth * Constants.LANE_DISTANCE
	var y = wallHeight * Constants.LANE_DISTANCE
	var z = wall_info.duration * Constants.BEAT_DISTANCE

	var depth = z * 0.5
	m.size.x = x
	shape.size.x = x
	m.size.y = y
	shape.size.y = y
	m.size.z = z
	shape.size.z = z
	#print(m.size.y)
	despawn_z = Constants.MISS_Z + depth
	(mesh.material_override as ShaderMaterial).set_shader_parameter(&"size", Vector3(x, y, z))
	
	#walls placement for mapping extensions
	if wall_info.line_index > 3 or wall_info.line_index < 0 or wall_info.line_layer > 2 or wall_info.line_layer < 0:
		var wallLineIndex = wall_info.line_index
		var wallLayerIndex = wall_info.line_layer
		var leftSide = false
		var flipLineIndex = wallLineIndex * -1
		var newLaneCount = 1000
		if wallLineIndex >= 1000 or wallLineIndex <= -1000:
			if sign(wall_info.line_index) == 1:
				transform.origin.x = ((wall_info.line_index - ((4 - wallWidth * 2)) - 1000) / 1000.0) - 1.5
				
			else:
				transform.origin.x = ((wall_info.line_index - ((4 - wallWidth * 2)) + 1000) / 1000.0) - 1.5
			transform.origin.x += (wallWidth * 0.5)
			#Y axix placement is broken for most walls
			transform.origin.y = (startHeight * 0.1) * 0.75
			#print(wallHeight,",",startHeight)
		else:
			transform.origin.x = (wall_info.line_index - ((4 - wallWidth) * 0.5)) * Constants.LANE_DISTANCE
			transform.origin.y = (wall_info.line_layer + (wallHeight * 0.5)) * Constants.LANE_DISTANCE
		transform.origin.z = - (wall_info.beat - current_beat) * Constants.BEAT_DISTANCE
	else:
		transform.origin.x = (wall_info.line_index - ((4 - wallWidth) * 0.5)) * Constants.LANE_DISTANCE
		transform.origin.y = (wall_info.line_layer + (wallHeight * 0.5)) * Constants.LANE_DISTANCE
		transform.origin.z = (current_beat - wall_info.beat) * Constants.BEAT_DISTANCE - depth
	speed = Constants.BEAT_DISTANCE * Map.current_info.beats_per_minute / 60.0
	($AnimationPlayer as AnimationPlayer).play(&"Spawn")


func PostfixWallHeight(wallType, wallHeight):
	if wallType < 1000 or wallType > 4005000:
		return wallHeight
	
	if wallType >= 4001 and wallType <= 4005000:
		wallType -= 4001
		wallHeight = wallType / 1000.0
	else:
		wallHeight -= 1000
	return wallHeight / 1000.0 * 5 * 1000 + 1000

func PostfixstartHeight(wallType, startHeight):
	if wallType < 1000 or wallType > 4005000:
		return startHeight
	if wallType >= 4001 and wallType <= 4005000:
		wallType -= 4001
		startHeight = fmod(wallType - 4001, 1000)
	return startHeight / 750.0 * 5 * 1000 + 1334

func PrefixWallHeight(wallType, wallHeight, line_layer, height):
	if !Constants.usingMappingExtension:
		return wallHeight
	#get spawn data
	if height <= -1000:
		wallHeight = (height + 2000) / 1000
	if height >= 1000:
		wallHeight = (height - 1000) / 1000
	if height > 2:
		wallHeight = height
	
	return wallHeight * line_layer
	#FIND OUT WHAT StaticBeatmapObjectSpawnMovementData IS!!

func PostfixWallType(wallType, wallHeight, startHeight):
	if wallType >= 4001:
		wallType = wallHeight / 1000.0 - startHeight - 4001
		return wallType * sign(wallType)
	return wallType
	
