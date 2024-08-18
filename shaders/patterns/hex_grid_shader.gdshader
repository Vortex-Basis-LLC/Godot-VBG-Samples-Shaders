shader_type spatial;

uniform float cell_size = 1.;

uniform vec2 uv_scale = vec2(20);
uniform vec2 uv_offset = vec2(0.0);

// We could be more precise with distance from edge of the
// hexagon, but this approximation gives some nice variation on
// the thickness of the edge mask.
uniform float edge_threshold = 0.7;
uniform float edge_mask_diff_start = 0.;
uniform float edge_mask_diff_end = 0.01;

// NOTE: The Red Blob Games blog has a good article covering the different
//   coordinate systems for hex grids and formulas for working with them.
//   URL: https://www.redblobgames.com/grids/hexagons/

float rand_float_from_vec2(vec2 v) {
	float w = dot(v, vec2(12.9898, 78.233));
    return fract(sin(w) * 43758.5453);
}

vec3 uv_to_hex_coords_floating(vec2 uv) {
	float q = (sqrt(3.)/3. * uv.x - 1./3. * uv.y) / cell_size;
	float r = (2./3. * uv.y) / cell_size;
	return vec3(q,r,-q-r);
}

// Given a floating set of hex cube coordinates, round to center of the hexagon
// and just so happen to return a mask for the edge at the same time.
vec3 round_hex_coords(vec3 coords, out float edge_mask) {
	float q = round(coords.x);
	float r = round(coords.y);
	float s = round(coords.z);

	float q_diff = abs(q - coords.x);
	float r_diff = abs(r - coords.y);
	float s_diff = abs(s - coords.z);

	if (q_diff > r_diff && q_diff > s_diff) {
		q = -r-s;

		// Setup edge mask.
		float diff_y = abs(max(r_diff, s_diff));
		float diff_x = abs(q - coords.x);
		float diff = edge_threshold - length(vec2(diff_x, diff_y));
		edge_mask = 1.0 - smoothstep(edge_mask_diff_start, edge_mask_diff_end, diff);
	} else if (r_diff > s_diff) {
		r = -q-s;

		// Setup edge mask.
		float diff_y = abs(max(q_diff, s_diff));
		float diff_x = abs(r - coords.y);
		float diff = edge_threshold - length(vec2(diff_x, diff_y));
		edge_mask = 1.0 - smoothstep(edge_mask_diff_start, edge_mask_diff_end, diff);
	} else {
		s = -q-r;

		// Setup edge mask.
		float diff_y = abs(max(q_diff, r_diff));
		float diff_x = abs(s - coords.z);
		float diff = edge_threshold - length(vec2(diff_x, diff_y));
		edge_mask = 1.0 - smoothstep(edge_mask_diff_start, edge_mask_diff_end, diff);
	}

	// NOTE: The following calculation will return a turtle shell looking mask.
	// float turtle_shell_mask = min(min(q_diff, r_diff), s_diff);

	return vec3(q,r,s);
}

vec2 hex_coord_to_uv(vec3 hex_coord) {
    float u = cell_size * (sqrt(3.) * hex_coord.x + sqrt(3.)/2. * hex_coord.y);
    float v = cell_size * (3./2. * hex_coord.y);
    return vec2(u, v);
}

void vertex() {
}


void fragment() {
	vec2 uv = UV * uv_scale + uv_offset;

	vec3 hex_coords_floating = uv_to_hex_coords_floating(uv);
	float edge_mask;
	vec3 hex_coords = round_hex_coords(hex_coords_floating, edge_mask);
	vec3 hex_offset = abs(hex_coords_floating - hex_coords);

	// the following gives a pattern of holes at the center of each hexagon.
	float edge_offset = max(max(hex_offset.x, hex_offset.y), hex_offset.z);
	float center_mask = 1.0 - smoothstep(0.1, 0.15, edge_offset);

	// NOTE: The following calculation will return a mask with pattern of little
	// triangles in between the center points (try a value of 0.5 or more for step start).
	// float triangle_corner_mask = smoothstep(0.55, 0.66, edge_offset);

	float cell_rand_value = rand_float_from_vec2(hex_coords.xy);

	ALBEDO = vec3(center_mask, edge_mask, cell_rand_value * (1.0 - edge_mask));
}

