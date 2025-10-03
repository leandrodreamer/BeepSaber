# The main menu is shown at game start or pause on an OQ_UI2DCanvas
# some logic is in the BeepSaber_Game.gd to set the correct state
#
# This file also contains the logic to load a beatmap in the format that
# normal Beat Saber uses. So you can load here custom beat saber songs too
extends Panel
class_name MainMenu

# emitted when a new map difficulty is selected
signal difficulty_changed(map_info: MapInfo, diff_rank: int)
# emitted when the settings button is pressed
signal settings_requested()
signal start_map(info: MapInfo, difficulty: DifficultyInfo)

var _cover_texture_create_sw := StopwatchFactory.create("cover_texture_create",10,true)

@export var main_song_player_ref: AudioStreamPlayer
@export var keyboard: OQ_UI2DKeyboard
@export var beepsaber_game : BeepSaber_Game

@export var song_uploader_ref: SongUploader

@onready var playlist_selector := $PlaylistSelector as OptionButton
@onready var _bg_img_loader := preload("res://game/scripts/BackgroundImgLoader.gd").new()

@onready var cover := $cover as TextureRect
@onready var songs_menu := $SongsMenu as ItemList
@onready var diff_menu := $DifficultyMenu as ItemList
@onready var delete_button := $Delete_Button as Button

@onready var song_preview := $song_prev as AudioStreamPlayer
var song_preview_transition_time := 1.0

var current_selected: int

enum PlaylistOptions {
	AllSongs,
	RecentlyAdded,
	MostPlayed
}

# several different lists of maps, for use with the sort-by bar up top
var _all_songs: Array[MapInfo]
var _recently_added_songs: Array[MapInfo] # newest is first, oldest is last
var _most_played_songs: Array[MapInfo] # most played is first, least played is last
var _currently_selected_songlist_ref: Array[MapInfo] = _all_songs # reference to whichever map list is the currently selected one

# stop the preview player if the main song player is going
func _physics_process(_delta: float) -> void:
	if main_song_player_ref.playing:
		song_preview.stop()

func refresh_playlist() -> void:
	var id := playlist_selector.get_selected_id()
	_on_PlaylistSelector_item_selected(id)

class MapInfoWithSort:
	var num: int
	var info: MapInfo
	
	func _init(n: int, i: MapInfo) -> void:
		num = n
		info = i

func compare(a: MapInfoWithSort, b: MapInfoWithSort) -> bool:
	return a.num > b.num

func _load_playlists() -> void:
	#copy sample songs to main playlist folder on first run
	const config_path := "user://config.dat"
	if not FileAccess.file_exists(config_path):
		@warning_ignore("return_value_discarded")
		DirAccess.make_dir_recursive_absolute(Constants.APPDATA_PATH+"Songs/")
		const maps_path := "res://game/data/maps/"
		var dir := DirAccess.open(maps_path + "Songs/")
		@warning_ignore("return_value_discarded")
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while not file_name.is_empty():
			if dir.current_is_dir():
				var new_dir := maps_path+"Songs/"+file_name
				@warning_ignore("return_value_discarded")
				DirAccess.make_dir_recursive_absolute(Constants.APPDATA_PATH+"Songs/"+file_name)
				var copy := DirAccess.open(new_dir)
				@warning_ignore("return_value_discarded")
				copy.list_dir_begin()
				var copy_file_name := copy.get_next()
				while not copy_file_name.is_empty():
					var copy_new_dir := new_dir+"/"+copy_file_name
					@warning_ignore("return_value_discarded")
					dir.copy(copy_new_dir,Constants.APPDATA_PATH+"Songs/"+file_name+"/"+copy_file_name)
					copy_file_name = copy.get_next()
			file_name = dir.get_next()
	
	_discover_all_songs(Constants.APPDATA_PATH+"Songs/")
	var songs_with_modify_times: Array[MapInfoWithSort] = []
	var songs_with_play_count: Array[MapInfoWithSort] = []
	for song in _all_songs:
		var song_path := song.filepath
		var modified_time := FileAccess.get_modified_time(song_path)
		var play_count := PlayCount.get_total_play_count(song)
		songs_with_modify_times.append(MapInfoWithSort.new(modified_time, song))
		songs_with_play_count.append(MapInfoWithSort.new(play_count, song))
	
	songs_with_modify_times.sort_custom(compare)
	songs_with_play_count.sort_custom(compare)
	_recently_added_songs = []
	_most_played_songs = []
	for song in songs_with_modify_times:
		_recently_added_songs.append(song.info)
	for song in songs_with_play_count:
		_most_played_songs.append(song.info)
	
	refresh_playlist()
	
	var canvas := get_parent().get_parent()
	if canvas is OQ_UI2DCanvas:
		(canvas as OQ_UI2DCanvas)._input_update()

