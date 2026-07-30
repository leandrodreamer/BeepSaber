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
signal start_map(info: MapInfo, difficulty: DifficultyInfo, health: bool)

var _cover_texture_create_sw := StopwatchFactory.create("cover_texture_create",10,true)

const FAVORITE_MASK := 0x4000000000000000
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
@onready var health_control := $Modifiers/Health as CheckButton
@onready var bombs_control := $Modifiers/Health/Bombs as CheckButton
@onready var arrows_control := $Modifiers/Health/Bombs/Arrows as CheckButton
@onready var flip_control := $Modifiers3/Flip as OptionButton
@onready var handedness_control := $Modifiers3/Flip/Speed/Handedness as OptionButton
@onready var claws_control := $Modifiers2/Claws as CheckButton
@onready var size_control := $Modifiers2/Claws/Size as OptionButton
@onready var width_control := $Modifiers2/Claws/Size/Width as OptionButton
@onready var speed_control := $Modifiers3/Flip/Speed as OptionButton
@onready var favorite_button := $Favorite_Button as Button
@onready var reset_button := $Reset_Button as Button

@onready var song_preview := $song_prev as AudioStreamPlayer
var song_preview_transition_time := 1.0
var licenses_showing := false

var current_selected := -1

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

# keep a record of all song hashes so we can check if the song is already in our local database
var all_song_hashes: Array[String]
# send a signal whenever the all_song_keys array changes
signal song_list_changed()

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
	
func _sort_songs() -> void:
	var do_map : MapInfo = null
	var do_difficulty := -1
	
	if _currently_selected_songlist_ref != null and current_selected >= 0:
		do_map = _currently_selected_songlist_ref[current_selected]
		do_difficulty = _map_difficulty
			
	var songs_with_modify_times: Array[MapInfoWithSort] = []
	var songs_with_play_count: Array[MapInfoWithSort] = []
	var songs_favorite: Array[MapInfo] = []
	var songs_unfavorite: Array[MapInfo] = []
	for song in _all_songs:
		var song_path := song.filepath
		var modified_time := FileAccess.get_modified_time(song_path)
		var play_count := PlayCount.get_total_play_count(song)
		var favorite := PlayCount.is_favorite(song)
		if favorite:
			modified_time |= FAVORITE_MASK
			play_count |= FAVORITE_MASK
			songs_favorite.append(song)
		else:
			songs_unfavorite.append(song)
		songs_with_modify_times.append(MapInfoWithSort.new(modified_time, song))
		songs_with_play_count.append(MapInfoWithSort.new(play_count, song))
	
	songs_with_modify_times.sort_custom(compare)
	songs_with_play_count.sort_custom(compare)
	_recently_added_songs = []
	_most_played_songs = []
	_all_songs = []
	for song in songs_with_modify_times:
		_recently_added_songs.append(song.info)
	for song in songs_with_play_count:
		_most_played_songs.append(song.info)
	for song in songs_favorite:
		_all_songs.append(song)
	for song in songs_unfavorite:
		_all_songs.append(song)
		
	refresh_playlist()
	if do_map != null:
		for i in range(_currently_selected_songlist_ref.size()):
			if _currently_selected_songlist_ref[i] == do_map:
				#songs_menu.select(i)
				_select_song(i)
				_select_difficulty(do_difficulty)

	if current_selected < 0:
		for i in range(_currently_selected_songlist_ref.size()):
			if _currently_selected_songlist_ref[i].filepath == Settings.last_map:
				songs_menu.select(i)
				_select_song(i)
				break
	
func _load_playlists() -> void:
	#copy sample songs to main playlist folder on first run
	current_selected = -1
	if not Settings.preloaded_songs:
		@warning_ignore("return_value_discarded")
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
		Settings.preloaded_songs = true
	
	_discover_all_songs(Constants.APPDATA_PATH+"Songs/")
	
	_sort_songs()
		
	var canvas := get_parent().get_parent()
	if canvas is OQ_UI2DCanvas:
		(canvas as OQ_UI2DCanvas)._input_update()

func _discover_all_songs(seek_path: String) -> void:
	_all_songs.clear()
	all_song_hashes.clear()
	var dir := DirAccess.open(seek_path)
	if dir:
		@warning_ignore("return_value_discarded")
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while not file_name.is_empty():
			if dir.current_is_dir() or file_name.to_lower().ends_with(".zip"): 
				var path : String
				if dir.current_is_dir():
					path = seek_path+file_name+"/"
				else:
					path = seek_path+file_name
				var song := Map.load_map_info(path)
				if song:
					_all_songs.append(song)
				# record all hashes, even those that have unsupported versions
				all_song_hashes.append(file_name)
			file_name = dir.get_next()
	emit_signal("song_list_changed")

