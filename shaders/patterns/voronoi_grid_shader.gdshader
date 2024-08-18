shader_type spatial;

uniform vec2 uv_scale = vec2(8.0);
uniform vec2 uv_offset = vec2(0.);

// Enabling this will allow the pattern to tile.
uniform bool mod_cell_coords_with_scale = true;

float rand_float_from_vec2(vec2 v) {
	float w = dot(v, vec2(12.9898, 78.233));
    return fract(sin(w) * 43758.5453);
}

vec2 rand_vec2_from_vec2(vec2 v) {
	vec2 w = vec2(
		dot(v, vec2(12.9898, 78.233)),
		// NOTE: Made up numbers that should have large common multiple.
		dot(v, vec2(235.12, 174.842))
	);
	return fract(sin(w) * 43758.5453);
}

vec2 get_cell_center(vec2 p, out float cell_rand) {
	vec2 ip = floor(p);

	vec2 cell_coords = ip;
	if (mod_cell_coords_with_scale) {
		cell_coords = mod(cell_coords, uv_scale);
	}

	vec2 rand_vec = rand_vec2_from_vec2(cell_coords);
	vec2 offset = rand_vec * 0.49;
	cell_rand = clamp(rand_vec.x, 0., 1.);

	return ip + vec2(0.5) + offset;
}

void get_voronoi_grid_values(vec2 p, out float dist, out float cell_rand) {
	// TODO: Return cell_offset to as part of voronoi struct.
	vec2 cell_offset;

	// Determine the cell which contains the closest center point. We assume
	// this must be in one of the immediate neighboring cells for this to
	// work as intended.
	dist = 100.0;
	for (float i = -1.0; i <= 1.0; i = i + 1.0) {
		for (float j = -1.0; j <= 1.0; j = j + 1.0) {
			float out_cell_rand;
			vec2 center = get_cell_center(p + vec2(i,j), out_cell_rand);
			float center_dist = length(p - center);
			if (center_dist < dist) {
				dist = min(dist, center_dist);
				cell_rand = out_cell_rand;
				cell_offset = vec2(i,j);
			}
		}
	}
}

void vertex() {
}

void fragment() {
	float dist;
	float cell_rand;

	vec2 uv_to_use = UV * uv_scale + uv_offset;
	get_voronoi_grid_values(uv_to_use, dist, cell_rand);
	//ALBEDO = vec3(1.0 - clamp(dist, 0., 1.), cell_rand, 1.);
	ALBEDO = vec3(cell_rand);
}
