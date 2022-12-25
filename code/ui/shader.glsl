@header package ui
@header import sg "../../../sokol-odin/sokol/gfx"

@vs vs
in vec2 position;
in vec4 color;
in vec2 uv;
in float tex_id;
in vec4 clip_quad;

uniform vs_params {
	vec2 framebuffer;
};

out vec4 vertex_color;
out vec2 tex_coords;
out float texture_id;
out vec4 clip;

void main() {
	vertex_color = color;

	tex_coords = uv;
	texture_id = tex_id;
	clip = clip_quad;

	float x = (position.x - framebuffer.x) / framebuffer.x;
	float y = (position.y - framebuffer.y) / -framebuffer.y;
	gl_Position = vec4(x, y, 0, 1);
}
@end

@fs fs
uniform sampler2D font;
uniform sampler2D tex;

in vec4 vertex_color;
in vec2 tex_coords;
in float texture_id;
in vec4 clip;
out vec4 frag_color;

void main()
{
	vec4 tex_color = vec4(texture(tex, tex_coords).rgba);
	vec4 font_color = vec4(vertex_color.rgb, texture(font, tex_coords).r);

	if (((gl_FragCoord.y > clip.y) && (gl_FragCoord.y < clip.w)) && ((gl_FragCoord.x > clip.x) && (gl_FragCoord.x < clip.z))) { 
		if (texture_id == 0) {
			frag_color = vertex_color;
		} else if (texture_id == 1) {
			frag_color = font_color;
		} else if (texture_id == 2) {
			frag_color = tex_color;
		}
	} else {
		frag_color = vec4(0,0,0,0);
	}
}
@end

@program quad vs fs
