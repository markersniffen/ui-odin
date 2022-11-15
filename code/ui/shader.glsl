@header package ui
@header import sg "../../../sokol-odin/sokol/gfx"

@vs vs
in vec4 position;
in vec2 uv;
in vec4 color;
in float texID;
in vec4 _clip;

uniform vs_params {
	uniform vec2 framebuffer_res;
	uniform vec2 multiplier;
};

out vec2 fb_res;
out vec4 vertex_color;

void main() {
	fb_res = framebuffer_res;
	float x = ((position.x * multiplier.x) - framebuffer_res.x) / framebuffer_res.x;
	float y = ((position.y * multiplier.y) - framebuffer_res.y) / -framebuffer_res.y;

	vertex_color = color;
	gl_Position.xyzw = vec4(position.x/fb_res.x, position.y/fb_res.y, position.z, position.w);
	//gl_Position = position;
}
@end

@fs fs
in vec2 fb_res;
in vec4 vertex_color;

out vec4 frag_color;

void main()
{
	frag_color = vec4(1,0,0,1);
}
@end

@program quad vs fs