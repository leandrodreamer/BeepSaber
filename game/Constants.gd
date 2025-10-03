extends Node

const LANE_ZERO_X := -0.9
const LAYER_ZERO_Y := 0.8
const BEAT_DISTANCE := 4.0
const LANE_DISTANCE := 0.6
const MISS_Z := 2.5
var CUBE_ROTATIONS := PackedFloat64Array([PI, 0.0, -TAU*0.25, TAU*0.25, -TAU*0.375, TAU*0.375, -TAU*0.125, TAU*0.125, 0.0])
var ROTATION_UNIT_VECTORS := PackedVector2Array([
	Vector2(0, 1), Vector2(0, -1), Vector2(-1, 0), Vector2(1, 0),
	Vector2(-0.70710678, 0.70710678), Vector2(0.70710678, 0.70710678),
	Vector2(-0.70710678, -0.70710678), Vector2(0.70710678, -0.70710678), Vector2(0,1)
])
const APPDATA_PATH := "user://OpenSaber/"

var usingMappingExtension = false
var usingNoodleExtension = false
var usingChroma = false
var usingVivify = false
