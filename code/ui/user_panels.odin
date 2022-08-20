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
		
		panel.widget = ui_master_widget("debug master")
		ui_push_parent(panel.widget)
		row := ui_row("temp")
		ui_push_parent(row)
		ui_button("Click me")
		ui_button("Something Else")
		ui_pop_parent()
		row = ui_row("row 2")
		ui_push_parent(row)
		ui_button("whee0")
		ui_button("Great!")


		// draw_text("DEBUG:", ctx)
		// draw_text(fmt.tprintf("CTX: %v", ctx^))
		// draw_text(fmt.tprintf("Mouse Pos: %v", state.mouse.pos), ctx^)
		// for p in state.ui.panels {
		// 	draw_text(fmt.tprintf("%v", state.ui.panels[p]), ctx^)
		// }
		// draw_text(fmt.tprintf("%v", state.ui.panel_master), ctx^)

		p := panel.widget
		ctx.b = ctx.t + state.ui.line_space
		for {
			draw_text(p.key, ctx)
			ctx.t += state.ui.line_space
			ctx.b += state.ui.line_space
			if p.next != nil {
				p = p.next
			} else {
				p = p.first_child
				ctx.l += 20
			}
			if p == nil do break
		}
	}
}

ui_panel_temp :: proc(panel_uid: Uid)
{
	// draw_text("Temp...", ctx)
}
