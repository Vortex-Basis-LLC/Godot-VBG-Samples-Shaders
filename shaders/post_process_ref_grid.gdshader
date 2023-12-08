shader_type spatial;
render_mode skip_vertex_transform, unshaded;

uniform sampler2D screen_texture: hint_screen_texture, filter_nearest;
uniform sampler2D normal_texture: hint_normal_roughness_texture, filter_nearest;
uniform sampler2D depth_texture: source_color, hint_depth_texture, filter_nearest;

// grid_mode enum
//   0 = Off
//   1 = World Space Grid
//   2 = View Space Grid
uniform int grid_mode = 1;

// grid_origin indicates coordinates in chosen space where grid should originate.
uniform vec3 grid_origin = vec3(0.0);

// grid_scale indicates how many units are between each line.
uniform float grid_scale = 1.0;

// When viewing depth or distance-based modes, the pixel scolor will go from
// black to white as value goes from depth_min to depth_max.
uniform float depth_min = 0.0;
uniform float depth_max = 50.0;

// Mode enum
//   0 = Pass-Through (same as regular color)
//   1 = Black (makes it easier to see the grid)
//   2 = Roughness
//   3 = World Space Normal
//   4 = View Space Normal
//   5 = Depth (visualization of view space z coordinate)
//   6 = Distance to Camera
uniform uint mode = 0;


void vertex(){
	// Place the post-processing mesh surface directly in front of the camera.
	// The coordinates of the mesh should already be in NDC space.
	POSITION = vec4(VERTEX, 1.0);
}

// get_grid_color will create a grid pattern with a thin line along each unit of movement
// on each axis. The value from 0 to 1 on each axis will be filled with a gradient to make
// it possible to tell where the origin is.
vec3 get_grid_color(vec3 pos, float scale, vec3 original_color) {
	pos -= grid_origin;
	vec3 cell_pos = fract(pos / scale);
	
	float thickness = 0.05 / scale;
		
	vec3 grid_color = vec3(0.0);
		
	grid_color.x = step(cell_pos.x, thickness);
	grid_color.y = step(cell_pos.y, thickness);
	grid_color.z = step(cell_pos.z, thickness);
	
	// Add a gradient band from 0 to 1, so you can see where the origin is.
	if (pos.x >= 0.0 && pos.x < 1.0) {
		grid_color.x = pos.x;
	}
	
	if (pos.y >= 0.0 && pos.y < 1.0) {
		grid_color.y = pos.y;
	}
	
	if (pos.z >= 0.0 && pos.z < 1.0) {
		grid_color.z = pos.z;
	}
	
	if (grid_color == vec3(0)) {
		grid_color = original_color;
	}
	
	return grid_color;
}


float map_depth_to_depth_ratio(float depth) {
	float depth_ratio = clamp((depth - depth_min) / (depth_max - depth_min), 0.0, 1.0);
	return depth_ratio;
}


void fragment() {
	// The original final color of the rendered pixel.
	vec3 original_color = texture(screen_texture, SCREEN_UV).rgb;
	
	// Normal of the pixel relative to the camera position, but values range 
	// from 0 to 1. Multiply xyz component by 2.0 and subtract 1.0 to get the 
	// actual direction. The w component is the roughness.
	vec4 normal_color = texture(normal_texture, SCREEN_UV);
	
	// Normal vector for the pixel in viewspace.
	vec3 normal_in_viewspace = normal_color.xyz * 2.0 - 1.0;
	
	// Roughness value of the original rendered pixel.
	float roughness =  normal_color.w;
	
	// NOTE: If the depth-value is exactly one, the pixel is probably part of the skybox.
	float depth_value = texture(depth_texture, SCREEN_UV).x;
	if (depth_value < 1.0) {	
		// ndc is the normalized device coordinates in clip space.
		vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_value);
		
		vec4 view_vec = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
		// pos_in_viewspace is the 3D coordinates of the pixel in viewspace as 
		// derived from NDC coordinates and depth texture.
		vec3 pos_in_viewspace = view_vec.xyz / view_vec.w;
		
		// pos_in_worldspace is the 3D coordinates of the pixel in viewspace.
		// INV_VIEW_MATRIX moves positions from viewspace to worldspace.
		vec3 pos_in_worldspace = (INV_VIEW_MATRIX * vec4(pos_in_viewspace, 1.0)).xyz;
		
		// view_to_world_normal_mat will convert directional vectors in viewspace into
		// directional vectors in worldspace.
		mat3 view_to_world_normal_mat = mat3(
			INV_VIEW_MATRIX[0].xyz, 
			INV_VIEW_MATRIX[1].xyz,
			INV_VIEW_MATRIX[2].xyz);
		
		// normal_in_worldspace is the normal vector of the pixel in world space.
		vec3 normal_in_worldspace = view_to_world_normal_mat * normal_in_viewspace;

		// camera_pos_in_worldspace is position of the camera in world space.
		vec3 camera_pos_in_worldspace = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
		float distance_to_camera = length(camera_pos_in_worldspace - pos_in_worldspace);

		switch (mode) {
			// 0 = Pass-Through (same as regular color)
			case 0: ALBEDO = original_color; break;
			// 1 = Black (makes it easier to see the grid)
			case 1: ALBEDO = vec3(0.0); break;
			// 2 = Roughness			
			case 2: ALBEDO = vec3(roughness); break;
			// 3 = World Space Normal
			case 3: ALBEDO = normal_in_worldspace; break;
			// 4 = View Space Normal
			case 4: ALBEDO = normal_in_viewspace; break;
			// 5 = Depth (visualization of view space z coordinate)
			case 5:
				ALBEDO = vec3(map_depth_to_depth_ratio(-pos_in_viewspace.z));
				break;
			// 6 = Distance to Camera
			case 6:
				ALBEDO = vec3(map_depth_to_depth_ratio(distance_to_camera));
				break;
		};

		if (grid_mode == 1) {
			ALBEDO = get_grid_color(pos_in_worldspace, grid_scale, ALBEDO);
		}
		else if (grid_mode == 2) {
			ALBEDO = get_grid_color(pos_in_viewspace, grid_scale, ALBEDO);
		}
	}
	else {
		ALBEDO = original_color;
	}
}