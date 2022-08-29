package ui

import "core:fmt"

//______ PANELS ______//

Panel_Type :: enum {
	NULL,
	DEBUG,
	PANEL_LIST,
	TEMP,
	FILE_MENU,
}

ui_panel_menu :: proc() {
	// ui_row()
	// ui_size_x(.TEXT_CONTENT, 1)
	// ui_label(fmt.tprintf("Panel %v | Type: %v", state.ui.ctx.panel.uid, state.ui.ctx.panel.type))
	// ui_spacer_fill()
	// if ui_button("CLOSE PANEL").clicked do ui_delete_panel(state.ui.ctx.panel)
	// ui_end_row()
}

ui_panel_file_edit_view :: proc() {
	ui_root_box()
	ui_layout(.Y, .PERCENT_PARENT, 1, .PIXELS, state.ui.line_space)
		ui_axis(.X)
		ui_size(.TEXT_CONTENT, 1, .TEXT_CONTENT, 1)
		ui_button("File")
		ui_button("Edit")
		ui_button("View")
		ui_spacer_fill()
		ui_button(" - ")
	ui_pop()
}

ui_panel_debug :: proc() {
	state.debug.box = ui_root_box()
	// ui_panel_menu()

	ui_layout(.Y, .PERCENT_PARENT, 1, .CHILDREN_SUM, 1)
		ui_layout(.X, .PERCENT_PARENT, .5, .CHILDREN_SUM, 1)
			ui_axis(.Y)
			ui_size(.PERCENT_PARENT, 1, .TEXT_CONTENT, 1)
			ui_button("test")
			ui_button("test2")
			ui_value("Mouse:", state.mouse.pos)
			ui_value("window size:", state.window_size)
			ui_value("fb size:", state.framebuffer_res)
		ui_pop()
	ui_pop()
	ui_layout(.Y, .PERCENT_PARENT, 1, .CHILDREN_SUM, 1)	// row/box that holds multiple columns
		ui_layout(.X, .PERCENT_PARENT, 0.3, .CHILDREN_SUM, 1) // column (1) of buttons
			ui_axis(.Y)
			ui_size(.PERCENT_PARENT, 1, .TEXT_CONTENT, 1)
			ui_button("WHEE")
			ui_button("Baz")
			ui_button("Bop")
			ui_button("FOo")
		ui_pop()

		ui_layout(.X, .PERCENT_PARENT, 0.3, .CHILDREN_SUM, 1) // column (2) of buttons
			ui_axis(.Y)
			ui_size(.PERCENT_PARENT, 1, .TEXT_CONTENT, 1)
			ui_button("x")
			ui_button("y")
			ui_button("z")
			ui_button("w")
		ui_pop()

		ui_layout(.X, .PERCENT_PARENT, 0.4, .CHILDREN_SUM, 1) // column (2) of buttons
			ui_axis(.Y)
			ui_size(.PERCENT_PARENT, 1, .TEXT_CONTENT, 1)
			ui_button("xx")
			ui_button("yx")
			ui_button("dasf")
			ui_button("wx")
		ui_pop()

		ui_row()
			ui_col()
				ui_button("Test5")
				ui_button("Test6")
				ui_button("Test7")
				ui_spacer_fill()
				ui_button("Test8")
			ui_pop()
		ui_pop()
	ui_pop()


}

ui_panel_temp :: proc() {
	// ui_root_box()
	// ui_panel_menu()
}

ui_panel_panel_list :: proc() {
	// ui_root_box()
	// ui_panel_menu()
}
