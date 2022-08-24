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
	ui_set_dir(.VERTICAL)
	ui_set_size_x(.PERCENT_PARENT, 1)
	ui_set_size_y(.PIXELS, state.ui.line_space)
	ui_push_parent(ui_row())
	ui_set_dir(.HORIZONTAL)
	ui_set_size_x(.TEXT_CONTENT, 1)
	ui_set_size_y(.PERCENT_PARENT, 1)
	ui_label(fmt.tprintf("Panel Type: %v | Panel IU: %v", state.ui.ctx.panel.type, state.ui.ctx.panel.uid))
	ui_spacer_fill()
	if ui_button("X").clicked do ui_delete_panel(state.ui.ctx.panel)
	ui_pop_parent()
}

ui_panel_file_menu :: proc(panel: ^Panel) {
	ui_root_box(panel)
	ui_set_dir(.VERTICAL)
	ui_set_size_x(.PERCENT_PARENT, 1)
	ui_set_size_y(.PIXELS, state.ui.line_space)
	ui_push_parent(ui_row())

	ui_set_dir(.HORIZONTAL)
	ui_set_size_x(.TEXT_CONTENT, 1)
	ui_set_size_y(.TEXT_CONTENT, 1)
	ui_button("File")
	ui_button("Edit")
	ui_button("View")
	ui_spacer_fill()
	ui_button("-")
	ui_button("O")
	ui_button("X")
}

ui_panel_debug :: proc(panel: ^Panel) {
	if panel != nil {
		ui_root_box(panel)
		ui_panel_menu()

		ui_set_dir(.VERTICAL)
		ui_set_size_x(.TEXT_CONTENT, 1)
		ui_set_size_y(.PIXELS, state.ui.line_space)
		// ui_label(fmt.tprintf("Mouse: %v", state.mouse.pos))
		ui_label(fmt.tprintf("Box Pool Nodes Used: %v | Len Box Map %v", state.ui.box_pool.nodes_used, len(state.ui.boxes)))
		ui_button("WHEE")

		// ui_pop_parent()
		ui_set_dir(.VERTICAL)
		ui_set_size_x(.PERCENT_PARENT, 1)
		ui_set_size_y(.PIXELS, state.ui.line_space)
		ui_push_parent(ui_row())

		ui_set_dir(.HORIZONTAL)
		ui_set_size_x(.TEXT_CONTENT, 1)
		ui_set_size_y(.TEXT_CONTENT, 1)

		if ui_button("Split Panel Veritcally").clicked do ui_create_panel(panel, .HORIZONTAL)
		if ui_button("Split Panel Horizontally").clicked do ui_create_panel(panel, .VERTICAL)
		if ui_button("Third button").clicked {
			fmt.println("THIRRD BUTTON CLICKE")
		}

		if state.debug.temp >= 0 {
			for i in 0..=state.debug.temp {
				ui_button(fmt.tprintf("special_%v", i))
			}
		}
		ui_pop_parent()
		ui_set_dir(.VERTICAL)
		ui_set_size_x(.PERCENT_PARENT, 1)
		ui_set_size_y(.PIXELS, state.ui.line_space)
		ui_push_parent(ui_row())

		ui_set_size_x(.TEXT_CONTENT, 1)
		ui_set_size_y(.TEXT_CONTENT, 1)
		ui_button("secnd row button1")
		ui_button("second row button 2")
		if state.debug.temp >= 0 {
			for i in 0..=state.debug.temp {
				ui_button(fmt.tprintf("sl_%v", i))
			}
		}
		ui_pop_parent()
	}
}

ui_panel_temp :: proc(panel: ^Panel) {
	if panel != nil {
		ui_root_box(panel)
		ui_panel_menu()

		ui_set_dir(.VERTICAL)
		ui_set_size_x(.PERCENT_PARENT, 1)
		ui_set_size_y(.PIXELS, state.ui.line_space)
		ui_push_parent(ui_row())

		ui_set_dir(.HORIZONTAL)
		ui_set_size_x(.PERCENT_PARENT, 0.25)
		ui_set_size_y(.PERCENT_PARENT, 1)
		ui_label("Size")
		ui_button("Size X")
		ui_button("Size Y")
		ui_button("Size Z")

		ui_pop_parent()
		ui_set_dir(.VERTICAL)
		ui_set_size_x(.PERCENT_PARENT, 1)
		ui_set_size_y(.PIXELS, state.ui.line_space)

		ui_push_parent(ui_row())
		ui_set_dir(.HORIZONTAL)
		ui_set_size_x(.PERCENT_PARENT, 0.25)
		ui_set_size_y(.PERCENT_PARENT, 1)
		ui_label("Position")
		ui_button("Pos X")
		ui_button("Pos Y")
		ui_button("Pos Z")
	}
}

ui_panel_panel_list :: proc(panel: ^Panel) {
	if panel != nil {
		ui_root_box(panel)
		ui_panel_menu()


		ui_push_parent(ui_row())
		
		ui_button(fmt.tprintf("Active: %v", state.ui.panel_active))

		for p in state.ui.panels {
			panel, pok := state.ui.panels[p]

			ui_button(fmt.tprintf("Panel: %v", panel))
		}
		ui_pop_parent()
	}
}
