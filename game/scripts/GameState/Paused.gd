extends GameState
class_name GameStatePaused

func _ready(game: BeepSaber_Game) -> void:
	game.main_menu._hide()
	game.settings_canvas._hide()
	game.show_MapSourceDialogs(false)
	game.endscore._hide()
	game.pause_menu._show()
	game.highscore_canvas._hide()
	game.name_selector_canvas._hide()
	game.multiplier_label.visible = true
	game.point_label.visible = true
	game.percent_indicator.visible = true
	game.track.visible = false
	game.left_ui_raycast.visible = true
	game.right_ui_raycast.visible = true
	game.highscore_keyboard._hide()
	game.online_search_keyboard._hide()
	game.left_saber.set_swingcast_enabled(false)
	game.right_saber.set_swingcast_enabled(false)
	Scoreboard.paused = true
	
	game.pause_position = game.song_player.get_playback_position()
	game.song_player.stop()
	(game.pause_menu.ui_control as PausePanel).set_pause_text(
		"%s By %s\nMap author: %s" % [
		Map.current_info.song_name,
		Map.current_info.song_author_name,
		Map.current_info.level_author_name
		], Map.current_difficulty.get_display_name()
	)
