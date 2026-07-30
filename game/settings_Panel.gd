extends Panel
class_name SettingsPanel

signal apply()
@export var beepsaber_game : BeepSaber_Game

@onready var saber_control := $ScrollContainer/VBox/SaberTypeRow/saber as OptionButton
@onready var glare_control := $ScrollContainer/VBox/glare as CheckButton
@onready var saber_tail_control := $ScrollContainer/VBox/saber_tail as CheckButton
@onready var saber_thickness := $ScrollContainer/VBox/SaberThicknessRow/saber_thickness as HSlider
@onready var cut_blocks := $ScrollContainer/VBox/cut_blocks as CheckButton
@onready var left_saber_col := $ScrollContainer/VBox/SaberColorsRow/left_saber_col as ColorPickerButton
@onready var right_saber_col := $ScrollContainer/VBox/SaberColorsRow/right_saber_col as ColorPickerButton
@onready var show_debug_control := $ScrollContainer/VBox/show_debug as CheckButton
@onready var mixed_reality_control := $ScrollContainer/VBox/mixed_reality as CheckButton
@onready var explain_control := $ScrollContainer/VBox/explain as CheckButton
@onready var left_handed_control := $ScrollContainer/VBox/left_handed as CheckButton
@onready var not_music_dl_control := $ScrollContainer/VBox/not_music_dl as CheckButton
@onready var swing_scoring_control := $ScrollContainer/VBox/swing_scoring as CheckButton
@onready var show_collisions := $ScrollContainer/VBox/show_collisions as CheckButton
@onready var ui_volume_slider := $ScrollContainer/VBox/UI_VolumeRow/ui_volume_slider as HSlider
@onready var disable_map_color_control := $ScrollContainer/VBox/disable_map_color as CheckButton
@onready var left_saber_posx_control := $ScrollContainer/VBox/left_saber_offset/posx as SpinBox
@onready var left_saber_posy_control := $ScrollContainer/VBox/left_saber_offset/posy as SpinBox
@onready var left_saber_posz_control := $ScrollContainer/VBox/left_saber_offset/posz as SpinBox
@onready var left_saber_rotx_control := $ScrollContainer/VBox/left_saber_offset/rotx as SpinBox
@onready var left_saber_roty_control := $ScrollContainer/VBox/left_saber_offset/roty as SpinBox
@onready var left_saber_rotz_control := $ScrollContainer/VBox/left_saber_offset/rotz as SpinBox
@onready var right_saber_posx_control := $ScrollContainer/VBox/right_saber_offset/posx as SpinBox
@onready var right_saber_posy_control := $ScrollContainer/VBox/right_saber_offset/posy as SpinBox
@onready var right_saber_posz_control := $ScrollContainer/VBox/right_saber_offset/posz as SpinBox
@onready var right_saber_rotx_control := $ScrollContainer/VBox/right_saber_offset/rotx as SpinBox
@onready var right_saber_roty_control := $ScrollContainer/VBox/right_saber_offset/roty as SpinBox
@onready var right_saber_rotz_control := $ScrollContainer/VBox/right_saber_offset/rotz as SpinBox
@onready var player_height_offset_control := $ScrollContainer/VBox/player_height_offset/pos as SpinBox
@onready var audio_master_control := $ScrollContainer/VBox/audio/master/master_slider as HSlider
@onready var audio_music_control := $ScrollContainer/VBox/audio/music/music_slider as HSlider
@onready var audio_music_preview_control := $ScrollContainer/VBox/audio/music_preview/music_preview_slider as HSlider
@onready var audio_sfx_control := $ScrollContainer/VBox/audio/sfx/sfx_slider as HSlider
@onready var spectator_view_control := $ScrollContainer/VBox/spectator_view as CheckButton
@onready var spectator_hud_control := $ScrollContainer/VBox/spectator_hud as CheckButton
@onready var background_mode_control := $ScrollContainer/VBox/background_mode_grid/background_mode as OptionButton
@onready var background_texture_control := $ScrollContainer/VBox/background_texture_grid/background_texture as OptionButton

var _play_ui_sound_demo := false
var left_saber_col_state := false
var right_saber_col_state := false

@export var main_menu_ref : MainMenu

func _ready() -> void:
	UI_AudioEngine.attach_children(self)
	
	if OS.get_name() in ["Android", "Web"]:
		spectator_hud_control.hide()
		spectator_view_control.hide()

	for i in len(Settings.BACKGROUND_MODES):
		background_mode_control.add_item(Settings.BACKGROUND_MODES[i][1])
		if Settings.background == Settings.BACKGROUND_MODES[i][0]:
			background_mode_control.selected = i
	background_mode_control.connect("item_selected", _on_background_mode_selected)
	
	_update_backgrounds()

	set_controls_from_settings()
	_play_ui_sound_demo = true
	for picker in [left_saber_col.get_picker(),right_saber_col.get_picker()]:
		picker.sampler_visible = false
		picker.presets_visible = true
		picker.picker_shape = ColorPicker.SHAPE_NONE
		picker.add_recent_preset(Color("ff1a1a"))
		picker.add_recent_preset(Color("1a1aff"))
			
	if OS.get_name() == &"Web":
		# way too heavy for webxr
		$ScrollContainer/VBox/glare.hide()
		
