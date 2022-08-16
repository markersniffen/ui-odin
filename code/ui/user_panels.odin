package ui

import "core:fmt"

Panel_Type :: enum {
	DEBUG,
	TEMP,
}

ui_panel_debug :: proc(panel_uid: Uid, ctx: Quad)
{
	// NOTE DEBUG

	debug_quad:= ctx
	draw_text("DEBUG:", debug_quad)
	debug_quad.t += state.ui.line_space
	draw_text(fmt.tprintf("CTX: %v", ctx), debug_quad)
	debug_quad.t += state.ui.line_space
	draw_text(fmt.tprintf("Mouse Pos: %v", state.mouse.pos), debug_quad)
	debug_quad.t += state.ui.line_space
	for p in state.ui.panels {
		draw_text(fmt.tprintf("%v", state.ui.panels[p]), debug_quad)
		debug_quad.t += state.ui.line_space
	}
	draw_text(fmt.tprintf("%v", state.ui.panel_master), debug_quad)
	debug_quad.t += state.ui.line_space


	
	if state.mouse.left == .CLICK && pt_in_quad({f32(state.mouse.pos.x), f32(state.mouse.pos.y)}, ctx) {
		ui_delete_panel(panel_uid)
		state.mouse.left = .UP
	}
}

ui_panel_temp :: proc(panel_uid: Uid, ctx: Quad)
{
	draw_text("Temp...", ctx)
}