func _set_cur_playlist(songs: Array[MapInfo]) -> void:
	var current_map : MapInfo
	current_map = null
	if current_selected >= 0:
		current_map = _currently_selected_songlist_ref[current_selected]
	_currently_selected_songlist_ref = songs
	songs_menu.clear()
	
	var map_index := 0
	for map in songs:
		@warning_ignore("return_value_discarded")
		songs_menu.add_item("%s - %s%s" % [map.song_author_name, map.song_name, "" if map.have_song else " [silent]"], default_song_icon)
		songs_menu.set_item_custom_fg_color(map_index, Color.YELLOW if PlayCount.is_favorite(map) else Color.WHITE)
		_bg_img_loader.load_texture(map.filepath, map.cover_image_filename, _on_cover_loaded, false, map_index)
		map_index += 1
		
	if current_map != null:
		current_selected = -1
		for i in range(songs.size()):
			if songs[i] == current_map:
				songs_menu.select(i)
				_select_song(i)
		if current_selected == -1:
			songs_menu.select(-1)

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
		# TODO: is this a good idea with higher speeds?
		song_prev_Tween.tween_property(song_preview, ^"volume_db", 0, song_preview_transition_time)
		song_prev_Tween.play()
		song_preview.play(start_time)
		song_preview.pitch_scale = Settings.music_speed / 100.
		($song_prev/stop_prev as Timer).start(duration)

func _select_song(id: int) -> void:
	current_selected = id 
	if id < 0:
		return
	songs_menu.ensure_current_is_visible()
	delete_button.disabled = false
	favorite_button.show()
	
	var map := _currently_selected_songlist_ref[id]
	($SongInfo_Label as Label).text = """Song Author: %s
	Song Title: %s
	Beatmap Author: %s
	Play Count: %d""" % [
		map.song_author_name,
		map.song_name,
		map.level_author_name,
		PlayCount.get_total_play_count(map)
	]
	
	_set_favorite_icon(PlayCount.is_favorite(map))
	
	# load cover in background to avoid freezing UI
	_bg_img_loader.load_texture(map.filepath, map.cover_image_filename, _on_cover_loaded, true, -1)
	
	# preview song
	if Settings.audio_music_preview > 0 and map.have_song:
		play_preview(Utils.read_binary_file(map.filepath, map.song_filename), map.preview_start_time, map.preview_duration)
	
	diff_menu.clear()
	for diff in map.difficulty_beatmaps:
		var diff_index := diff_menu.add_item(diff.get_display_name())
		diff_menu.set_item_tooltip(diff_index, diff.difficulty + " / " + diff.get_display_name())
	
	var d := PlayCount.get_last_difficulty(map)
	_select_difficulty(0 if d < 0 else (d & Constants.DIFFICULTY_MASK))

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
	update_view()


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
		current_selected = -1
		update_view()
	
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
			delete_button.disabled = true
			favorite_button.hide()
		else:
			DirAccess.remove_absolute(map.filepath)
			delete_button.disabled = true
			favorite_button.hide()
	_on_LoadPlaylists_Button_pressed()
	
func _drop_down(control: OptionButton, list: Array, value: Variant, defaultIndex: int) -> void:
	control.clear()
	var index := defaultIndex
	for i in range(list.size()):
		control.add_item(list[i][1])
		if list[i][0] == value:
			index = i
	control.selected = index
	
func _update_mod_controls() -> void:
	health_control.button_pressed = Settings.health_mode
	arrows_control.button_pressed = Settings.arrows_enabled
	
	_drop_down(flip_control, Constants.FLIPS, Settings.flip, 0)
	_drop_down(handedness_control, Constants.HANDEDNESSES, Settings.handedness, 0)
	_drop_down(width_control, Constants.WIDTHS, Settings.width, 0)
	_drop_down(size_control, Constants.SIZES, Settings.block_size, 1)
	_drop_down(speed_control, Constants.SPEEDS, Settings.music_speed, 1)
	
	bombs_control.button_pressed = Settings.bombs_enabled
	claws_control.button_pressed = Settings.claws

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(Constants.APPDATA_PATH+"Backgrounds/")
	DirAccess.make_dir_recursive_absolute(Constants.APPDATA_PATH+"Songs/")

	Settings.changed.connect(on_settings_changed)
	
	_update_mod_controls()
	favorite_button.hide()
	
	UI_AudioEngine.attach_children(self)
	
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
		$upload_url.text = "Manually Upload Songs/Backgrounds: \n%s"%[
			song_uploader_ref.get_server_url()
		]
	else:
		$upload_url.text = ""
	
	$version.text = beepsaber_game.version
	if OS.get_name() == &"Web":
		$Exit_Button.hide()
		
