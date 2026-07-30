extends GameState
class_name GameStatePlaying

func _ready(game: BeepSaber_Game) -> void:
	game.main_menu._hide()
	game.settings_canvas._hide()
	game.show_MapSourceDialogs(false)
	game.endscore._hide()
	game.pause_menu._hide()
	game.highscore_canvas._hide()
	game.name_selector_canvas._hide()
	if Settings.handedness == 0:
		if Map.one_saber:
			if Settings.left_handed:
				game.right_saber._hide()
				game.left_saber._show()
			else:
				game.left_saber._hide()
				game.right_saber._show()
		else:
			game.right_saber._show()
			game.left_saber._show()
	elif Settings.handedness == Constants.HANDEDNESS_FORCE_LEFT:
		game.right_saber._hide()
		game.left_saber._show()
	elif Settings.handedness == Constants.HANDEDNESS_FORCE_RIGHT:
		game.right_saber._show()
		game.left_saber._hide()
	elif Settings.handedness == Constants.HANDEDNESS_IGNORE:
		game.right_saber._show()
		game.left_saber._show()
	game.multiplier_label.visible = true
	game.point_label.visible = true
	game.percent_indicator.visible = true
	game.track.visible = true
	game.left_ui_raycast.visible = false
	game.right_ui_raycast.visible = false
	game.highscore_keyboard._hide()
	game.online_search_keyboard._hide()
	game.left_saber.set_swingcast_enabled(true)
	game.right_saber.set_swingcast_enabled(true)
	Scoreboard.paused = false

func _physics_process(game: BeepSaber_Game) -> void:
	if game.left_controller.by_just_pressed() or game.left_controller.menu_just_pressed():
		game._transition_game_state(game.gamestate_paused)
	if game._audio_synced_after_restart:
		_process_map(game)
	else:
		# 0.5 seconds is a pretty concervative number to use for the audio
		# resync check. Having this duration be this long might only be an
		# issue for maps that spawn notes extremely early into the song.
		if game.song_player.get_playback_position() < 0.5:
			game._audio_synced_after_restart = true

var bomb_template := load("res://game/Bomb/Bomb.tscn") as PackedScene
var wall_template := load("res://game/Wall/Wall.tscn") as PackedScene
var arc_template := load("res://game/Arc/Arc.tscn") as PackedScene
const BEATS_AHEAD := 4.0

func _process_map(game: BeepSaber_Game) -> void:
	if (Map.current_info == null):
		return
	
	var current_beat := game.song_player.get_playback_position() * Map.current_info.beats_per_minute * 0.016666666666666667
	var look_ahead := current_beat + BEATS_AHEAD
	
	# chains connect to a regular colornote and modify it, so we have to keep
	# track of what notes were spawned this frame, in case any become the head
	# of a chain.
	# why did they do this?
	var note_info_refs: Array[ColorNoteInfo] = []
	var cube_refs: Array[BeepCube] = []
	
	# spawn notes
	while not Map.note_stack.is_empty() and Map.note_stack[-1].beat <= look_ahead:
		var note := GlobalReferences.cube_pool.acquire() as BeepCube
		var note_info := Map.note_stack.pop_back() as ColorNoteInfo
		note.spawn(note_info, current_beat)
		note_info_refs.append(note_info)
		cube_refs.append(note)
	
	# spawn bombs
	while not Map.bomb_stack.is_empty() and Map.bomb_stack[-1].beat <= look_ahead:
		var bomb := bomb_template.instantiate() as Bomb
		bomb.spawn(Map.bomb_stack.pop_back() as BombInfo, current_beat)
		game.track.add_child(bomb)
	
	# spawn obstacles (walls)
	while not Map.obstacle_stack.is_empty() and Map.obstacle_stack[-1].beat <= look_ahead:
		var wall := wall_template.instantiate() as Wall
		wall.spawn(Map.obstacle_stack.pop_back() as ObstacleInfo, current_beat)
		game.track.add_child(wall)
	
	while not Map.arc_stack.is_empty() and Map.arc_stack[-1].head_beat <= look_ahead:
		var arc := arc_template.instantiate() as Arc
		var arc_info := Map.arc_stack.pop_back() as ArcInfo
		
		# find starting cube to use as magnet trigger and mark start and end cubes as arc head/tail
		var head_cube : BeepCube
		var cube_id := cube_refs.size()-1
		var have_head := false
		var have_tail := false
		while cube_id >= 0:
			var current_cube : BeepCube = cube_refs[cube_id]
			if current_cube.which_saber == arc_info.color:
				if current_cube.beat == arc_info.head_beat:
					current_cube.set_arc_head()
					head_cube = current_cube
					if have_tail:
						break
					have_head = true
				if current_cube.beat == arc_info.tail_beat:
					current_cube.set_arc_tail()
					if have_head:
						break
					have_tail = true
			cube_id -= 1
		
		if have_head:
			arc.spawn(arc_info, current_beat, head_cube)
			game.track.add_child(arc)
	
	while not Map.chain_stack.is_empty() and Map.chain_stack[-1].head_beat <= look_ahead:
		var chain_info := Map.chain_stack.pop_back() as ChainInfo
		if chain_info.slice_count > 1: # skip if the chain doesn't have any links
			ChainLink.construct_chain(chain_info, current_beat, note_info_refs, cube_refs)
	
	while not Map.event_stack.is_empty() and Map.event_stack[-1].beat <= current_beat:
		game.event_driver.process_event(Map.event_stack.pop_back() as EventInfo)
