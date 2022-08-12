package snui

import "core:fmt"

update :: proc()
{
	quad : Quad = {
		f32(state.mouse.pos.x),
		f32(state.mouse.pos.y),
		f32(state.mouse.pos.x)+50,
		f32(state.mouse.pos.y)+50,
	}
	color: v4 ={0,1,0,1}

	if state.mouse.left == .CLICK do color = {1,0,0,1}
	if state.mouse.right == .CLICK do color = {0,0,1,1}
	if state.mouse.middle == .CLICK do color = {0,1,1,1}

	// push_quad(quad, color, 2.0)
	push_quad_gradient_v(quad, {1,0,0,1}, color)
	draw_text("Welcome to sniff UI\nHere is a new line!", {f32(state.mouse.pos.x), f32(state.mouse.pos.y)})
}

