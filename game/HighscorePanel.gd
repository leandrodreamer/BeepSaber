extends Panel
class_name HighscorePanel

signal close()

@export var show_close_button := true
@export var show_song_info := true

# keep a copy of the base row for regeneration later
@onready var _base_row = $Margin/VBox/LeftRight/ScrollContainer/Margin/HighscoresList/BaseRecordRow.duplicate()
@onready var _highscore_list = $Margin/VBox/LeftRight/ScrollContainer/Margin/HighscoresList
@onready var _title = $Margin/VBox/Title
@onready var _song_info = $Margin/VBox/LeftRight/VBox/SongInfo_Label
@onready var _exit_button = $Margin/VBox/Exit_Button
@onready var _song_info_panel = $Margin/VBox/LeftRight/VBox

func _ready() -> void:
	_clear_list()
	_exit_button.visible = show_close_button
	_song_info_panel.visible = show_song_info
	
func load_highscores(map_info: MapInfo, diff_rank: int) -> void:
	
	# clear the high score list
	_clear_list()
	
	diff_rank = HighscoreTable.get_rank_key(diff_rank)
	
	# populate title text
	set_title("Highscores (%s)" % _get_difficulty_name(map_info,diff_rank))
	
	# populate song info
	_song_info.text = """Artist: %s
		Song: %s
		Map Author: %s""" % [map_info.song_author_name, map_info.song_name, map_info.level_author_name]
		
	# TODO populate song artwork
	
	var records := Highscores.get_records(map_info,diff_rank)
	var idx = 1
	for record in records:
		# build a new row and populate fields from record
		var new_row = _base_row.duplicate()
		new_row.get_child(0).text = "%d." % idx
		new_row.get_child(1).text = record.player_name
		new_row.get_child(2).text = str(record.score)
		
		_highscore_list.add_child(new_row)
		idx += 1
		
func set_title(title_text):
	_title.text = title_text
	
# clears all rows from the highscore table
func _clear_list():
	for c in _highscore_list.get_children():
		c.queue_free()
	
func _get_difficulty_name(map_info: MapInfo, diff_rank: int) -> String:
	var difficulty := diff_rank & Constants.DIFFICULTY_MASK
	var width := HighscoreTable.get_width_from_rank(diff_rank)
	var speed := HighscoreTable.get_speed_from_rank(diff_rank)
	var game_type := ( ("Health" if (diff_rank & Constants.DIFFICULTY_HEALTH) != 0 else "No Health") +
					 ("" if (diff_rank & Constants.DIFFICULTY_BOMBS) != 0 else ", No Bombs") + 
					 ("" if (diff_rank & Constants.DIFFICULTY_ARROWS) != 0 else ", No Arrows") +
					 (", Small" if ((diff_rank & Constants.DIFFICULTY_BLOCK_SIZE_MASK) == Constants.DIFFICULTY_BLOCK_SIZE_SMALL) else "") + 
					 (", Big" if ((diff_rank & Constants.DIFFICULTY_BLOCK_SIZE_MASK) == Constants.DIFFICULTY_BLOCK_SIZE_BIG) else "") + 
					 (", Giant" if ((diff_rank & Constants.DIFFICULTY_BLOCK_SIZE_MASK) == Constants.DIFFICULTY_BLOCK_SIZE_GIANT) else "") + 
					 (", Short Sword" if (diff_rank & Constants.DIFFICULTY_CLAWS) != 0 else "") +
					 ((", Stretch %d%% " % width) if (width != 100) else "") +
					 ((", Speed %d%% " % speed) if (speed != 100) else "") +
					 ((", %s " % Constants.FLIPS[Settings.flip][1] if Settings.flip != 0 else "")) +
					 ((", %s " % Constants.FLIPS[Settings.handedness][1] if Settings.handedness != 0 else ""))
					 )
	for beat_map in map_info.difficulty_beatmaps:
		if beat_map.difficulty_rank == (diff_rank & Constants.DIFFICULTY_MASK):
			return beat_map.difficulty + ", " + game_type
	return ('Rank %d' % (diff_rank & Constants.DIFFICULTY_MASK)) + " " + game_type

func _on_Exit_Button_pressed() -> void:
	close.emit()
