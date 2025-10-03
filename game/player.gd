extends XROrigin3D

@onready var beep_saber: BeepSaber_Game = $".."
@onready var song_player: AudioStreamPlayer = $"../SongPlayer"

func _process(delta: float) -> void:
	var fps = Engine.get_frames_per_second()
	if fps <= 5 and song_player.playing:
		print(fps)
		beep_saber._transition_game_state(beep_saber.gamestate_paused)
		#Input.action_press()
		pass
