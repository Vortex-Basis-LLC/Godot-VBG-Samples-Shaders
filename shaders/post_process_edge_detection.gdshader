shader_type spatial;
render_mode skip_vertex_transform, unshaded;

uniform sampler2D screen_texture: hint_screen_texture, filter_nearest;
uniform sampler2D normal_texture: hint_normal_roughness_texture, filter_nearest;
uniform sampler2D depth_texture: source_color, hint_depth_texture, filter_nearest;

// Adjust approximate line width by changing how far apart pixel samples are.
uniform int line_width = 3;

// See usage below. Adjust to taste.
uniform float depth_diff_scalar = 1000.0;
uniform float depth_diff_power = 2.0;

// See usage below. Adjust to taste.
uniform float normal_diff_scalar = 20.0;
uniform float normal_diff_power = 3.0;



void vertex(){
	// Place the post-processing mesh surface directly in front of the camera.
	// The coordinates of the mesh should already be in NDC space.
	POSITION = vec4(VERTEX, 1.0);
}


void fragment() {
	// The original final color of the rendered pixel.
	vec3 original_color = texture(screen_texture, SCREEN_UV).rgb;
	
	// Normal of the pixel relative to the camera position, but values range 
	// from 0 to 1. Multiply xyz component by 2.0 and subtract 1.0 to get the 
	// actual direction. The w component is the roughness.
	vec4 normal_color = texture(normal_texture, SCREEN_UV);
	
	
	// NOTE: If the depth-value is exactly one, the pixel is probably part of the skybox.
	float depth_value = texture(depth_texture, SCREEN_UV).x;
	if (depth_value < 1.0) {
		vec2 pixel_size = 1.0 / VIEWPORT_SIZE;
		
		// TODO: Add a mode where depth_value is converted into actual depth value with inverse
		// perspective matrix prior to doing comparisons. The current method doesn't work well
		// when objects are close to camera.
		
		// Calculate difference amount based on depth.
		float depth_diff_total = 0.0;
		float depth;
		
		depth = texelFetch(depth_texture, ivec2(FRAGCOORD.xy) + ivec2(-line_width, 0), 0).r;
		depth_diff_total += abs(depth - depth_value);
		
		depth = texelFetch(depth_texture, ivec2(FRAGCOORD.xy) + ivec2(line_width, 0), 0).r;	
		depth_diff_total += abs(depth - depth_value);
		
		depth = texelFetch(depth_texture, ivec2(FRAGCOORD.xy) + ivec2(0, -line_width), 0).r;	
		depth_diff_total += abs(depth - depth_value);
		
		depth = texelFetch(depth_texture, ivec2(FRAGCOORD.xy) + ivec2(0, line_width), 0).r;	
		depth_diff_total += abs(depth - depth_value);

		float delta_diff_scaled = pow(depth_diff_total * depth_diff_scalar, depth_diff_power);
		
		
		// Calculate difference amount based on normals.
		float normal_diff_total = 0.0;
		vec3 other_normal_color, normal_diff;
		
		other_normal_color = texelFetch(normal_texture, ivec2(FRAGCOORD.xy) + ivec2(-line_width, 0), 0).rgb;
		normal_diff = (normal_color.rgb - other_normal_color);
		normal_diff_total += dot(normal_diff, normal_diff);
		
		other_normal_color = texelFetch(normal_texture, ivec2(FRAGCOORD.xy) + ivec2(line_width, 0), 0).rgb;
		normal_diff = (normal_color.rgb - other_normal_color);
		normal_diff_total += dot(normal_diff, normal_diff);
		
		other_normal_color = texelFetch(normal_texture, ivec2(FRAGCOORD.xy) + ivec2(0, -line_width), 0).rgb;
		normal_diff = (normal_color.rgb - other_normal_color);
		normal_diff_total += dot(normal_diff, normal_diff);
		
		other_normal_color = texelFetch(normal_texture, ivec2(FRAGCOORD.xy) + ivec2(0, line_width), 0).rgb;
		normal_diff = (normal_color.rgb - other_normal_color);
		normal_diff_total += dot(normal_diff, normal_diff);
		
		float normal_diff_scaled = pow(normal_diff_total * normal_diff_scalar, normal_diff_power);

		// Determine which diff value to use.
		float diff_total_to_use = max(delta_diff_scaled, normal_diff_scaled);
		
		ALBEDO = mix(original_color, vec3(0.0), clamp(diff_total_to_use, 0.0, 1.0));
	}
	else {
		ALBEDO = original_color;
	}
}