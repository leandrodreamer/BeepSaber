extends Node

signal score_changed()
signal points_awarded(position: Vector3, rotation: float, amount: String)

var points: int
var combo: int
var multiplier: int
var in_wall: bool
var right_notes: float
var wrong_notes: float
var full_combo: bool
var paused: bool
var last_in_wall_time: float

func restart() -> void:
	last_in_wall_time = -1000.
	points = 0
	multiplier = 1
	combo = 0
	right_notes = 0.0
	wrong_notes = 0.0
	full_combo = true
	in_wall = false
	score_changed.emit()

func reset_combo(wrong_note) -> void:
	var changed = false
	if multiplier != 1:
		multiplier = 1
		changed = true
	if combo != 0:
		combo = 0
		changed = true
	if wrong_note:
		wrong_notes += 1.0
		changed = true
	if full_combo:
		full_combo = false
		changed = true
	if changed:
		score_changed.emit()
	
func enter_wall() -> void:
	var beat : float
	var time := GlobalReferences.main_game_scene.get_current_time()
	if last_in_wall_time < 0:
		GlobalReferences.main_game_scene.update_health(Constants.HEALTH_OBSTACLE_PER_SECOND *.1)
		last_in_wall_time = time
	elif time > 0 and last_in_wall_time >= 0 and last_in_wall_time + 0.1 <= time:
		GlobalReferences.main_game_scene.update_health(Constants.HEALTH_OBSTACLE_PER_SECOND *(time-last_in_wall_time))
		last_in_wall_time = time
	in_wall = true
	reset_combo(false)

func exit_wall() -> void:
	in_wall = false
	last_in_wall_time = -1000.

func add_points(position: Vector3, _rotation: float, amount: int, comment: String = "") -> void:
	if amount > 0:
		GlobalReferences.main_game_scene.update_health(Constants.HEALTH_HIT)
	
	if not in_wall:
		combo += 1
		@warning_ignore("integer_division")
		multiplier = 1 + mini(combo / 10, 7)
	points += amount * multiplier
	
	points_awarded.emit(position, _rotation, str(amount)+(comment if Settings.explain else ""))
	score_changed.emit()
	# track accuracy percent
	var good = Constants.SWING_GOOD_SCORE if Settings.swing_scoring else Constants.OPENSABER_GOOD_SCORE
	var normalized_points := clampf(float(points)/good, 0.0, 1.0)
	right_notes += normalized_points
	wrong_notes += 1.0-normalized_points
	
func add_swing_score(position: Vector3, _rotation: float, accuracy: float, preswing: float, followthrough: float) -> void:
	var score := int(roundf(accuracy + 
					clampf(preswing/Constants.TARGET_PRESWING_ANGLE,0,1.)*Constants.SWING_PRESWING_SCORE + 
					clampf(followthrough/Constants.TARGET_FOLLOWTHROUGH_ANGLE,0.,1.)*Constants.SWING_FOLLOWTHROUGH_SCORE))
	add_points(position, _rotation, score, "  (%d %d %d)" % [int(roundf(accuracy)),int(roundf(preswing)),int(roundf(followthrough))])

func chain_link_cut(position: Vector3, _rotation: float) -> void:
	add_points(position, _rotation, Constants.SWING_CHAIN_LINK_SCORE if Settings.swing_scoring else Constants.OPENSABER_CHAIN_LINK_SCORE)

func note_cut(saber: LightSaber, position: Vector3, _rotation: float, beat_accuracy: float, cut_angle_accuracy: float, cut_distance_accuracy: float, 
		travel_distance_factor: float, arc_head: bool, arc_tail: bool, chain_head: bool) -> void:
	
	if cut_angle_accuracy >= 1e-10: # and cut_distance_accuracy >= 1e-10:
		if Settings.swing_scoring:
			if chain_head:
				saber.add_chain_head_score(position, _rotation, cut_distance_accuracy * Constants.SWING_ACCURACY_SCORE)
			else:
				# unless we have arc_head, we need to wait for followthrough to finish scoring
				saber.add_score(position, _rotation, cut_distance_accuracy * Constants.SWING_ACCURACY_SCORE, arc_head, arc_tail)
		else:
			# point computation based on the accuracy of the swing
			var points_new := beat_accuracy * Constants.OPENSABER_BEAT_ACCURACY_SCORE
			points_new += cut_angle_accuracy * Constants.OPENSABER_ANGLE_ACCURACY_SCORE
			points_new += cut_distance_accuracy * Constants.OPENSABER_DISTANCE_ACCURACY_SCORE
			points_new += points_new * travel_distance_factor
			points_new = roundf(points_new)
			add_points(position, _rotation, int(points_new))
	else:
		bad_cut(position, _rotation, "bad angle")

func bad_cut(position: Vector3, _rotation: float, description: String) -> void:
	if description == "bomb":
		reset_combo(false)
		GlobalReferences.main_game_scene.update_health(Constants.HEALTH_BOMB)
	elif description == "wrong saber" or description == "miss":
		reset_combo(true)
		GlobalReferences.main_game_scene.update_health(Constants.HEALTH_MISS)
		if description == "miss":
			description = ""
	else:
		reset_combo(true)
		GlobalReferences.main_game_scene.update_health(Constants.HEALTH_BAD_CUT)
	points_awarded.emit(position, _rotation, description if Settings.explain else "x")
