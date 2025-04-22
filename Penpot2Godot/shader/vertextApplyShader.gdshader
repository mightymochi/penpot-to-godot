shader_type canvas_item;

uniform sampler2D image_texture : source_color, filter_linear, repeat_disable;
uniform sampler2D gradient_texture : source_color, filter_linear, repeat_disable;
uniform bool use_gradient = false;
uniform bool use_image = false;
uniform bool use_solid = true;
uniform bool gradient_behind = false;
uniform vec4 target_color : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform float tolerance : hint_range(0.001, 1.0,0.001) = 0.001;
uniform vec4 new_bg_color : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec2 node_size;
uniform vec2 texture_size;
uniform float texture_scale : hint_range(0.0, 6.0) = 1.0;
uniform vec2 stretch = vec2(1.0);
uniform vec2 offset = vec2(0.0);
uniform bool flip_x = false;
uniform bool flip_y = false;
uniform bool keep_aspect = true;
uniform bool fill_rect = true;
uniform bool tile_texture = false;
uniform bool manual_scale = false;
uniform vec2 vert_offset = vec2(0.0, 0.0);

varying vec4 vertex_color;
varying vec4 modulated_color;

void vertex() {
    vertex_color = COLOR;
	VERTEX.xy += vert_offset;
	modulated_color = vertex_color / target_color;
}

void fragment() {
	float x_dir = flip_x ? -1.0 : 1.0;
    float y_dir = flip_y ? -1.0 : 1.0;
	vec2 uv = (UV / stretch - offset);
	float texture_aspect = texture_size.x / texture_size.y;
	float viewport_aspect = node_size.x / node_size.y;
	if (keep_aspect && !manual_scale) {
		if (fill_rect) {
			if (texture_aspect < viewport_aspect) {
				uv.y = (uv.y - 0.5) * (texture_aspect / viewport_aspect) + 0.5;
			} else {
				uv.x = (uv.x - 0.5) * (viewport_aspect / texture_aspect) + 0.5;
			}
		} else {
			if (texture_aspect > viewport_aspect) {
				uv.y = (uv.y - 0.5) * (texture_aspect / viewport_aspect) + 0.5;
			} else {
				uv.x = (uv.x - 0.5) * (viewport_aspect / texture_aspect) + 0.5;
			}
		}
	}
	uv -= 0.5;
    uv *= vec2(x_dir, y_dir);
    if (manual_scale) {
        uv /= (vec2(texture_size) / vec2(node_size)) * texture_scale;
    } else {
        uv /= texture_scale;
    }
    uv += 0.5;
	if (tile_texture) {
        uv = fract(uv);
    }
	vec4 image = texture(image_texture, uv);
	vec4 gradient =  texture(gradient_texture,UV);
	if (distance(vertex_color.rgb, target_color.rgb) < tolerance) {
		if (use_solid) { COLOR = new_bg_color; }
		if (gradient_behind && use_gradient) {
			if (use_solid) { COLOR.rgb = mix(COLOR.rgb, gradient.rgb, gradient.a); } else { COLOR = gradient; }
		}
		if (use_image) {
			if (use_solid || gradient_behind) { COLOR = mix(COLOR, tint_color * image, image.a); } else { COLOR = tint_color * image; }
		}
		if (!gradient_behind && use_gradient) {
			if(use_image || use_solid) { COLOR.rgb = mix(COLOR.rgb, gradient.rgb, gradient.a); } else { COLOR = gradient; }
		}
		COLOR *= modulated_color.a;
	}
}