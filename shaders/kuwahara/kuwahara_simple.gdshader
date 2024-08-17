shader_type spatial;
render_mode skip_vertex_transform, unshaded;

uniform sampler2D screen_texture: hint_screen_texture, filter_nearest;
uniform sampler2D normal_texture: hint_normal_roughness_texture, filter_nearest;
uniform sampler2D depth_texture: source_color, hint_depth_texture, filter_nearest;

uniform ivec2 window_size = ivec2(5,3);

void vertex() 
{
	// Place the post-processing mesh surface directly in front of the camera.
	// The coordinates of the mesh should already be in NDC space.
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}


// Kuwahara filter will calculate the mean/variance for 4 quadrants around a pixel
// and then use the mean color for the quadrant that has the lowest variance.

vec4 calc_mean_and_variance_for_window(sampler2D sampler, vec2 uv, ivec2 window_x, ivec2 window_y, vec2 pixel_size)
{
    vec3 total = vec3(0.0);    
    int count = 0;    
    for (int i = window_x.x; i <= window_x.y; i++)
    {
        for (int j = window_y.x; j <= window_y.y; j++)
        {
            vec2 uv_offset = (vec2(float(i),float(j)) * pixel_size);
            vec2 sample_uv = uv + uv_offset;
            vec3 col = texture(sampler, sample_uv).rgb;

            total += col;            
            count++;
        }
    }
    
    vec3 mean = total / float(count);
    
    // Calculate variance.    
    float square_diff_total = 0.0;
    {
        for (int i = window_x.x; i <= window_x.y; i++)
        {
            for (int j = window_y.x; j <= window_y.y; j++)
            {
                vec2 uv_offset = (vec2(float(i),float(j)) * pixel_size);
                vec2 sample_uv = uv + uv_offset;
                vec3 col = texture(sampler, sample_uv).rgb;

                vec3 diff_from_mean = col - mean;
				float component_diff = abs(diff_from_mean.x) + abs(diff_from_mean.y) + abs(diff_from_mean.z);
                square_diff_total += component_diff * component_diff;
            }
        }
    }

    float variance = square_diff_total / float(count); 
    return vec4(mean.r, mean.g, mean.b, variance);
}


void fragment() {
	// The original final color of the rendered pixel.
	vec3 original_color = texture(screen_texture, SCREEN_UV).rgb;
	
	// Kuwahara filter calculates mean/variance for 4 quadrants around a pixel
	// and then use the mean color for the quadrant that has the lowest variance.	

	vec2 pixel_size = 1.0 / VIEWPORT_SIZE;

	vec2 uv = SCREEN_UV;
	int window_size_x = window_size.x;
	int window_size_y = window_size.y;

	// For each quadrant, xyz will be mean color and w will be the variation.
	vec4 quadrant1 = calc_mean_and_variance_for_window(screen_texture, uv, ivec2(-window_size_x, 0), ivec2(-window_size_y, 0), pixel_size);
	vec4 quadrant2 = calc_mean_and_variance_for_window(screen_texture, uv, ivec2(0, window_size_x), ivec2(-window_size_y, 0), pixel_size);
	vec4 quadrant3 = calc_mean_and_variance_for_window(screen_texture, uv, ivec2(-window_size_x, 0), ivec2(0, window_size_y), pixel_size);
	vec4 quadrant4 = calc_mean_and_variance_for_window(screen_texture, uv, ivec2(0, window_size_x), ivec2(0, window_size_y), pixel_size);

	// Use the mean color from quadrant with lowest variation.
	vec3 mean_to_use = quadrant1.rgb;
	float min_variation_seen = quadrant1.a;

	if (quadrant2.a < min_variation_seen)
	{
	    mean_to_use = quadrant2.rgb;
	    min_variation_seen = quadrant2.a;
	}
	if (quadrant3.a < min_variation_seen)
	{
	    mean_to_use = quadrant3.rgb;
	    min_variation_seen = quadrant3.a;
	}
	if (quadrant4.a < min_variation_seen)
	{
	    mean_to_use = quadrant4.rgb;
	    min_variation_seen = quadrant4.a;
	}

	ALBEDO = mean_to_use;	
}

