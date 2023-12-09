shader_type spatial;

uniform sampler2D noise_tex: repeat_enable, filter_linear_mipmap;

uniform vec3 base_color: source_color = vec3(0.3, 0.6, 0.3);

uniform float roughness_min = 0.35;
uniform float roughness_max = 1.0;


void fragment() {
	float noise = texture(noise_tex, UV).r;

	ALBEDO = base_color;
	METALLIC = 0.0;
	ROUGHNESS = (noise * (roughness_max - roughness_min)) + roughness_min;
}
