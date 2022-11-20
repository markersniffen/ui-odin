@header package ui
@header import sg "../../../sokol-odin/sokol/gfx"

@vs vs
in vec2 position;

uniform vs_params {
	vec2 framebuffer;
};


void main() {
	float x = (position.x - framebuffer.x) / framebuffer.x;
	float y = (position.y - framebuffer.y) / -framebuffer.y;
	gl_Position = vec4(x, y, 0, 1);
}
@end

@fs fs
out vec4 frag_color;

void main()
{
	frag_color = vec4(1,0.5,1,1);
}
@end

@program quad vs fs
