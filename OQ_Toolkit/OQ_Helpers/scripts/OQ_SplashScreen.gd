extends Node3D

var current_position: Vector3
var move_position: Vector3
var distance := 3.0
var time_to_move := 0.5
var time_remaining := 3.0

@export var camera: Node3D
@onready var opensaber_material := ($opensaber as MeshInstance3D).material_override as StandardMaterial3D
@onready var godot_material := ($Godot as MeshInstance3D).material_override as StandardMaterial3D
@onready var view_blocker := $ViewBlocker as MeshInstance3D
@onready var view_blocker_material := view_blocker.material_override as StandardMaterial3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var viewDir := -camera.global_transform.basis.z
	var camPos := camera.global_transform.origin
	current_position = camPos + viewDir * distance
	move_position = current_position
	
	look_at_from_position(current_position, camPos, Vector3(0,1,0))
	
	($DebugLabel as Node3D).visible = OS.is_debug_build()
	
var moving := false
var move_timer := 0.0

func _process(dt: float) -> void:
	time_remaining -= dt
	if time_remaining < 0.0:
		queue_free()
		return
	elif time_remaining < 1.0:
		opensaber_material.albedo_color.a = time_remaining
		godot_material.albedo_color.a = time_remaining
		view_blocker_material.albedo_color.a = time_remaining
	
	var view_dir := -camera.global_transform.basis.z
	view_dir.y = 0.0
	view_dir = view_dir.normalized()
	
	var cam_pos := camera.global_transform.origin
	
	#TODO: rotate instead of move
	var target_position := cam_pos + view_dir * distance
	var dist_to_target := (target_position - current_position).length()
	if moving:
		current_position = current_position + (move_position - current_position) * dt
		if dist_to_target < 0.05:
			moving = false
	
	if dist_to_target > 0.5:
		move_timer += dt
	else:
		move_timer = 0.0
	
	if (move_timer > time_to_move):
		moving = true
		move_position = target_position
	
	look_at_from_position(current_position, cam_pos, Vector3(0,1,0))
	view_blocker.global_position = cam_pos
