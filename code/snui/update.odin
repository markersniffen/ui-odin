package snui

import "core:fmt"

update :: proc()
{
	quad : Quad
	quad.l = f32(state.mouse.pos.x) - 25
	quad.t = f32(state.mouse.pos.y) - 25
	quad.r = quad.l + 50
	quad.b = quad.t + 50

	color: v4 ={0,1,0,1}

	if state.mouse.left == .CLICK do color = {1,0,0,1}
	if state.mouse.right == .CLICK do color = {0,0,1,1}

	push_quad_2(quad, color)
}

