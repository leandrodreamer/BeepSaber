extends Node
class_name HighscoreTable

# location to store the highscores on filesystem
var HIGHSCORES_FILEPATH := Constants.CONFIG_ROOT_PATH + "highscores.json"

# maximum records to store in each song's record table. once list
# grows past this length, the lowest ranking score will get bumped.
const MAX_RECORDS_PER_KEY := 10

# internal copy of the highscore table
# restored from user file in _ready()
# {
#   "<hs_key>" : {# records for a given song
#       "1" : [ # records at diffucultyRank 1
#           {"player_name":"Bob","score":10000,"epoch_time":0}
#           {"player_name":"Alice","score":5000,"epoch_time":0}
#       ],
#       "3" : [ # records at diffucultyRank 3
#           {"player_name":"Bob","score":10000,"epoch_time":0}
#           {"player_name":"Alice","score":5000,"epoch_time":0}
#       ]
#   }
# }
var _hs_table: Dictionary = {}

func _ready() -> void:
	load_hs_table()

# clears the whole highscore table
func clear_table() -> void:
	_hs_table = {}

# removes a given map from the table, effectively resetting that map's records
func remove_map(map_info: MapInfo) -> void:
	var hs_key := map_info.get_key()
	@warning_ignore("return_value_discarded")
	_hs_table.erase(hs_key)
	save_hs_table()
	
# returns true if score is a new highscore in the table, false otherwise
func is_new_highscore(map_info: MapInfo, diff_rank: int, score: int) -> bool:
	if score == 0:
		return false
	var hs_key := map_info.get_key()
	return _is_new_highscore(hs_key, get_rank_key(diff_rank), score)
	
static func get_rank_key(diff_rank: int) -> int:
	diff_rank &= Constants.DIFFICULTY_MASK
	if Settings.health_mode:
		diff_rank |= Constants.DIFFICULTY_HEALTH
	if Settings.arrows_enabled:
		diff_rank |= Constants.DIFFICULTY_ARROWS
	if Settings.bombs_enabled:
		diff_rank |= Constants.DIFFICULTY_BOMBS
	if Settings.claws:
		diff_rank |= Constants.DIFFICULTY_CLAWS
	diff_rank = diff_rank & ~Constants.DIFFICULTY_WIDTH_MASK
	for i in range(Constants.WIDTHS.size()):
		if Settings.width == Constants.WIDTHS[i][0]:
			diff_rank |= Constants.WIDTHS[i][2]
	diff_rank = diff_rank & ~Constants.DIFFICULTY_SPEED_MASK
	for i in range(Constants.SPEEDS.size()):
		if Settings.music_speed == Constants.SPEEDS[i][0]:
			diff_rank |= Constants.SPEEDS[i][2]
	diff_rank = diff_rank & ~Constants.DIFFICULTY_FLIP_MASK
	diff_rank |= Settings.flip << Constants.DIFFICULTY_FLIP_SHIFT
	diff_rank = diff_rank & ~Constants.DIFFICULTY_HANDEDNESS_MASK
	if Settings.handedness == Constants.HANDEDNESS_FORCE_LEFT:
		diff_rank |= Constants.DIFFICULTY_HANDEDNESS_FORCE_LEFT
	elif Settings.handedness == Constants.HANDEDNESS_FORCE_RIGHT:
		diff_rank |= Constants.DIFFICULTY_HANDEDNESS_FORCE_RIGHT
	elif Settings.handedness == Constants.HANDEDNESS_IGNORE:
		diff_rank |= Constants.DIFFICULTY_HANDEDNESS_IGNORE
	return diff_rank
	
static func get_width_from_rank(diff_rank: int) -> int:
	var wr := diff_rank & Constants.DIFFICULTY_WIDTH_MASK
	for ww in Constants.WIDTHS:
		if ww[2] == wr:
			return ww[0]
	return 100
	
static func get_speed_from_rank(diff_rank: int) -> int:
	var sr := diff_rank & Constants.DIFFICULTY_SPEED_MASK
	for ss in Constants.SPEEDS:
		if ss[2] == sr:
			return ss[0]
	return 100
	
