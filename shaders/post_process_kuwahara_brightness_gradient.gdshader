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
	POSITION = vec4(VERTEX, 1.0);
}


// Kuwahara filter will calculate the mean/variance for 4 quadrants around a pixel
// and then use the mean color for the quadrant that has the lowest variance.

vec4 calc_mean_and_variance_for_window(sampler2D sampler, vec2 uv, ivec2 window_x, ivec2 window_y, mat2 window_rot_matrix, vec2 pixel_size)
{
    vec3 total = vec3(0.0);    
    int count = 0;    
    for (int i = window_x.x; i <= window_x.y; i++)
    {
        for (int j = window_y.x; j <= window_y.y; j++)
        {
            vec2 uv_offset = (vec2(float(i),float(j)) * pixel_size) * window_rot_matrix;
            vec2 sample_uv = clamp(uv + uv_offset, 0.0, 1.0);
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
                vec2 uv_offset = (vec2(float(i),float(j)) * pixel_size) * window_rot_matrix;
                vec2 sample_uv = clamp(uv + uv_offset, 0.0, 1.0);
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

float get_brightness_from_color(vec3 col)
{
    // Source: https://www.w3.org/TR/AERT/#color-contrast
    return dot(col, vec3(.299, .587, .114));
}

vec2 get_sobel_brightness_gradient(sampler2D sampler, vec2 uv, vec2 pixel_size)
{    
    float gradient_x = 0.0;
    float gradient_y = 0.0;

    // -1, -1
    { 
        vec2 sample_uv = clamp(uv + (vec2(float(-1),float(-1)) * pixel_size), 0.0, 1.0);
        vec3 col = texture(sampler, sample_uv).rgb;
        float brightness = get_brightness_from_color(col);
                        
        gradient_x += -brightness;
        gradient_y += -brightness;
    }

    // -1, 0
    {
		vec2 sample_uv = clamp(uv + (vec2(float(-1),float(0)) * pixel_size), 0.0, 1.0);
		vec3 col = texture(sampler, sample_uv).rgb;		
        float brightness = get_brightness_from_color(col);
                        
        gradient_x += -2.0 * brightness;        
    }

    // -1, 1
    {
		vec2 sample_uv = clamp(uv + (vec2(float(-1),float(1)) * pixel_size), 0.0, 1.0);
		vec3 col = texture(sampler, sample_uv).rgb;		
        float brightness = get_brightness_from_color(col);
                        
        gradient_x += -brightness;   
        gradient_y += brightness;
    }

    // 0, -1
    {
		vec2 sample_uv = clamp(uv + (vec2(float(0),float(-1)) * pixel_size), 0.0, 1.0);
		vec3 col = texture(sampler, sample_uv).rgb;
        float brightness = get_brightness_from_color(col);
                         
        gradient_y += -2.0 * brightness;
    }

    // 0, 1
    {
		vec2 sample_uv = clamp(uv + (vec2(float(0),float(1)) * pixel_size), 0.0, 1.0);
		vec3 col = texture(sampler, sample_uv).rgb;
        float brightness = get_brightness_from_color(col);
                            
        gradient_y += 2.0 * brightness;
    }

    // 1, -1
    {
		vec2 sample_uv = clamp(uv + (vec2(float(1),float(-1)) * pixel_size), 0.0, 1.0);
		vec3 col = texture(sampler, sample_uv).rgb;        
        float brightness = get_brightness_from_color(col);
                        
        gradient_x += brightness;
        gradient_y += -brightness;
    }

    // 1, 0
    {
		vec2 sample_uv = clamp(uv + (vec2(float(1),float(0)) * pixel_size), 0.0, 1.0);
		vec3 col = texture(sampler, sample_uv).rgb;		
        float brightness = get_brightness_from_color(col);
                        
        gradient_x += 2.0 * brightness;             
    }

    // 1, 1
    {
		vec2 sample_uv = clamp(uv + (vec2(float(1),float(1)) * pixel_size), 0.0, 1.0);
		vec3 col = texture(sampler, sample_uv).rgb;        
        float brightness = get_brightness_from_color(col);
                        
        gradient_x += brightness;   
        gradient_y += brightness;
    }

    return vec2(gradient_x, gradient_y);
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

	vec2 gradient = get_sobel_brightness_gradient(screen_texture, uv, pixel_size);
	float gradient_len = length(gradient);
	vec2 normalized_gradient = (gradient_len == 0.0) ? vec2(0,1) : gradient / gradient_len;
	mat2 gradient_rot_mat = mat2(vec2(normalized_gradient.x, -normalized_gradient.y), vec2(normalized_gradient.y, normalized_gradient.x));

	// For each quadrant, xyz will be mean color and w will be the variation.
	vec4 quadrant1 = calc_mean_and_variance_for_window(screen_texture, uv, ivec2(-window_size_x, 0), ivec2(-window_size_y, 0), gradient_rot_mat, pixel_size);
	vec4 quadrant2 = calc_mean_and_variance_for_window(screen_texture, uv, ivec2(0, window_size_x), ivec2(-window_size_y, 0), gradient_rot_mat, pixel_size);
	vec4 quadrant3 = calc_mean_and_variance_for_window(screen_texture, uv, ivec2(-window_size_x, 0), ivec2(0, window_size_y), gradient_rot_mat, pixel_size);
	vec4 quadrant4 = calc_mean_and_variance_for_window(screen_texture, uv, ivec2(0, window_size_x), ivec2(0, window_size_y), gradient_rot_mat, pixel_size);

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

