package snui

import "core:fmt"

update :: proc()
{
	quad : Quad = {
		f32(state.mouse.pos.x),
		f32(state.mouse.pos.y)-16,
		f32(state.mouse.pos.x)+250,
		f32(state.mouse.pos.y),
	}
	color: v4 ={0,1,0,1}

	if state.mouse.left == .CLICK do color = {1,0,0,1}
	if state.mouse.right == .CLICK do color = {0,0,1,1}
	if state.mouse.middle == .CLICK do color = {0,1,1,1}

	push_quad(quad, color, 2.0)
	draw_text("Welcome to sniff UI\nHere is a new line!", quad)
	push_quad({0, 0, 500, 500}, {1,0.2,0.5,1}, 0, {0,0,1,1}, 1)
	fmt.println(state.render.quad_index)
}

