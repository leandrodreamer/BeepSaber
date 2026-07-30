shader_type spatial;
render_mode unshaded, cull_back;
uniform vec3 color;
uniform float how_full;

void fragment() {
	if (how_full < 0.005) {
		discard;
	}
	float x = UV.x - 0.5;
	float y = UV.y - 0.5;
	float dist_from_center_squared = x*x + y*y;
	if (dist_from_center_squared <= 0.125 || dist_from_center_squared > 0.25) {
		discard;
	}
	if (how_full < 0.995 && atan(x,y) + PI > how_full * TAU) {
		discard;
	}
	ALBEDO = color; // vec3(1.0);
}
