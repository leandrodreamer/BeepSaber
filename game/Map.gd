extends RefCounted
class_name Map

# this would have basically been impossible to figure out without constantly
# referencing the beat saber modding group wiki.
# https://bsmg.wiki/mapping/map-format.html

static var current_info: MapInfo
static var current_difficulty: DifficultyInfo

static var note_stack: Array[ColorNoteInfo]
static var bomb_stack: Array[BombInfo]
static var obstacle_stack: Array[ObstacleInfo]
static var arc_stack: Array[ArcInfo]
static var chain_stack: Array[ChainInfo]
static var event_stack: Array[EventInfo]

static var _color_left: Color
static var _color_right: Color
static var color_left: Color :
	get():
		if Settings.handedness == Constants.HANDEDNESS_FORCE_RIGHT:
			return _color_right
		elif Settings.handedness == Constants.HANDEDNESS_IGNORE:
			return (_color_left+_color_right)/2
		else:
			return _color_left
	set(c):
		_color_left = c
static var color_right: Color :
	get():
		if Settings.handedness == Constants.HANDEDNESS_FORCE_LEFT:
			return _color_left
		elif Settings.handedness == Constants.HANDEDNESS_IGNORE:
			return (_color_left+_color_right)/2
		else:
			return _color_right
	set(c):
		_color_right = c
static var last_beat := 0.
static var one_saber := false

const ROTATIONS_V2 := [ -60., -45., -30., -15., 15., 30., 45., 60. ]
const ROTATE_ALL := 0. # for testing

# some simple multithreading, since larger maps can take a very long time to
# load.  one particulary notable outlier is the beatmap of shrek, which took
# around 48 milliseconds to load before even on a 7800x3d, and now takes around
# 29 milliseconds.  takes just over half as long as before, very worth the
# nightmare code i've written.
#
# long story short, each beatmap-element loading func splits into two threads:
# one for parsing the top half of the array of dicts, and one for parsing the
# bottom half.  these run concurrently, not quite halfing the time, but
# getting pretty close to halfing it.
static var note_thread_0 := Thread.new()
static var note_thread_1 := Thread.new()
static var bomb_thread_0 := Thread.new()
static var bomb_thread_1 := Thread.new()
static var obstacle_thread_0 := Thread.new()
static var obstacle_thread_1 := Thread.new()
static var arc_thread_0 := Thread.new()
static var arc_thread_1 := Thread.new()
static var chain_thread_0 := Thread.new()
static var chain_thread_1 := Thread.new()
static var event_thread_0 := Thread.new()
static var event_thread_1 := Thread.new()

# not officially part of the spec, but used by mods a lot
static func set_colors_from_custom_data() -> void:
	if Settings.disable_map_color:
		Map.color_left = Settings.color_left
		Map.color_right = Settings.color_right
		return
	
	var set_colors := func(data: Dictionary, color_name: String) -> bool:
		var left_name := color_name % "Left"
		var right_name := color_name % "Right"
		if (
			data.has(left_name) and data.has(right_name)
			and data[left_name] is Dictionary and data[right_name] is Dictionary
		):
			@warning_ignore("unsafe_cast")
			var left := data[left_name] as Dictionary
			@warning_ignore("unsafe_cast")
			var right := data[right_name] as Dictionary
			Map.color_left = Color(
				Utils.get_float(left, "r", Settings.color_left.r),
				Utils.get_float(left, "g", Settings.color_left.g),
				Utils.get_float(left, "b", Settings.color_left.b)
			)
			Map.color_right = Color(
				Utils.get_float(right, "r", Settings.color_right.r),
				Utils.get_float(right, "g", Settings.color_right.g),
				Utils.get_float(right, "b", Settings.color_right.b)
			)
			return true
		return false
	var info_data := current_info.custom_data
	var diff_data := current_difficulty.custom_data
	var custom_colors_found := false
	if set_colors.call(info_data, "_envColor%sBoost"): custom_colors_found = true
	if set_colors.call(diff_data, "_envColor%sBoost"): custom_colors_found = true
	if set_colors.call(info_data, "envColor%sBoost"): custom_colors_found = true
	if set_colors.call(diff_data, "envColor%sBoost"): custom_colors_found = true
	if set_colors.call(info_data, "_envColor%s"): custom_colors_found = true
	if set_colors.call(diff_data, "_envColor%s"): custom_colors_found = true
	if set_colors.call(info_data, "envColor%s"): custom_colors_found = true
	if set_colors.call(diff_data, "envColor%s"): custom_colors_found = true
	if set_colors.call(info_data, "_color%s"): custom_colors_found = true
	if set_colors.call(diff_data, "_color%s"): custom_colors_found = true
	if set_colors.call(info_data, "color%s"): custom_colors_found = true
	if set_colors.call(diff_data, "color%s"): custom_colors_found = true
	if not custom_colors_found:
		Map.color_left = Settings.color_left
		Map.color_right = Settings.color_right

