// SOURCE REFERENCE: https://godotforums.org/d/32248-create-trees-with-wind-effect
// MORE INFO: https://developer.nvidia.com/gpugems/gpugems3/part-iii-rendering/chapter-16-vegetation-procedural-animation-and-shading-crysis

shader_type spatial;
render_mode depth_prepass_alpha, cull_disabled, world_vertex_coords;

uniform sampler2D texture_albedo : source_color;

global uniform float sway_speed;
global uniform float sway_strength;
global uniform float sway_phase_len;

void vertex() {
    float strength = COLOR.b * sway_strength;
    VERTEX.x += sin(VERTEX.x * sway_phase_len * 1.123 + TIME * sway_speed) * strength;
    VERTEX.y += sin(VERTEX.y * sway_phase_len + TIME * sway_speed * 1.12412) * strength;
    VERTEX.z += sin(VERTEX.z * sway_phase_len * 0.9123 + TIME * sway_speed * 1.3123) * strength;
}

void fragment() {
    vec4 albedo_tex = texture(texture_albedo, UV);
    ALBEDO = albedo_tex.rgb;
	
    ALPHA = albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD = 0.15;
	
    METALLIC = 0.0;
    ROUGHNESS = 1.0;    
}