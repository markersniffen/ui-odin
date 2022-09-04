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

}

ui_panel_file_edit_view :: proc() {
	ui_root_box()
	ui_layout(.Y, .PERCENT_PARENT, 1, .PIXELS, state.ui.line_space)
		ui_axis(.X)
		ui_size(.TEXT_CONTENT, 1, .TEXT_CONTENT, 1)
		if ui_dropdown("File").selected {
			// ui_axis(.Y)
			ui_menu()
				ui_size(.TEXT_CONTENT, 1, .TEXT_CONTENT, 1)
				ui_button("menu button 1")
				ui_button("menu button 2")
				ui_button("menu button 3")
				ui_button("menu button 4")
			ui_pop()
		}
		ui_size(.TEXT_CONTENT, 1, .TEXT_CONTENT, 1)
		if ui_dropdown("Edit").selected {
			ui_axis(.Y)
			ui_menu()
				ui_size(.TEXT_CONTENT, 1, .TEXT_CONTENT, 1)
				ui_button("menu buttonx 1")
				ui_button("menu buttonx 2")
				ui_button("menu buttonx 3")
				ui_button("menu buttonx 4")
				ui_button("menu buttonx 5")
			ui_pop()
		}
		ui_size(.TEXT_CONTENT, 1, .TEXT_CONTENT, 1)
		if ui_dropdown("View").selected {
			ui_axis(.Y)
			ui_menu()
				ui_size(.TEXT_CONTENT, 1, .TEXT_CONTENT, 1)
				ui_button("menu buttony 1")
				ui_button("menu buttony 2")
				ui_button("menu buttony 3")
				ui_button("menu buttony 4")
				ui_button("menu buttony 5")
			ui_pop()
		}
		ui_spacer_fill()
		ui_button(" - ")
	ui_pop()
}

ui_panel_debug :: proc() {
	state.debug.box = ui_root_box()
	ui_layout(.Y, .PERCENT_PARENT, 1, .CHILDREN_SUM, 1)
		ui_layout(.X, .PERCENT_PARENT, .5, .CHILDREN_SUM, 1)
			ui_axis(.Y)
			ui_size(.PERCENT_PARENT, 1, .TEXT_CONTENT, 1)


			if ui_dropdown("Random").selected {
				ui_menu()
					ui_size(.TEXT_CONTENT, 1, .TEXT_CONTENT, 1)
					ui_button("menu button 1")
					ui_button("menu button 2")
					ui_button("menu button 3")
					ui_button("menu button 4")
					ui_button("menu button 5")
				ui_pop()
			}

			ui_row()
				ui_value("window size:", state.window_size)
				ui_value("fb size:", state.framebuffer_res)
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