static func load_map_info(load_path: String) -> MapInfo:
	var info_dict := {}
	var info_dat := Utils.read_binary_file(load_path, "Info.dat")
	if len(info_dat) == 0:
		info_dat = Utils.read_binary_file(load_path, "info.dat")
		if len(info_dat) == 0:
			info_dat = Utils.read_binary_file(load_path, "INFO.DAT")
	info_dict = Utils.binary_to_json(info_dat)
	if (info_dict.is_empty()):
		vr.log_error("Invalid info.dat found in " + load_path)
		return null
	
	if info_dict.has("_version"):
		return MapInfo.new_v2(info_dict, load_path)
	elif info_dict.has("version"):
		return MapInfo.new_v4(info_dict, load_path)
	else:
		vr.log_warning("%s is an unknown beatmap version" % load_path)
		return null

# speed for the speed gods.  please forgive me for this.
# - steve hocktail
static func load_note_stack_v2(note_data: Array, rotations: Array) -> void:
	var load_range := func(start: int, end: int) -> Array[Array]:
		var note_array: Array[ColorNoteInfo] = []
		var bomb_array: Array[BombInfo] = []
		var i := start
		while i < end:
			if not note_data[i] is Dictionary: continue
			@warning_ignore("unsafe_cast")
			var note_dict := note_data[i] as Dictionary
			var note_type := int(Utils.get_float(note_dict, "_type", -1.0))
			note_dict["r"] = get_rotation(rotations, Utils.get_float(note_dict, "_time", 0.))
			if note_type == 3 and Settings.bombs_enabled:
				bomb_array.append(BombInfo.new_v2(note_dict))
			elif note_type == 0 or note_type == 1:
				note_array.append(ColorNoteInfo.new_v2(note_dict))
			i += 1
		return [note_array, bomb_array]
	var midpoint := note_data.size() >> 1
	#note_thread_1.start(load_range.bind(0, midpoint))
	Utils.custom_thread_call(note_thread_1, load_range, [0, midpoint])
	var total_second_half : Array[Array] = load_range.bind(midpoint, note_data.size()).call()
	#var total_first_half : Array[Array] = note_thread_1.wait_to_finish()
	var total_first_half : Array[Array] = Utils.custom_thread_wait_to_finish(note_thread_1)
	note_stack = total_first_half[0] + total_second_half[0]
	bomb_stack = total_first_half[1] + total_second_half[1]
	note_stack.reverse()
	bomb_stack.reverse()

static func load_obstacle_stack_v2(obstacle_data: Array, rotations: Array) -> void:
	var last_index := obstacle_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if obstacle_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				var o := obstacle_data[i] as Dictionary
				o["r"] = get_rotation(rotations, Utils.get_float(o, "_time", 0.))
				obstacle_stack[last_index - i] = ObstacleInfo.new_v2(o)
			i += 1
	var midpoint := obstacle_data.size() >> 1
	obstacle_stack.resize(obstacle_data.size())
	#obstacle_thread_1.start(load_range.bind(0, midpoint))
	Utils.custom_thread_call(obstacle_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, obstacle_data.size()).call()
	#obstacle_thread_1.wait_to_finish()
	Utils.custom_thread_wait_to_finish(obstacle_thread_1)