func _discover_all_songs(seek_path: String) -> void:
	_all_songs.clear()
	var dir := DirAccess.open(seek_path)
	if dir:
		@warning_ignore("return_value_discarded")
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while not file_name.is_empty():
			if dir.current_is_dir(): # TODO: or file_name.ends_with(".zip"):
				var new_dir := seek_path+file_name+"/"
				var song := Map.load_map_info(new_dir)
				if song:
					_all_songs.append(song)
			file_name = dir.get_next()

func _set_cur_playlist(songs: Array[MapInfo]) -> void:
	_currently_selected_songlist_ref = songs
	var current_id := songs_menu.get_selected_items()
	
	songs_menu.clear()
	
	var song_count := songs.size()
	var map_index := 0
	for map in songs:
		@warning_ignore("return_value_discarded")
		songs_menu.add_item("%s - %s" % [map.song_author_name, map.song_name], default_song_icon)
		var filepath := map.filepath + map.cover_image_filename
		_bg_img_loader.load_texture(filepath, _on_cover_loaded, false, map_index)
		map_index += 1
	
	if current_id.size() > 0:
		var selected_id := current_id[0]
		if selected_id >= song_count:
			selected_id = song_count - 1
		_select_song(selected_id)

var default_song_icon := preload("res://game/data/beepsaber_logo.png")

# callback from ImageUtils when background image loading is complete. if image
# failed to load, tex will be null
func _on_cover_loaded(img_tex: Texture2D, is_main_cover: bool, list_idx: int) -> void:
	if img_tex != null:
		if is_main_cover:
			cover.call_deferred("set_texture", img_tex)
		else:
			songs_menu.call_deferred("set_item_icon", list_idx,img_tex)
			#songs_menu.set_item_icon(list_idx,img_tex)

func _load_cover(cover_path: String, filename: String) -> ImageTexture:
	# parse buffer into an ImageTexture
	_cover_texture_create_sw.start()
	var tex := ImageTexture.create_from_image(Image.load_from_file(cover_path+filename))
	_cover_texture_create_sw.stop()
	return tex

func play_preview(buffer: PackedByteArray, start_time: float = 0.0, duration: float = -1.0, buffer_data_type_hint: String = 'ogg') -> void:
	var stream: AudioStream
	# take song preview data from buffer as-is. trust passed type hint
	if buffer_data_type_hint == 'ogg':
		stream = AudioStreamOggVorbis.load_from_buffer(buffer)
	elif buffer_data_type_hint == 'mp3':
		stream = AudioStreamMP3.new()
		(stream as AudioStreamMP3).data = buffer
	
	if not stream: return
	
	if duration < 0.0:
		# assume preview duration based on parsed audio length
		duration = stream.get_length()
	
	
	# fade out preview if ones already running
	if song_preview.playing:
		await _on_stop_prev_timeout()
	
	# start the requested preview, if still on song select
	if not main_song_player_ref.playing:
		song_preview.stream = stream
		var song_prev_Tween := song_preview.create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		@warning_ignore("return_value_discarded")
		song_prev_Tween.tween_property(song_preview, ^"volume_db", 0, song_preview_transition_time)
		song_prev_Tween.play()
		song_preview.play(start_time)
		($song_prev/stop_prev as Timer).start(duration)

