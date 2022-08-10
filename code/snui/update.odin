package snui

import "core:fmt"

update :: proc()
{
	quad : Quad = {f32(state.mouse.pos.x) - 25, f32(state.mouse.pos.y) - 25, f32(state.mouse.pos.x) + 50, f32(state.mouse.pos.y) + 50}
	color: v4 ={0,1,0,1}

	if state.mouse.left == .CLICK do color = {1,0,0,1}
	if state.mouse.right == .CLICK do color = {0,0,1,1}

	push_quad(quad, color, 2.0)
}

