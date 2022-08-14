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

	if state.mouse.left == .CLICK do color = state.ui.col_active
	if state.mouse.right == .CLICK do color = state.ui.col_hot
	if state.mouse.middle == .CLICK do color = state.ui.col_base

	push_quad_border(quad, color, 1)

	if state.mouse.scroll != 0 {
		ui_set_font_size(state.ui.font_size + (state.mouse.scroll*10))
		state.mouse.scroll = 0
	}

	draw_text_multiline("Welcome to sniff UI\nHere is a new line!\nSome more text\n-Mark Sniffendfasd!", quad, -2, .RIGHT)

	// NOTE DEBUG
	debug_quad: Quad = {0, 0, f32(state.window_size.x), 0 + state.ui.line_space}
	draw_text("DEBUG:", debug_quad)
	debug_quad.t += state.ui.line_space
	debug_quad.b += state.ui.line_space
	draw_text(fmt.tprintf("Mouse Pos: %v", state.mouse.pos), debug_quad)
	debug_quad.t += state.ui.line_space
	debug_quad.b += state.ui.line_space
	draw_text(fmt.tprintf("Font Size: %v", state.ui.font_size), debug_quad)
}