func _select_song(id: int) -> void :
	current_selected = id
	songs_menu.ensure_current_is_visible()
	delete_button.disabled = false

	var map: = _currently_selected_songlist_ref[id]
	var modsNeeded = "None"
	var filePath = map.filepath + "info.dat"
	Constants.usingMappingExtension = false
	if FileAccess.file_exists(filePath):
		var mods = vr.load_json_file(filePath)
		if mods:
			var beatmap_sets = mods.get("_difficultyBeatmapSets", [])
			if beatmap_sets.size() > 0:

				var first_set = beatmap_sets[0]
				var difficulty_beatmaps = first_set.get("_difficultyBeatmaps", [])

				if difficulty_beatmaps.size() > 0:

					var first_difficulty = difficulty_beatmaps[0]
					var custom_data = first_difficulty.get("_customData", {})

					if custom_data.has("_requirements"):
						var requirements = custom_data.get("_requirements")
						print(requirements)
						if len(requirements) > 0:
							if modsNeeded == "None": 
								modsNeeded = ""
							for i in len(requirements):
								print(requirements[i])
								modsNeeded = requirements[i] + "\n" + modsNeeded
								Constants.usingMappingExtension = requirements.has("Mapping Extensions")
								Constants.usingNoodleExtension = requirements.has("Noodle Extensions")
								Constants.usingChroma = requirements.has("Chroma")
								Constants.usingVivify = requirements.has("Vivify")
						else:
							modsNeeded = "None"
							Constants.usingMappingExtension = false
							Constants.usingNoodleExtension = false
							Constants.usingChroma = false
							Constants.usingVivify = false
					if custom_data.has("_suggestions"):
						var suggestions = custom_data.get("_suggestions")
						if modsNeeded == "None": 
							modsNeeded = ""
						for i in len(suggestions):
							if not modsNeeded.contains("Chroma"):
								modsNeeded = suggestions[i] + "\n" + modsNeeded
							elif suggestions[i] != "Chroma":
								modsNeeded = suggestions[i] + "\n" + modsNeeded
							if suggestions.has("Chroma"):
								Constants.usingChroma = true
							else:
								Constants.usingChroma = false
					else:
							modsNeeded = "None"
							Constants.usingChroma = false
	else:


		filePath = map.filepath + "Info.dat"
		var mods = vr.load_json_file(filePath)
		if mods:
			var beatmap_sets = mods.get("_difficultyBeatmapSets", [])
			if beatmap_sets.size() > 0:

				var first_set = beatmap_sets[0]
				var difficulty_beatmaps = first_set.get("_difficultyBeatmaps", [])

				if difficulty_beatmaps.size() > 0:

					var first_difficulty = difficulty_beatmaps[0]
					var custom_data = first_difficulty.get("_customData", {})

					if custom_data.has("_requirements"):
						var requirements = custom_data.get("_requirements")
						if len(requirements) > 0:
							if modsNeeded == "None":
								modsNeeded = ""
							for i in len(requirements):
								modsNeeded = requirements[i] + "\n" + modsNeeded
								Constants.usingMappingExtension = requirements.has("Mapping Extensions")
								Constants.usingNoodleExtension = requirements.has("Noodle Extensions")
								Constants.usingChroma = requirements.has("Chroma")
								Constants.usingVivify = requirements.has("Vivify")
						else:
							modsNeeded = "None"
							Constants.usingMappingExtension = false
							Constants.usingNoodleExtension = false
							Constants.usingChroma = false
							Constants.usingVivify = false
					if custom_data.has("_suggestions"):
						var suggestions = custom_data.get("_suggestions")
						if modsNeeded == "None":
							modsNeeded = ""
						for i in len(suggestions):
							modsNeeded = suggestions[i] + "\n" + modsNeeded
							Constants.usingChroma = suggestions.has("Chroma")
					else:
							modsNeeded = "None"
							Constants.usingChroma = false
	#warnMapping.visible = Constants.usingMappingExtension
	#warnNoodle.visible = Constants.usingNoodleExtension
	#warnChroma.visible = Constants.usingChroma
	($SongInfo_Label as Label).text = """Song Author: %s
	Song Title: %s
	Beatmap Author: %s
	Play Count: %d
	Mods requrired: %s""" % [
		map.song_author_name,
		map.song_name,
		map.level_author_name,
		PlayCount.get_total_play_count(map),
		modsNeeded
	]
	
	# load cover in background to avoid freezing UI
	_bg_img_loader.load_texture(map.filepath + map.cover_image_filename, _on_cover_loaded, true, -1)
	
	# preview song
	play_preview(FileAccess.get_file_as_bytes(map.filepath + map.song_filename), map.preview_start_time, map.preview_duration)
	var result := FileAccess.get_open_error()
	if result != OK:
		vr.log_file_error(result, map.filepath + map.song_filename, "BeepSaberMainMenu.gd at line 223 ")
	
	diff_menu.clear()
	for diff in map.difficulty_beatmaps:
		var diff_index := diff_menu.add_item(diff.custom_name)
		diff_menu.set_item_tooltip(diff_index, diff.difficulty + " / " + diff.custom_name)
	
	_select_difficulty(0)

