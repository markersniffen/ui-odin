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
uniform sampler2D regular;
uniform sampler2D bold;
uniform sampler2D italic;
uniform sampler2D light;
uniform sampler2D icons;

in vec4 vertex_color;
in vec2 tex_coords;
in float texture_id;
in vec4 clip;
out vec4 frag_color;

void main()
{
	if (((gl_FragCoord.y > clip.y) && (gl_FragCoord.y < clip.w)) && ((gl_FragCoord.x > clip.x) && (gl_FragCoord.x < clip.z))) { 
		if (texture_id == 0)
		{
			frag_color = vertex_color;
		} else if (texture_id == 1) {
			frag_color = vec4(vertex_color.rgb, texture(regular, tex_coords).r);
		} else if (texture_id == 2) {
			frag_color = vec4(vertex_color.rgb, texture(bold, tex_coords).r);
		} else if (texture_id == 3) {
			frag_color = vec4(vertex_color.rgb, texture(italic, tex_coords).r);
		} else if (texture_id == 4) {
			frag_color = vec4(vertex_color.rgb, texture(light, tex_coords).r);
		} else if (texture_id == 5) {
			frag_color = vec4(vertex_color.rgb, texture(icons, tex_coords).r);
		}
	}
}
@end

@program quad vs fs
