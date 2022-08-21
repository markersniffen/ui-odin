package ui

import "core:fmt"

Panel_Type :: enum {
	NULL,
	DEBUG,
	TEMP,
}

ui_panel_debug :: proc(panel: ^Panel)
{
	if panel != nil {
		ctx := panel.ctx

		// reset index for boxes
		panel.box = ui_master_box(fmt.tprintf("master_%v", panel.type))
		ui_push_parent(ui_row())
		ui_button("First button")
		ui_button("Second button")

		if state.debug.temp >= 0 {
			for i in 0..=state.debug.temp {
				ui_button(fmt.tprintf("special_%v", i))
			}
		}
		ui_pop_parent()

		ui_push_parent(ui_row())
		ui_button("secnd row button1")
		ui_button("second row button 2")
		ui_pop_parent()
	}
}

ui_panel_temp :: proc(panel: ^Panel)
{
	if panel != nil {
		// reset index for boxes
		// state.ui.box_index = 0
		panel.box = ui_master_box(fmt.tprintf("master_%v", panel.type))
		ui_push_parent(ui_row())
		ui_button("X")
		ui_button("Y")
	}
}
