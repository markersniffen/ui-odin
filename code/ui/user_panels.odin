package ui

import "core:fmt"

//______ PANELS ______//

ui_panel_file_menu :: proc(panel: ^Panel) {
	panel.box = ui_master_box(fmt.tprintf("master_%v", panel.type), panel.ctx)
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
}

ui_panel_debug :: proc(panel: ^Panel)
{
	if panel != nil {
		panel.box = ui_master_box(fmt.tprintf("master_%v", panel.type), panel.ctx)

		state.ui.ctx.bg_color = state.ui.col.bg
		state.ui.ctx.border_color = {0,1,0,1}
		state.ui.ctx.border = 1

		ui_set_dir(.VERTICAL)
		ui_set_size_x(.PERCENT_PARENT, 1)
		ui_set_size_y(.PIXELS, state.ui.line_space)
		ui_push_parent(ui_row())

		ui_set_dir(.HORIZONTAL)
		ui_set_size_x(.TEXT_CONTENT, 1)
		ui_set_size_y(.TEXT_CONTENT, 1)
		ui_label(fmt.tprintf("Mouse: %v", state.mouse.pos))

		ui_pop_parent()
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

ui_panel_temp :: proc(panel: ^Panel)
{
	if panel != nil {
		panel.box = ui_master_box(fmt.tprintf("master_%v", panel.type), panel.ctx)
		
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
		panel.box = ui_master_box(fmt.tprintf("master_%v", panel.type), panel.ctx)
		ui_push_parent(ui_row())
		
		ui_button(fmt.tprintf("Active: %v", state.ui.panel_active))

		for p in state.ui.panels {
			panel, pok := state.ui.panels[p]

			ui_button(fmt.tprintf("Panel: %v", panel))
		}
		ui_pop_parent()
	}
}
