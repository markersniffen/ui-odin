package ui

import "core:fmt"

Panel_Type :: enum {
	DEBUG,
	TEMP,
}

ui_panel_debug :: proc(panel_uid: Uid)
{
	panel, panel_ok := state.ui.panels[panel_uid]
	if panel_ok {
		ctx := panel.ctx
 		parent_widget := cast(^Widget)pool_alloc(&state.ui.widget_pool)
		widget.id = fmt.tprintf("%v_parent", panel_uid)
		widget.ctx = ctx
		state.ui.widget = parent_widget.uid

		



		draw_text("DEBUG:", ctx)
		// draw_text(fmt.tprintf("CTX: %v", ctx^))
		// draw_text(fmt.tprintf("Mouse Pos: %v", state.mouse.pos), ctx^)
		// for p in state.ui.panels {
		// 	draw_text(fmt.tprintf("%v", state.ui.panels[p]), ctx^)
		// }
		// draw_text(fmt.tprintf("%v", state.ui.panel_master), ctx^)
	}
}

ui_panel_temp :: proc(panel_uid: Uid)
{
	// draw_text("Temp...", ctx)
}