static func load_arc_stack_v2(arc_data: Array, rotations: Array) -> void:
	var last_index := arc_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if arc_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				var a := arc_data[i] as Dictionary
				a["hr"] = get_rotation(rotations, Utils.get_float(a, "_time", 0.))
				a["tr"] = a["hr"]
				arc_stack[last_index - i] = ArcInfo.new_v2(a)
			i += 1
	var midpoint := arc_data.size() >> 1
	arc_stack.resize(arc_data.size())
	Utils.custom_thread_call(arc_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, arc_data.size()).call()
	Utils.custom_thread_wait_to_finish(arc_thread_1)
	

static func load_event_stack_v2(event_data: Array) -> void:
	var last_index := event_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if event_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				event_stack[last_index - i] = EventInfo.new_v2(event_data[i] as Dictionary)
			i += 1
	var midpoint := event_data.size() >> 1
	event_stack.resize(event_data.size())
	Utils.custom_thread_call(event_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, event_data.size()).call()
	Utils.custom_thread_wait_to_finish(event_thread_1)
	
static func get_rotation(rotations: Array, beat: float, start := 0, end := -1) -> float:
	if rotations.size() == 0:
		return 0
	if end < 0:
		end = rotations.size() - 1
	if end <= start+1:
		if rotations[end][0] <= beat:
			return rotations[end][1]
		elif rotations[start][0] <= beat:
			return rotations[start][1]
		elif start > 0:
			return rotations[start-1][1]
		else:
			return 0
	var midpoint = (end + start) / 2
	var mt := rotations[midpoint][0] as float
	if mt == beat:
		return rotations[midpoint][1]
	if mt < beat:
		return get_rotation(rotations, beat, midpoint, end)
	else:
		return get_rotation(rotations, beat, start, midpoint)

static func load_note_stack_v3_v4(note_data: Array, meta: Array, rotations: Array) -> void:
	var last_index := note_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if note_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				var n := note_data[i] as Dictionary
				var beat := Utils.get_float(n, "b", 0.)
				n["r"] = Utils.get_float(n, "r", 0.) + get_rotation(rotations, beat)
				var index := int(Utils.get_float(n, "i", -1))
				if 0 <= index and index < meta.size() and meta[index] is Dictionary:
					n.merge(meta[index])
				note_stack[last_index - i] = ColorNoteInfo.new_v3(n as Dictionary)
			i += 1
	var midpoint := note_data.size() >> 1
	note_stack.resize(note_data.size())
	Utils.custom_thread_call(note_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, note_data.size()).call()
	Utils.custom_thread_wait_to_finish(note_thread_1)

static func load_bomb_stack_v3_v4(bomb_data: Array, meta: Array, rotations: Array) -> void:
	if not Settings.bombs_enabled:
		bomb_stack.clear()
		return
	var last_index := bomb_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if bomb_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				var b := bomb_data[i] as Dictionary
				var beat := Utils.get_float(b, "b", 0.)
				b["r"] = Utils.get_float(b, "r", 0.) + get_rotation(rotations, beat)
				var index := int(Utils.get_float(b, "i", -1))
				if 0 <= index and index < meta.size() and meta[index] is Dictionary:
					b.merge(meta[index])
				bomb_stack[last_index - i] = BombInfo.new_v3(b)
			i += 1
	var midpoint := bomb_data.size() >> 1
	bomb_stack.resize(bomb_data.size())
	Utils.custom_thread_call(bomb_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, bomb_data.size()).call()
	Utils.custom_thread_wait_to_finish(bomb_thread_1)

static func load_obstacle_stack_v3_v4(obstacle_data: Array, meta: Array, rotations: Array) -> void:
	var last_index := obstacle_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if obstacle_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				var o := obstacle_data[i] as Dictionary
				var beat := Utils.get_float(o, "b", 0.)
				o["r"] = Utils.get_float(o, "r", 0.) + get_rotation(rotations, beat)
				var index := int(Utils.get_float(o, "i", -1))
				if 0 <= index and index < meta.size() and meta[index] is Dictionary:
					o.merge(meta[index])
				obstacle_stack[last_index - i] = ObstacleInfo.new_v3(o)
			i += 1
	var midpoint := obstacle_data.size() >> 1
	obstacle_stack.resize(obstacle_data.size())
	Utils.custom_thread_call(obstacle_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, obstacle_data.size()).call()
	Utils.custom_thread_wait_to_finish(obstacle_thread_1)

