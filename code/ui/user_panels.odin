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
	// ui_set_size_x(.TEXT_CONTENT, 1)
	// ui_label(fmt.tprintf("Panel %v | Type: %v", state.ui.ctx.panel.uid, state.ui.ctx.panel.type))
	// ui_spacer_fill()
	// if ui_button("CLOSE PANEL").clicked do ui_delete_panel(state.ui.ctx.panel)
	// ui_end_row()
}

ui_panel_file_edit_view :: proc() {
	ui_root_box()

	ui_row()
	ui_set_size_x(.TEXT_CONTENT, 1)
	ui_set_size_y(.TEXT_CONTENT, 1)
	ui_button("File")
	ui_button("Edit")
	ui_button("View")
	ui_spacer_fill()
	ui_button(" - ")
	ui_button(" O ")
	ui_button(" X ")

	ui_end_row()
}

ui_panel_debug :: proc() {
	ui_root_box()
	// ui_panel_menu()

	ui_set_size_x(.TEXT_CONTENT, 1)
	ui_set_size_y(.TEXT_CONTENT, 1)
	ui_row()
	ui_button("Test1")
	ui_button("Test2")
	ui_button("Test3")
	ui_button("Test4")
	ui_end_row()

	ui_col()
	ui_button("x1")
	ui_button("x2")
	ui_button("x3")
	ui_end_col()

	ui_row()
	ui_button("Test5")
	ui_button("Test6")
	ui_button("Test7")
	ui_button("Test8")
	ui_end_row()


}

ui_panel_temp :: proc() {
	// ui_root_box()
	// ui_panel_menu()
}

ui_panel_panel_list :: proc() {
	// ui_root_box()
	// ui_panel_menu()
}
