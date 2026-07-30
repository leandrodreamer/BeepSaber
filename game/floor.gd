extends StaticBody3D
class_name Floor

var left_last_position := Vector2(0,-50)
var right_last_position := Vector2(0,-50)

var C_LEFT := Color()
var C_RIGHT := Color()

@onready var sub_viewport := $SubViewport as SubViewport
@onready var color_rect := $SubViewport/ColorRect as ColorRect
@onready var burn_l := $SubViewport/ColorRect/burn_l as Node2D
@onready var burn_r := $SubViewport/ColorRect/burn_r as Node2D
@onready var l_sprite := $SubViewport/ColorRect/burn_l/sprite as Panel
@onready var r_sprite := $SubViewport/ColorRect/burn_r/sprite as Panel
@onready var timer_clear := $TimerClear as Timer
const mixed_reality_burn_alpha := 0.3

var is_disabled := false

func _ready() -> void:
	var material := ($Node3D/cutFloor as MeshInstance3D).material_override as StandardMaterial3D
	sub_viewport.transparent_bg = Settings.mixed_reality
	material.albedo_texture = sub_viewport.get_texture()
	material.emission_texture = sub_viewport.get_texture()
	
	if OS.get_name() == &"Web":
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		is_disabled = true
		
func update_left_color(color: Color) -> void:
	C_LEFT = color
	burn_l.modulate = color*6
	if Settings.mixed_reality:
		burn_l.modulate.a = mixed_reality_burn_alpha

func update_right_color(color: Color) -> void:
	C_RIGHT = color
	burn_r.modulate = color*6
	if Settings.mixed_reality:
		burn_r.modulate.a = mixed_reality_burn_alpha

var left_is_out := false
var right_is_out := false
func burn_mark(pos:=Vector3(0,0,-50),type:=0) -> void:
	if is_disabled:
		return
	var newpos := Vector2(
		(pos.x+1)*256,
		pos.z*256
	)

	var burn_mark_sprite: Node2D
	var burn_mark_sprite_long: Panel
	var dist: float

	if type == 0:
		burn_mark_sprite = burn_l
		burn_mark_sprite_long = l_sprite
		left_is_out = false
		burn_mark_sprite.rotation = newpos.angle_to_point(left_last_position)
		dist = left_last_position.distance_to(newpos)
	elif type == 1:
		burn_mark_sprite = burn_r
		burn_mark_sprite_long = r_sprite
		right_is_out = false
		burn_mark_sprite.rotation = newpos.angle_to_point(right_last_position)
		dist = right_last_position.distance_to(newpos)
	else:
		return
	var was_out := !burn_mark_sprite.visible
	burn_mark_sprite.visible = true
	
	burn_mark_sprite.position = newpos
	
	burn_mark_sprite.rotation_degrees += 180
	if dist > 12 and not was_out:
		burn_mark_sprite_long.size.x = dist+12
	else:
		burn_mark_sprite_long.size.x = 24
	
	if type == 0:
		left_last_position = newpos
	elif type == 1:
		right_last_position = newpos

func _process(_delta: float) -> void:
	if left_is_out:
		burn_l.visible = false
	if right_is_out:
		burn_r.visible = false
	left_is_out = true
	right_is_out = true

func _on_timer_clear_timeout() -> void:
	color_rect.self_modulate.a = 1
	await get_tree().process_frame
	color_rect.self_modulate.a = 0
	timer_clear.start()