static func load_arc_stack_v3(arc_data: Array, rotations: Array) -> void:
	var last_index := arc_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if arc_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				var a := arc_data[i] as Dictionary
				var beat := Utils.get_float(a, "b", 0.)
				a["hr"] = Utils.get_float(a, "r", 0.) + get_rotation(rotations, beat)
				a["tr"] = a["hr"]
				arc_stack[last_index - i] = ArcInfo.new_v3(arc_data[i] as Dictionary)
			i += 1
	var midpoint := arc_data.size() >> 1
	arc_stack.resize(arc_data.size())
	Utils.custom_thread_call(arc_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, arc_data.size()).call()
	Utils.custom_thread_wait_to_finish(arc_thread_1)

static func load_arc_stack_v4(arc_data: Array, meta: Array, meta_notes: Array) -> void:
	var last_index := arc_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if arc_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				var a := arc_data[i] as Dictionary
				var a3 := {}
				if a.has("hb"):
					a3["b"] = a["hb"] # head beat
				if a.has("tb"):
					a3["tb"] = a["tb"] # tail beat
				var index := int(Utils.get_float(a, "ai", -1))
				if 0 <= index and index < meta.size() and meta[index] is Dictionary:
					a3["mu"] = Utils.get_float(meta[index], "m", 1.)
					a3["tmu"] = Utils.get_float(meta[index], "tm", 1.)
					a3["m"] = Utils.get_float(meta[index], "a", 1.)
				index = int(Utils.get_float(a, "hi", -1))
				if 0 <= index and index < meta_notes.size() and meta_notes[index] is Dictionary:
					var m := meta_notes[index] as Dictionary
					a3["x"] = Utils.get_float(m, "x", 0)
					a3["y"] = Utils.get_float(m, "y", 0)
					a3["c"] = Utils.get_float(m, "c", 0)
					a3["d"] = Utils.get_float(m, "d", 0)
					a3["head_angle_offset"]= Utils.get_float(m, "a", 0)
				index = int(Utils.get_float(a, "ti", -1))
				if 0 <= index and index < meta_notes.size() and meta_notes[index] is Dictionary:
					var m := meta_notes[index] as Dictionary
					a3["tx"] = Utils.get_float(m, "x", 0)
					a3["ty"] = Utils.get_float(m, "y", 0)
					a3["tc"] = Utils.get_float(m, "d", 0)
					a3["tail_angle_offset"]= Utils.get_float(m, "a", 0)
				
				if abs(ROTATE_ALL) > Constants.ROTATION_EPS_DEGREES:
					a3["hr"] = ROTATE_ALL
					a3["tr"] = ROTATE_ALL
				arc_stack[last_index - i] = ArcInfo.new_v3(a3)
			i += 1
	var midpoint := arc_data.size() >> 1
	arc_stack.resize(arc_data.size())
	Utils.custom_thread_call(arc_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, arc_data.size()).call()
	Utils.custom_thread_wait_to_finish(arc_thread_1)

static func load_chain_stack_v4(chain_data: Array, meta: Array, meta_notes: Array) -> void:
	var last_index := chain_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if chain_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				var c := chain_data[i] as Dictionary
				var c3 := {}
				if c.has("hb"):
					c3["b"] = c["hb"] # head beat
				if c.has("tb"):
					c3["tb"] = c["tb"] # tail beat
				var index := int(Utils.get_float(c, "ci", -1))
				if 0 <= index and index < meta.size() and meta[index] is Dictionary:
					c3["tx"] = Utils.get_float(meta[index], "tx", 0.)
					c3["ty"] = Utils.get_float(meta[index], "ty", 0.)
					c3["sc"] = Utils.get_float(meta[index], "c", 0)
					c3["s"] = Utils.get_float(meta[index], "s", 1.)
				index = int(Utils.get_float(c, "i", -1))
				if 0 <= index and index < meta_notes.size() and meta_notes[index] is Dictionary:
					var m := meta_notes[index] as Dictionary
					c3["x"] = Utils.get_float(m, "x", 0)
					c3["y"] = Utils.get_float(m, "y", 0)
					c3["c"] = Utils.get_float(m, "c", 0)
					c3["d"] = Utils.get_float(m, "d", 0)
				chain_stack[last_index - i] = ChainInfo.new_v3(c3)
			i += 1
	var midpoint := chain_data.size() >> 1
	chain_stack.resize(chain_data.size())
	Utils.custom_thread_call(chain_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, chain_data.size()).call()
	Utils.custom_thread_wait_to_finish(chain_thread_1)

