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

		// reset index for boxes
		state.ui.box_index = 0
		
		test := false
		if pt_in_quad({f32(state.mouse.pos.x), f32(state.mouse.pos.y)}, ctx) do test = true

		panel.box = ui_master_box("master")
		ui_push_parent(ui_row())
		ui_button("First button")
		ui_button("Second button")
		ui_pop_parent()

		if test {
			ui_button("hidden one")
			ui_button("hidden two")
		}

		ui_push_parent(ui_row())
		ui_button("secnd row button1")
		ui_button("second row button 2")
		ui_pop_parent()
		
		ctx.b = ctx.t + state.ui.line_space
		
		inorder :: proc(box: ^Box, ctx: ^Quad) {
			if box == nil do return
			draw_text(box.key, ctx^)
			ctx.t += state.ui.line_space
			ctx.b += state.ui.line_space

			inorder(box.first, ctx)
			inorder(box.next, ctx)
		}
		inorder(panel.box, &ctx)

		// panel.widget = ui_master_widget("debug master")
		// ui_push_parent(panel.widget)
		// row := ui_row("ROW 1")
		// ui_push_parent(row)
		// ui_button("r1 first button")
		// ui_button("r1 second button")
		// ui_button("r1 third button")
		// // if state.mouse.left == .CLICK {
		// // 	fmt.println(state.mouse.left)
		// // }
		// ui_pop_parent()
		// row2 := ui_row("ROW 2")
		// ui_push_parent(row2)
		// ui_button("r2 button1")
		// ui_button("r2 button2")

		

		// draw_text("DEBUG:", ctx)
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
