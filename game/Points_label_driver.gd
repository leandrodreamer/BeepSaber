extends Node3D
class_name PointsLabelDriver


var points_label := [null, null, null, null]
var current_point_label :int = 0


func _ready():
	var points_label_ref := preload("res://game/points_label.tscn")
	for i in range(0,4):
		var instance := points_label_ref.instantiate()
		points_label[i] = instance
		add_child(instance)

func show_points(_position: Vector3, _rotation: float, value: String):
	if value == "0":
		value = "x"
	var color := Color(1,0,0) if value == "x" else Color(1,1,1)
	points_label[current_point_label].show_points(_position,_rotation,value,color)
	current_point_label += 1
	current_point_label %= 4
