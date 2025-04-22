shader_type canvas_item;

uniform sampler2D image_texture : source_color, filter_linear, repeat_disable;
uniform sampler2D gradient_texture : source_color, filter_linear, repeat_disable;
uniform bool use_gradient = false;
uniform bool use_image = false;
uniform bool use_solid = true;
uniform bool gradient_behind = false;
varying vec4 vertex_color;
uniform vec4 new_bg_color : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec2 texture_size;
uniform float texture_scale : hint_range(0.0, 6.0) = 1.0;
uniform vec2 stretch = vec2(1.0);
uniform vec2 offset = vec2(0.0);
uniform bool flip_x = false;
uniform bool flip_y = false;
uniform bool tile_texture = false;

void fragment() {
	float x_dir = flip_x ? -1.0 : 1.0;
    float y_dir = flip_y ? -1.0 : 1.0;
	vec2 uv = (UV / stretch - offset);
	float texture_aspect = texture_size.x / texture_size.y;
	uv -= 0.5;
    uv *= vec2(x_dir, y_dir);
    uv /= texture_scale;
    uv += 0.5;
	if (tile_texture) {
        uv = fract(uv);
    }
	vec4 image = texture(image_texture, uv);
	vec4 gradient =  texture(gradient_texture,uv);

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
}