# adds a new score record to the table. if the score is not a highscore
# then the record will not be stored.
#
# map_info : data structure as read for map's info.dat file
# diff_rank : difficulty rank (1,3,etc.) that the score was set on
# player_name : string name for the player
# score : integer score to store
#
# return : None
func add_highscore(map_info: MapInfo, diff_rank: int, player_name: String, score: int) -> void:
	# get existing records for song + difficulty
	var hs_key := map_info.get_key()
	diff_rank = get_rank_key(diff_rank)
	var records := _get_records(hs_key,diff_rank)
	
	# construct a new record and resort the list
	var record := _make_record(score,player_name)
	records.append(record)
	records.sort_custom(_highest_and_oldest)
	
	# remove the lowest ranking score
	if records.size() > MAX_RECORDS_PER_KEY:
		records.pop_back()
		
	# store updated records in table
	if not _hs_table.has(hs_key):
		_hs_table[hs_key] = {}
	_hs_table[hs_key][str(diff_rank)] = records
	
	save_hs_table()

# return : the list of records for the given map + difficulty
func get_records(map_info: MapInfo, diff_rank: int) -> Array:
	var hs_key := map_info.get_key()
	return _get_records(hs_key,diff_rank)
	
# return : the overall highscore for the given map + difficulty. -1 is
# returned if no record exist for this song yet
func get_highscore(map_info: MapInfo, diff_rank: int) -> int:
	var hs_key := map_info.get_key()
	var records := _get_records(hs_key,get_rank_key(diff_rank))
	if records.size() == 0:
		return -1
	else:
		return records[0].score
	
# return : list of all unique players names in highscore table
func get_all_player_names() -> Array[String]:
	var unique_names: Array[String] = []
	for song_records: Dictionary in _hs_table.values():
		for diff_record: Array in song_records.values():
			for hs_entry: Dictionary in diff_record:
				var player_name: String = hs_entry.player_name
				# add name to list if we haven't seen it before
				if not unique_names.has(player_name):
					unique_names.append(player_name)
	return unique_names

# restores highscore table from filesystem
func load_hs_table() -> void:
	var file := FileAccess.open(HIGHSCORES_FILEPATH,FileAccess.READ)
	if file:
		var text := file.get_as_text()
		file.close()
		var json_res := JSON.parse_string(text) as Dictionary
		if json_res:
			_hs_table = json_res
	else:
		print("WARN: Failed to open %s (might not exist yet)" % HIGHSCORES_FILEPATH)

# saves highscore table to filesystem
func save_hs_table() -> void:
	var file := FileAccess.open(HIGHSCORES_FILEPATH,FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_hs_table,"   ",true))
		file.close()
	else:
		print("ERROR: Failed to open %s" % HIGHSCORES_FILEPATH)

# internal function used to lookup records for a given song + diffculty
func _get_records(hs_key: String, diff_rank: int) -> Array:
	var records: Array = []
	
	if _hs_table.has(hs_key):
		var i: Variant = _hs_table[hs_key]
		if not i is Dictionary: return []
		var hs_row := i as Dictionary
		if hs_row.has(str(diff_rank)):
			records = hs_row[str(diff_rank)]
	
	return records

# internal function used too check if a score is a new highscore
func _is_new_highscore(hs_key: String, diff_rank: int, score: int) -> bool:
	var records := _get_records(hs_key,diff_rank)
	# make a temporary record just for lookup purposes
	var temp_record := _make_record(score,"**TEMP_PLAYER**")
	return _get_insert_index(records,temp_record) < MAX_RECORDS_PER_KEY

# creates a "record" structure for storage in the highscore table
func _make_record(score: int, player_name: String) -> Dictionary:
	return {
		"score" : score,
		"player_name" : player_name,
		"epoch_time" : Time.get_unix_time_from_system()
	}

# records: the list of records for a given (song + diff_rank)
# record: the score record to request the insertion index for
func _get_insert_index(records: Array, record: Dictionary) -> int:
	return records.bsearch_custom(record, _highest_and_oldest, false)

static func _highest_and_oldest(lhs: Dictionary, rhs: Dictionary) -> bool:
	if lhs.score > rhs.score:
		return true
	elif lhs.score < rhs.score:
		return false
	else:
		#  Older score's should be sorted with higher precedance
		# than newer scores.
		if lhs.epoch_time < rhs.epoch_time:
			return true
	return false