func _on_stop_prev_timeout() -> void:
	var song_prev_Tween := song_preview.create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	@warning_ignore("return_value_discarded")
	song_prev_Tween.tween_property(song_preview, "volume_db", -50, song_preview_transition_time)
	song_prev_Tween.play()
	await get_tree().create_timer(song_preview_transition_time).timeout
	song_preview.stop()


var _map_difficulty := 0

func _select_difficulty(id: int) -> void:
	_map_difficulty = id
	diff_menu.select(id)
	
	# notify listeners that difficulty has changed
	var difficulty := _currently_selected_songlist_ref[current_selected].difficulty_beatmaps[id]
	difficulty_changed.emit(_currently_selected_songlist_ref[current_selected], difficulty.difficulty_rank)


func _load_map_and_start(map: MapInfo) -> void:
	if map.is_empty(): return
	
	var set0 := map.difficulty_beatmaps
	if (set0.size() == 0):
		vr.log_error("No _difficultyBeatmaps in set")
		return
	
	var diff_info := set0[_map_difficulty]
	
	start_map.emit(map, diff_info)

func _on_Delete_Button_button_up() -> void:
	if delete_button.text != "Sure?":
		delete_button.text = "Sure?"
		await get_tree().create_timer(5).timeout
		delete_button.text = "Delete"
	else:
		delete_button.text = "Delete"
		_delete_map(_currently_selected_songlist_ref[current_selected])
	
func _delete_map(map: MapInfo) -> void:
	Highscores.remove_map(map)
	PlayCount.remove_map(map)
	
	if not map.filepath.is_empty():
		var dir := DirAccess.open(map.filepath)
		if dir:
			@warning_ignore("return_value_discarded")
			dir.list_dir_begin()
			var current_file := dir.get_next()
			while current_file != "":
				@warning_ignore("return_value_discarded")
				DirAccess.remove_absolute(map.filepath+current_file)
				current_file = dir.get_next()
			@warning_ignore("return_value_discarded")
			DirAccess.remove_absolute(map.filepath)
			vr.log_info(map.filepath+" Removed")
			delete_button.disabled = true
		else:
			vr.log_info("Error removing song " + map.filepath)
		_on_LoadPlaylists_Button_pressed()