static func load_chain_stack_v3(chain_data: Array, rotations: Array) -> void:
	var last_index := chain_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if chain_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				var c := chain_data[i] as Dictionary
				var beat := Utils.get_float(c, "b", 0.)
				c["hr"] = Utils.get_float(c, "r", 0.) + get_rotation(rotations, beat)
				c["tr"] = c["hr"]
				chain_stack[last_index - i] = ChainInfo.new_v3(chain_data[i] as Dictionary)
			i += 1
	var midpoint := chain_data.size() >> 1
	chain_stack.resize(chain_data.size())
	Utils.custom_thread_call(chain_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, chain_data.size()).call()
	Utils.custom_thread_wait_to_finish(chain_thread_1)

static func load_event_stack_v3(event_data: Array) -> void:
	var last_index := event_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if event_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				event_stack[last_index - i] = EventInfo.new_v3(event_data[i] as Dictionary)
			i += 1
	var midpoint := event_data.size() >> 1
	event_stack.resize(event_data.size())
	Utils.custom_thread_call(event_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, event_data.size()).call()
	Utils.custom_thread_wait_to_finish(event_thread_1)
	
static func get_last_beat() -> void:
	current_info.last_beat = 0.
	for note_info in note_stack:
		if note_info.beat + 0.5 > current_info.last_beat:
			current_info.last_beat = note_info.beat + 0.5
	for obstacle in obstacle_stack:
		var beat := obstacle.beat + obstacle.duration
		if beat > current_info.last_beat:
			current_info.last_beat = beat
	for bomb in bomb_stack:
		if bomb.beat > current_info.last_beat:
			current_info.last_beat = bomb.beat
	
static func compare_times(a: Array, b: Array):
	return a[0] < b[0]
			
static func get_rotations_v2(events: Array) -> Array:
	if abs(ROTATE_ALL) > Constants.ROTATION_EPS * 180/PI:
		return [[0.,ROTATE_ALL]]
	var r := []
	var angle := 0.
	for e in events:
		if e is Dictionary:
			var t := Utils.get_float(e, "_time", 0.)
			var type := int(Utils.get_float(e, "_type", 0))
			if type != 14 and type != 15:
				continue
			if type == 15:
				t += 1.e-5
			var index := int(Utils.get_float(e, "_value", -1))
			if index < 0 or index > 7:
				continue
			angle += ROTATIONS_V2[index]
			if angle < 0:
				angle += TAU
			elif angle >= TAU:
				angle -= TAU
			r.append([t, angle])
	r.sort_custom(compare_times)
	return r

static func get_rotations_v3(events: Array) -> Array:
	if abs(ROTATE_ALL) > Constants.ROTATION_EPS * 180 / PI:
		return [[0.,ROTATE_ALL]]
	var r := []
	var angle := 0.
	for e in events:
		if e is Dictionary:
			var t := Utils.get_float(e, "b", 0.)
			if Utils.get_float(e, "e", 0.) > 0:
				t += 1.e-5
			angle += Utils.get_float(e, "r", 0.)
			if angle < 0:
				angle += 360
			elif angle >= 360:
				angle -= 360
			r.append([t, angle])
	r.sort_custom(compare_times)
	return r

