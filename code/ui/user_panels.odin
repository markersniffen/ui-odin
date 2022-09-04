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
		state.debug.box = state.ui.ctx.box_parent
		ui_axis(.X)
		ui_size(.TEXT_CONTENT, 1, .TEXT_CONTENT, 1)
		if ui_menu_button("FILE").selected {
			ui_menu()
				ui_axis(.Y)
				ui_size(.TEXT_CONTENT, 1, .TEXT_CONTENT, 1)
				ui_button("menu button 1")
				ui_button("menu button 2")
				ui_button("menu button 3")
				ui_button("menu button 4")
				ui_button("menu button 5")
			ui_pop()
		}
		if ui_menu_button("EDIT").selected {
			ui_menu()
				ui_axis(.Y)
				ui_size(.TEXT_CONTENT, 1, .TEXT_CONTENT, 1)
				ui_button("menu button 1")
				ui_button("menu button 2")
				ui_button("menu button 3")
				ui_button("menu button 4")
				ui_button("menu button 5")
			ui_pop()
		}
		if ui_menu_button("VIEW").selected {
			ui_menu()
				ui_axis(.Y)
				ui_size(.TEXT_CONTENT, 1, .TEXT_CONTENT, 1)
				ui_button("menu button 1")
				ui_button("menu button 2")
				ui_button("menu button 3")
				ui_button("menu button 4")
				ui_button("menu button 5")
			ui_pop()
		}
		ui_spacer_fill()
		ui_button(" - ")
	ui_pop()
}

see_3_layers :: proc(box: ^Box) {
		if box != nil {
		n1 := box.first
		for b1 := n1; b1 != nil; b1 = b1.next {
			ui_label(b1.key)
			if b1.first != nil {
				for b2 := b1.first; b2 != nil; b2 = b2.next {
					ui_label(fmt.tprintf(">>%v", b2.key))
					if b2.first != nil {
						for b3 := b2.first; b3 != nil; b3 = b3.next {
							ui_label(fmt.tprintf(">>>>>%v", b3.key))
						}
					}
				}
			}
		}
	}
}

ui_panel_debug :: proc() {
	ui_root_box()
	ui_layout(.Y, .PERCENT_PARENT, 1, .CHILDREN_SUM, 1)
		ui_layout(.X, .PERCENT_PARENT, .5, .CHILDREN_SUM, 1)
			ui_axis(.Y)
			ui_size(.PERCENT_PARENT, 1, .TEXT_CONTENT, 1)
			see_3_layers(state.debug.box)
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