func _update_backgrounds() -> void:
	var selected := 0
	background_texture_control.clear()
	for i in len(Settings.BACKGROUND_TEXTURES):
		background_texture_control.add_item(Settings.BACKGROUND_TEXTURES[i][1])
		if Settings.background_texture == Settings.BACKGROUND_TEXTURES[i][0]:
			selected = i
	var dir := DirAccess.open(Constants.APPDATA_PATH + "Backgrounds")
	var i := len(Settings.BACKGROUND_TEXTURES)
	if dir:
		dir.list_dir_begin()
		var name := dir.get_next()
		while name != "":
			if not dir.current_is_dir():
				background_texture_control.add_item(name)
				if Settings.background_texture == name:
					selected = i
				i += 1
			name = dir.get_next()
	background_texture_control.selected = selected
	background_texture_control.connect("item_selected", _on_background_texture_selected)
	
func set_controls_from_settings() -> void:
	saber_control.clear()
	for s in Settings.SABER_VISUALS:
		saber_control.add_item(s[0])
	
	show_collisions.button_pressed = get_tree().debug_collisions_hint
	show_collisions.visible = OS.is_debug_build()
	
	# set the selections to the loaded values
	await get_tree().process_frame
	saber_thickness.value = Settings.thickness
	cut_blocks.button_pressed = Settings.cube_cuts_falloff
	left_saber_col.color = Settings.color_left
	right_saber_col.color = Settings.color_right
	saber_tail_control.button_pressed = Settings.saber_tail
	glare_control.button_pressed = Settings.glare
	saber_control.select(Settings.saber_visual)
	show_debug_control.button_pressed = Settings.show_debug_info
	mixed_reality_control.button_pressed = Settings.mixed_reality
	explain_control.button_pressed = Settings.explain
	left_handed_control.button_pressed = Settings.left_handed
	not_music_dl_control.button_pressed = Settings.not_music_dl
	swing_scoring_control.button_pressed = Settings.swing_scoring
	ui_volume_slider.value = Settings.ui_volume
	disable_map_color_control.button_pressed = Settings.disable_map_color
	left_saber_posx_control.value = Settings.left_saber_offset_pos.x
	left_saber_posy_control.value = Settings.left_saber_offset_pos.y
	left_saber_posz_control.value = Settings.left_saber_offset_pos.z
	left_saber_rotx_control.value = Settings.left_saber_offset_rot.x
	left_saber_roty_control.value = Settings.left_saber_offset_rot.y
	left_saber_rotz_control.value = Settings.left_saber_offset_rot.z
	right_saber_posx_control.value = Settings.right_saber_offset_pos.x
	right_saber_posy_control.value = Settings.right_saber_offset_pos.y
	right_saber_posz_control.value = Settings.right_saber_offset_pos.z
	right_saber_rotx_control.value = Settings.right_saber_offset_rot.x
	right_saber_roty_control.value = Settings.right_saber_offset_rot.y
	right_saber_rotz_control.value = Settings.right_saber_offset_rot.z
	player_height_offset_control.value = Settings.player_height_offset
	audio_master_control.value = Settings.audio_master
	audio_music_control.value = Settings.audio_music
	audio_music_preview_control.value = Settings.audio_music_preview
	audio_sfx_control.value = Settings.audio_sfx
	spectator_view_control.button_pressed = Settings.spectator_view
	spectator_hud_control.button_pressed = Settings.spectator_hud

func _restore_defaults() -> void:
	Settings.restore_defaults()
	set_controls_from_settings()

#settings down here
func _on_thickness_value_changed(value: float) -> void:
	Settings.thickness = value

func _on_cut_blocks_toggled(button_pressed: bool) -> void:
	Settings.cube_cuts_falloff = button_pressed

func _on_left_saber_color_changed(color: Color) -> void:
	Settings.color_left = color

func _on_right_saber_color_changed(color: Color) -> void:
	Settings.color_right = color

func _on_saber_tail_toggled(button_pressed: bool) -> void:
	Settings.saber_tail = button_pressed

func _on_glare_toggled(button_pressed: bool) -> void:
	Settings.glare = button_pressed

func _on_saber_item_selected(index: int) -> void:
	Settings.saber_visual = index

func _on_show_debug_toggled(button_pressed: bool) -> void:
	Settings.show_debug_info = button_pressed

func _on_mixed_reality_toggled(button_pressed: bool) -> void:
	Settings.mixed_reality = button_pressed
	MixedReality.set_mixed_reality(Settings.mixed_reality)

func _on_explain_toggled(button_pressed: bool) -> void:
	Settings.explain = button_pressed

func _on_swing_scoring_toggled(button_pressed: bool) -> void:
	Settings.swing_scoring = button_pressed