static func load_beatmap(info: MapInfo, difficulty: DifficultyInfo, map_data: Dictionary) -> bool:
	# Ensures the map_data dict has a version (some maps include the version only on info but not in the data)
	if !map_data.has("_version") and !map_data.has("version"):
		if info.version.begins_with("2.") or info.version.begins_with("1."):
			map_data["_version"] = info.version
		else:
			map_data["version"] = info.version
	
	if map_data.has("_version"):
		var rotations := get_rotations_v2(Utils.get_array(map_data, "_events", []))
		Utils.custom_thread_call(note_thread_0, load_note_stack_v2, [Utils.get_array(map_data, "_notes", []), rotations])
		Utils.custom_thread_call(obstacle_thread_0, load_obstacle_stack_v2, [Utils.get_array(map_data, "_obstacles", []), rotations])
		Utils.custom_thread_call(event_thread_0, load_event_stack_v2, [Utils.get_array(map_data, "_events", [])])
		Utils.custom_thread_call(arc_thread_0, load_arc_stack_v2, [Utils.get_array(map_data, "_sliders", []), rotations])
		chain_stack.clear()
		current_info = info
		current_info.beats_per_minute *= Settings.music_speed / 100.
		current_difficulty = difficulty
		one_saber = difficulty.characteristic == "OneSaber"
		Map.set_colors_from_custom_data()
		Utils.custom_thread_wait_to_finish(note_thread_0)
		Utils.custom_thread_wait_to_finish(obstacle_thread_0)
		Utils.custom_thread_wait_to_finish(event_thread_0)
		Utils.custom_thread_wait_to_finish(arc_thread_0)
		get_last_beat()
		return true
	elif map_data.has("version"):
		var version := Utils.get_str(map_data, "version", "")
		if version.begins_with("3.") or version.begins_with("4."):
			var v4 := version.begins_with("4.")
			var rotations : Array
			if v4:
				rotations = [] if abs(ROTATE_ALL) <= Constants.ROTATION_EPS_DEGREES else [[0.,ROTATE_ALL]]
			else:
				rotations = get_rotations_v3(Utils.get_array(map_data, "rotationEvents", []))
			Utils.custom_thread_call(note_thread_0, load_note_stack_v3_v4, 
				[Utils.get_array(map_data, "colorNotes", []),
				 Utils.get_array(map_data, "colorNotesData", []) if v4 else [],
				 rotations
				])
			Utils.custom_thread_call(bomb_thread_0, load_bomb_stack_v3_v4, 
				[Utils.get_array(map_data, "bombNotes", []),
				 Utils.get_array(map_data, "bombNotesData", []) if v4 else [],
				 rotations
				])
			Utils.custom_thread_call(obstacle_thread_0, load_obstacle_stack_v3_v4, 
				[Utils.get_array(map_data, "obstacles", []),
				 Utils.get_array(map_data, "obstaclesData", []) if v4 else [],
				 rotations
				])
			if v4:
				Utils.custom_thread_call(arc_thread_0, load_arc_stack_v4, 
					[Utils.get_array(map_data, "arcs", []),
					Utils.get_array(map_data, "arcsData", []),
					Utils.get_array(map_data, "colorNotesData", [])
					])
			else:
				Utils.custom_thread_call(arc_thread_0, load_arc_stack_v3, 
					[Utils.get_array(map_data, "sliders", []), rotations])
			if v4:
				Utils.custom_thread_call(chain_thread_0, load_chain_stack_v4, 
					[Utils.get_array(map_data, "chains", []),
					Utils.get_array(map_data, "chainsData", []),
					Utils.get_array(map_data, "colorNotesData", [])
					])
			else:
				Utils.custom_thread_call(chain_thread_0, load_chain_stack_v3, 
					[Utils.get_array(map_data, "burstSliders", []),
					rotations
					])
			if v4:
				pass #TODO
			else:
				Utils.custom_thread_call(event_thread_0, load_event_stack_v3, [Utils.get_array(map_data, "basicBeatmapEvents", [])])
			current_info = info
			current_info.beats_per_minute *= Settings.music_speed / 100.
			current_difficulty = difficulty
			one_saber = difficulty.characteristic == "OneSaber"
			Map.set_colors_from_custom_data()
			Utils.custom_thread_wait_to_finish(note_thread_0)
			Utils.custom_thread_wait_to_finish(bomb_thread_0)
			Utils.custom_thread_wait_to_finish(obstacle_thread_0)
			Utils.custom_thread_wait_to_finish(arc_thread_0)
			Utils.custom_thread_wait_to_finish(chain_thread_0)
			Utils.custom_thread_wait_to_finish(event_thread_0)
			get_last_beat()
			return true
	vr.log_warning("selected map is an unsupported version")
	return false