func on_settings_changed(key: StringName) -> void:
	match key:
		&"music_speed":
			song_preview.pitch_scale = Settings.music_speed / 100.

func difficulty_modifier_changed() -> void:
	pass			

func _on_Play_Button_pressed() -> void:
	if current_selected >= 0:
		var map := _currently_selected_songlist_ref[current_selected]
		Settings.last_map = map.filepath
		song_preview.stop()
		Settings.save()
		_load_map_and_start(map)

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

func _text_input_enter(_text:String = "") -> void:
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

func _on_licenses_pressed() -> void:
	var license := FileAccess.open("res://LICENSE", FileAccess.READ).get_as_text()
	$LicensePopup/ScrollContainer/Label.text = license
	if licenses_showing:
		$LicensePopup.hide()
	else:
		$LicensePopup.show()
	licenses_showing = not licenses_showing
	return
	
func update_view() -> void:
	if current_selected >= 0 and len(_currently_selected_songlist_ref):
		if current_selected >= len(_currently_selected_songlist_ref):
			current_selected = 0
		if _map_difficulty >= len(_currently_selected_songlist_ref[current_selected].difficulty_beatmaps):
			_map_difficulty = 0
		var difficulty := _currently_selected_songlist_ref[current_selected].difficulty_beatmaps[_map_difficulty]
		difficulty_changed.emit(_currently_selected_songlist_ref[current_selected], difficulty.difficulty_rank)
	else:	
		difficulty_changed.emit(null, -1)
	_set_reset_icon()

func _on_health_toggled(value: bool) -> void:
	Settings.health_mode = value
	update_view()

func _on_claws_toggled(value: bool) -> void:
	Settings.claws = value
	update_view()

func _on_bombs_toggled(value: bool) -> void:
	Settings.bombs_enabled = value
	update_view()
	
func _on_arrows_toggled(value: bool) -> void:
	Settings.arrows_enabled = value
	update_view()
	
func _are_mods_default() -> bool:
	if Settings.health_mode or not Settings.bombs_enabled or not Settings.arrows_enabled:
		return false
	if Settings.claws or Settings.block_size != 100:
		return false
	if Settings.width != 100 or Settings.flip != 0 or Settings.music_speed != 100:
		return false
	if Settings.handedness != 0:
		return false
	return true
	
func _set_reset_icon() -> void:
	if _are_mods_default():
		reset_button.hide()
	else:
		reset_button.text = "\u21BA" 
		reset_button.show()

func _set_favorite_icon(value: bool) -> void:
	favorite_button.text = "\u2605" if value else "\u2606"
	var color := Color.YELLOW if value else Color.WHITE
	favorite_button.add_theme_color_override("font_color", color)
	favorite_button.add_theme_color_override("font_disabled_color", color)
	favorite_button.add_theme_color_override("font_focus_color", color)
	favorite_button.add_theme_color_override("font_hover_color", color)
	favorite_button.add_theme_color_override("font_hover_pressed_color", color)
	favorite_button.add_theme_color_override("font_pressed_color", color)

func _on_favorite_button_pressed() -> void:
	var map := _currently_selected_songlist_ref[current_selected]
	var favorite := not PlayCount.is_favorite(map)
	PlayCount.set_favorite(map, favorite)
	_set_favorite_icon(favorite)
	_sort_songs()
	update_view()
	
func _on_small_toggled(value: bool) -> void:
	Settings.small = value
	update_view()

func _on_width_item_selected(index: int) -> void:
	Settings.width = Constants.WIDTHS[index][0]
	update_view()

func _on_size_item_selected(index: int) -> void:
	Settings.block_size = Constants.SIZES[index][0]
	update_view()

func _on_speed_item_selected(index: int) -> void:
	Settings.music_speed = Constants.SPEEDS[index][0]
	update_view()

func _on_flip_item_selected(index: int) -> void:
	Settings.flip = Constants.FLIPS[index][0]
	update_view()

func _on_handedness_item_selected(index: int) -> void:
	Settings.handedness = Constants.HANDEDNESSES[index][0]
	update_view()

func _on_reset_button_pressed() -> void:
	Settings.health_mode = false
	Settings.bombs_enabled = true
	Settings.claws = false
	Settings.block_size = 100
	Settings.width = 100 
	Settings.flip = 0
	Settings.music_speed = 100
	Settings.handedness = 0
	_update_mod_controls()
	update_view()

	pass # Replace with function body.