func _on_ui_volume_slider_value_changed(value: float) -> void:
	UI_AudioEngine.set_volume(linear_to_db(float(value)/10.0))
	if _play_ui_sound_demo:
		UI_AudioEngine.play_click()
	
	Settings.ui_volume = value

func _on_left_saber_pos_x_changed(value: float) -> void:
	Settings.left_saber_offset_pos.x = value

func _on_left_saber_pos_y_changed(value: float) -> void:
	Settings.left_saber_offset_pos.y = value

func _on_left_saber_pos_z_changed(value: float) -> void:
	Settings.left_saber_offset_pos.z = value

func _on_left_saber_rot_x_changed(value: float) -> void:
	Settings.left_saber_offset_rot.x = value

func _on_left_saber_rot_y_changed(value: float) -> void:
	Settings.left_saber_offset_rot.y = value

func _on_left_saber_rot_z_changed(value: float) -> void:
	Settings.left_saber_offset_rot.z = value

func _on_right_saber_pos_x_changed(value: float) -> void:
	Settings.right_saber_offset_pos.x = value

func _on_right_saber_pos_y_changed(value: float) -> void:
	Settings.right_saber_offset_pos.y = value

func _on_right_saber_pos_z_changed(value: float) -> void:
	Settings.right_saber_offset_pos.z = value

func _on_right_saber_rot_x_changed(value: float) -> void:
	Settings.right_saber_offset_rot.x = value

func _on_right_saber_rot_y_changed(value: float) -> void:
	Settings.right_saber_offset_rot.y = value

func _on_right_saber_rot_z_changed(value: float) -> void:
	Settings.right_saber_offset_rot.z = value

func _on_player_height_offset_changed(value: float) -> void:
	Settings.player_height_offset = value

func _on_disable_map_color_toggled(toggled_on: bool) -> void:
	Settings.disable_map_color = toggled_on
	
func _force_update_show_coll_shapes(node: Node) -> void:
	# toggle enable to make engine show collision shapes
	if node is CollisionShape3D:
		var col := node as CollisionShape3D
		col.disabled = not col.disabled
		col.disabled = not col.disabled
	elif node is RayCast3D:
		var ray := node as RayCast3D
		ray.enabled = not ray.enabled
		ray.enabled = not ray.enabled
	
	for c in node.get_children():
		_force_update_show_coll_shapes(c)

func _on_show_collisions_toggled(button_pressed: bool) -> void:
	get_tree().debug_collisions_hint = button_pressed
	# must toggle 
	_force_update_show_coll_shapes(get_tree().root)

func _on_apply_pressed() -> void:
	Settings.save()
	apply.emit()
	left_saber_col.get_popup().hide()
	right_saber_col.get_popup().hide()
	left_saber_col_state = false
	right_saber_col_state = false

func _on_master_slider_value_changed(value: float) -> void:
	Settings.audio_master = value

func _on_music_slider_value_changed(value: float) -> void:
	Settings.audio_music = value

func _on_music_preview_slider_value_changed(value: float) -> void:
	Settings.audio_music_preview = value

func _on_sfx_slider_value_changed(value: float) -> void:
	Settings.audio_sfx = value

func _on_spectator_view_toggled(value: bool) -> void:
	Settings.spectator_view = value

func _on_spectator_hud_toggled(value: bool) -> void:
	Settings.spectator_hud = value


func _on_recenter_button_up() -> void:
	var recenter_button : Button = $ScrollContainer/VBox/recenter
	recenter_button.disabled = true
	recenter_button.text = "3.."
	await get_tree().create_timer(1).timeout
	recenter_button.text = "2.."
	await get_tree().create_timer(1).timeout
	recenter_button.text = "1.."
	await get_tree().create_timer(1).timeout
	recenter_button.text = "Recenter"
	recenter_button.disabled = false
	beepsaber_game.recenter()

func _on_left_saber_col_pressed() -> void:
	if left_saber_col_state:
		left_saber_col.get_popup().hide()
	left_saber_col_state = not left_saber_col_state

func _on_right_saber_col_pressed() -> void:
	if right_saber_col_state:
		right_saber_col.get_popup().hide()
	right_saber_col_state = not right_saber_col_state

func _on_not_music_dl_toggled(button_pressed: bool) -> void:
	Settings.not_music_dl = button_pressed

func _on_simple_toggled(button_pressed: bool) -> void:
	if button_pressed:
		Settings.background = "simple"

func _on_dynamic_toggled(button_pressed: bool) -> void:
	if button_pressed:
		Settings.background = "dynamic"

func _on_static_toggled(button_pressed: bool) -> void:
	if button_pressed:
		Settings.background = "static"

func _on_background_texture_selected(item: int) -> void:
	if item < len(Settings.BACKGROUND_TEXTURES):
		Settings.background_texture = Settings.BACKGROUND_TEXTURES[item][0]
	else:
		Settings.background_texture = background_texture_control.get_item_text(item)

func _on_background_mode_selected(item: int) -> void:
	Settings.background = Settings.BACKGROUND_MODES[item][0]

func _on_left_handed_toggled(value: bool) -> void:
	Settings.left_handed = value
