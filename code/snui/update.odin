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

	// NOTE DEBUG
	debug_quad: Quad = {0, 0, f32(state.window_size.x), 0 + state.ui.line_space}
	draw_text("DEBUG:", debug_quad)
	debug_quad.t += state.ui.line_space
	debug_quad.b += state.ui.line_space
	draw_text(fmt.tprintf("Mouse Pos: %v", state.mouse.pos), debug_quad)
	debug_quad.t += state.ui.line_space
	debug_quad.b += state.ui.line_space
	for p in state.ui.panels {
		draw_text(fmt.tprintf("%v", state.ui.panels[p]), debug_quad)
		debug_quad.t += state.ui.line_space
		debug_quad.b += state.ui.line_space
	}
	draw_text(fmt.tprintf("%v", state.ui.panel_master), debug_quad)
	debug_quad.t += state.ui.line_space
	debug_quad.b += state.ui.line_space

	ui_calc_panel(state.ui.panel_master, {0, 0, f32(state.window_size.x), f32(state.window_size.y)})

}