func _ready() -> void:
	UI_AudioEngine.attach_children(self)
	vr.log_info("BeepSaber search path is " + Constants.APPDATA_PATH)
	
	playlist_selector.clear()
	playlist_selector.add_item("All Songs")
	playlist_selector.add_item("Recently Added")
	playlist_selector.add_item("Most Played")
	
	_load_playlists()
	
	await keyboard.ready
	@warning_ignore("return_value_discarded")
	keyboard.text_input_enter.connect(_text_input_enter)
	@warning_ignore("return_value_discarded")
	keyboard.text_input_cancel.connect(_text_input_cancel)
	@warning_ignore("return_value_discarded")
	keyboard._text_edit.text_changed.connect(_text_input_changed)
	@warning_ignore("return_value_discarded")
	keyboard._text_edit.focus_exited.connect(_text_input_enter)
	
	playlist_selector.select(1)
	playlist_selector.item_selected.emit(1)
	
	if song_uploader_ref and song_uploader_ref.active:
		$upload_url.text = "Manually Upload Custom Songs: \n%s"%[
			song_uploader_ref.get_server_url()
		]
	else:
		$upload_url.text = ""
	
	$version.text = beepsaber_game.version
	if OS.get_name() == &"Web":
		$Exit_Button.hide()


func _on_Play_Button_pressed() -> void:
	song_preview.stop()
	_load_map_and_start(_currently_selected_songlist_ref[current_selected])


func _on_Exit_Button_pressed() -> void:
	get_tree().quit()


func _on_Settings_Button_pressed() -> void:
	settings_requested.emit()

const READ_PERMISSION = "android.permission.READ_EXTERNAL_STORAGE"

func is_in_array(arr: Array, val: Variant) -> bool:
	for e: Variant in arr:
		if (e == val): return true
	return false
	
func _check_required_permissions() -> bool:
	if not vr.inVR: return true # desktop is always allowed
	
	var permissions := OS.get_granted_permissions()
	var read_storage_permission := is_in_array(permissions, READ_PERMISSION)
	
	vr.log_info(str(permissions))
	
	if not read_storage_permission:
		return false

	return true

func _check_and_request_permission() -> bool:
	vr.log_info("Checking permissions")
	
	if not _check_required_permissions():
		vr.log_info("Requesting permissions")
		OS.request_permissions()
		return false
	else:
		return true


func _on_LoadPlaylists_Button_pressed() -> void:
	# Note: this call is non-blocking; so a user has to click again after
	#       granting the permissions; we need to find a solutio for this
	#       maybe polling after the button press?
	_check_and_request_permission()
	_load_playlists()


func _on_Search_Button_button_up() -> void:
	keyboard.visible=true
	keyboard._text_edit.grab_focus()

func _text_input_enter(_text: String) -> void:
	keyboard.visible=false

func _text_input_cancel() -> void:
	keyboard.visible=false
	_clean_search()

func _text_input_changed() -> void:
	var text := keyboard._text_edit.text
	($Search_Button/Label as Label).text = text
	if text == "":
		_clean_search()
		return
	text = text.to_upper() # ignore case
	var songs_sorted_by_similarity: Array[MapInfoWithSort] = []
	for song in _all_songs:
		# similarity is between 0.0 and 1.0, MapInfoWithSort takes an int,
		# gotta make the number larger else it'll just be 0 or 1 later
		var similarity := song.song_name.to_upper().similarity(text) * 65536.0
		songs_sorted_by_similarity.append(MapInfoWithSort.new(int(similarity), song))
	songs_sorted_by_similarity.sort_custom(compare)
	var songs_sorted: Array[MapInfo] = []
	for song in songs_sorted_by_similarity:
		songs_sorted.append(song.info)
	_set_cur_playlist(songs_sorted)

func _clean_search() -> void:
	_on_PlaylistSelector_item_selected(playlist_selector.get_selected_id())
	($Search_Button/Label as Label).text = ""

func _on_PlaylistSelector_item_selected(id: int) -> void:
	match id:
		PlaylistOptions.AllSongs:
			_set_cur_playlist(_all_songs)
		PlaylistOptions.MostPlayed:
			_set_cur_playlist(_most_played_songs)
		PlaylistOptions.RecentlyAdded:
			_set_cur_playlist(_recently_added_songs)
		_:
			vr.log_warning("Unsupported playlist option %s" % id)
			_set_cur_playlist(_all_songs)
