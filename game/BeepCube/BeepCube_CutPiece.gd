extends RigidBody3D
class_name CutPiece

# structure of nodes that represent a cut piece of a cube (ie. one half)
static var cube_phys_mat := load("res://game/BeepCube/BeepCube_Cut.phymat") as PhysicsMaterial
var mesh := MeshInstance3D.new()
var coll := CollisionShape3D.new()
var lifetime: float = 0.0
var parent_cube : Node3D = null

func _init(parent: Node3D, mesh_in: Mesh, mat_in: ShaderMaterial, bouncy: bool) -> void:
	parent_cube = parent
	
	# cut pieces will reside inside of their parent_cube's node tree, but we want
	# them to move independently, thus setting their transform to be 'top_level'
	parent_cube.add_child(self)
	top_level = true
	
	add_to_group(&"cutted_cube")
	mat_in.set_shader_parameter(&"cutted", true)
	collision_layer = 0
	collision_mask = CollisionLayerConstants.Floor_mask
	gravity_scale = 1
	if bouncy:
		# set a physics material for some more bouncy behaviour
		physics_material_override = cube_phys_mat
	
	mesh.mesh = mesh_in
	mesh.layers = 3 # visible to both spectator and player
	mesh.material_override = mat_in
	
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.25, 0.25, 0.125)
	coll.shape = shape
	
	add_child(coll)
	add_child(mesh)
	
	hide_piece()

func start_cut_plane(normal: Vector3, dist: float) -> void:
	# re-enable our process_mode first otherwise it seems like Godot-internals
	# can behave weirdly (ex. AnimationPlayer won't always play correctly)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var s := Settings.block_size / 100.
	mesh.scale = Vector3(s,s,s)
	lifetime = 0.0
	visible = true
	angular_velocity = Vector3()
	linear_velocity = Vector3()
	
	normal = normal.rotated(Vector3(0,0,1), -parent_cube.rotation.z) # ARP: fix rot
	mesh.material_override.set_shader_parameter(&"cut_plane_normal", normal)
	if dist > .25:
		dist = .25 
	elif dist < -.25:
		dist = -.25
	mesh.material_override.set_shader_parameter(&"cut_plane_dist", dist) 

func set_color(new_color: Color, is_dot: bool) -> void:
	mesh.material_override.set_shader_parameter(&"color", new_color)
	mesh.material_override.set_shader_parameter(&"is_dot", is_dot)
	mesh.material_override.set_shader_parameter(&"arrows_enabled", Settings.arrows_enabled)
	
func set_chain_head(is_chain_head: bool) -> void:
	mesh.material_override.set_shader_parameter(&"is_chain_head", is_chain_head)

func hide_piece():
	visible = false
	# disable processing on this node and all children to help with performance
	process_mode = Node.PROCESS_MODE_DISABLED

const MAX_LIFETIME := 0.3;

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime > MAX_LIFETIME:
		parent_cube._on_cut_piece_died()
		hide_piece()
	else:
		# the "cut_vanish" shader parameter controls how faded-out the
		# piece is. 0.0 is not faded out at all, and higher numbers make it
		# more faded. we use ease() with a curve arguments of 2.0 which starts
		# the fade slowly, but then ramps up more quickly toward the end of the
		# lifetime. see this reddit post for a visual of ease() curve values.
		# https://forum.godotengine.org/t/how-do-i-properly-use-the-ease-function/20396/2
		var fade := lifetime / MAX_LIFETIME
		mesh.material_override.set_shader_parameter(&"cut_vanish",ease(fade,2.0)*0.5)
