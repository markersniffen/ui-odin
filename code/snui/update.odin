package snui

import "core:fmt"

update :: proc()
{
	quad : Quad = {
		f32(state.mouse.pos.x),
		f32(state.mouse.pos.y),
		f32(state.mouse.pos.x)+400,
		f32(state.mouse.pos.y)+(state.ui.line_space * 5),
	}
	color: v4 ={0,1,0,1}

	if state.mouse.left == .CLICK do color = state.ui.col.active
	if state.mouse.right == .CLICK do color = state.ui.col.hot
	if state.mouse.middle == .CLICK do color = state.ui.col.base

	push_quad_border(quad, color, 1)



	ui_calc_panel(state.ui.panel_master, {0, 0, f32(state.window_size.x), f32(state.window_size.y)})

}

