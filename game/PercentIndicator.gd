extends MeshInstance3D
class_name PercentIndicator

var how_full := 0.0
var how_full_display := 0.0
var label: TextMesh
var shader: ShaderMaterial
var health: bool

func _ready() -> void:
	shader = material_override as ShaderMaterial
	var label_instance = $PercentLabel as MeshInstance3D
	label = label_instance.mesh as TextMesh
	label_instance.layers = layers

func set_health_mode(_health: bool) -> void:
	health = _health
	if health:
		label.text = ""
	else:
		shader.set_shader_parameter(&"color", Vector3(1.,1.,1.))

func _process(delta: float) -> void:
	how_full_display = lerpf(how_full_display, how_full, delta*8)
	shader.set_shader_parameter(&"how_full", how_full_display)
	if health:
		shader.set_shader_parameter(&"color", Vector3(1-how_full,how_full,0.))

func start_map() -> void:
	how_full = 1.0
	how_full_display = 0.0
	label.text = "" if health else "100%" 

func endscore() -> void:
	how_full = 0.0
	how_full_display = 0.0
	label.text = "" if health else "0%"

func update_percent(amount: float) -> void:
	how_full = amount
	var display = "" if health else "%d%%" % int(amount * 100)
	if label.text != display:
		label.text = display
