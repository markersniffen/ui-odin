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
	// ui_root_box()
	index := 0
	iterate_boxes :: proc(box: ^Box) {
		parentkey := ""
		if box != nil {
			if box.parent != nil do parentkey = box.parent.key
			fmt.print(fmt.tprintf("%v [%v] >", box.key, parentkey))
		}
		if box != nil {
			for child := box.first; child != nil; child = child.next {
				iterate_boxes(child)
			}
		}
	}

	iterate_boxes(state.debug.box)
	fmt.print('\n')

	// ui_row()
	// ui_set_size_x(.TEXT_CONTENT, 1)
	// ui_set_size_y(.TEXT_CONTENT, 1)
	// ui_button("File")
	// ui_button("Edit")
	// ui_button("View")
	// ui_spacer_fill()
	// ui_button(" - ")
	// ui_button(" O ")
	// ui_button(" X ")

	// ui_end_row()
}

ui_panel_debug :: proc() {
	state.debug.box = ui_root_box()
	// ui_panel_menu()

	ui_set_size_x(.TEXT_CONTENT, 1)
	ui_set_size_y(.TEXT_CONTENT, 1)
	ui_row()
	ui_button("Test1")
	ui_button("Test2")
	ui_button("Test3")
	ui_button("Test4")
	ui_end_row()
	

	ui_set_dir(.VERTICAL)
	ui_set_size_x(.PERCENT_PARENT, 1)
	ui_set_size_y(.CHILDREN_SUM, 1)
	ui_layout()	// row/box that holds multiple columns

		ui_set_dir(.HORIZONTAL)
		ui_set_size_x(.PERCENT_PARENT, 0.25)
		ui_set_size_y(.CHILDREN_SUM, 1)
		ui_layout() // column (1) of buttons
			ui_set_dir(.VERTICAL)
			ui_set_size_x(.PERCENT_PARENT, 1)
			ui_set_size_y(.PIXELS, state.ui.line_space)
			ui_button("WHEE")
			ui_button("Baz")
			ui_button("Bop")
			ui_button("FOo")
		ui_pop_parent()

		ui_set_dir(.HORIZONTAL)
		ui_set_size_x(.PERCENT_PARENT, 0.25)
		ui_set_size_y(.CHILDREN_SUM, 1)
		ui_layout() // column (2) of buttons
			ui_set_dir(.VERTICAL)
			ui_set_size_x(.PERCENT_PARENT, 1)
			ui_set_size_y(.PIXELS, state.ui.line_space)
			ui_button("x")
			ui_button("y")
			ui_button("z")
			ui_button("w")
		ui_pop_parent()

	ui_pop_parent()

	ui_row()
	ui_set_size_x(.TEXT_CONTENT, 1)
	ui_set_size_y(.TEXT_CONTENT, 1)
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
