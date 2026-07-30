extends Node

var floor_albedo_texture : Texture2D = null
	
func set_mixed_reality(mr: bool):
	var xr_interface := XRServer.find_interface("OpenXR") as XRInterface
	if xr_interface and xr_interface.is_passthrough_supported():
		if mr:
			if xr_interface.start_passthrough():
				get_viewport().transparent_bg = true
				xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND
				print("BeepSaber: MR")
		else:
			xr_interface.stop_passthrough()
			get_viewport().transparent_bg = false
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_OPAQUE
			
			
	var cut_floor := get_node("/root/BeepSaber/StandingGround/Node3D/cutFloor") as MeshInstance3D
	var material := cut_floor.material_override as StandardMaterial3D
	
	if floor_albedo_texture == null:
		floor_albedo_texture = material.albedo_texture

	if mr:
		material.transparency = 1
		material.albedo_texture = null
		material.albedo_color = Color(0,0,0,.6)
		get_node("/root/BeepSaber/event_driver/Level/Sphere").hide()
		get_node("/root/BeepSaber/Multiplier_Label/Text_Background").show()
		get_node("/root/BeepSaber/Point_Label/Text_Background2").show()
	else:
		material.transparency = 0
		material.albedo_texture = floor_albedo_texture
		get_node("/root/BeepSaber/event_driver/Level/Sphere").show()
		get_node("/root/BeepSaber/Multiplier_Label/Text_Background").hide()
		get_node("/root/BeepSaber/Point_Label/Text_Background2").hide()
	
	material = (get_node("/root/BeepSaber/event_driver/Level/floor") as MeshInstance3D).material_override as StandardMaterial3D
	var gradient_texture := material.albedo_texture as GradientTexture2D
	var gradient := gradient_texture.gradient
	for i in gradient.get_point_count():
		var c := gradient.get_color(i)
		if Settings.mixed_reality:
			gradient.set_color(i, Color(c.r,c.g,c.b,0.6))
		else:
			gradient.set_color(i, Color(c.r,c.g,c.b))

		
