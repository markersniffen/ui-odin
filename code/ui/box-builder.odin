package ui

import "core:fmt"

Panel_Content :: enum {
	NONE,
	FILE_MENU,
	FLOATER,
	PANEL_LIST,
	DEBUG,
	PROPERTIES,
	BOXLIST,
	TESTLIST,
}

build_panel_content :: proc(content: Panel_Content) {
	#partial switch content
	{
		case .DEBUG: 		ui_panel_debug()
		case .FILE_MENU: 	ui_panel_file_menu()
		case .FLOATER: 		ui_panel_floater()
		case .PANEL_LIST: 	ui_panel_pick_panel()
		// PANELS AFTER THIS ARE SWAPPABLE //
		case .PROPERTIES: 	ui_panel_properties()
		case .BOXLIST: 		ui_panel_boxlist()
		case .TESTLIST: 	ui_panel_testlist()
	}
}

ui_panel_file_menu :: proc() {
	ui_begin()
	ui_size(.TEXT, 1, .TEXT, 1)
	ui_axis(.X)
	ui_button("File")
	ui_button("Edit")
	ui_button("View")
	ui_spacer_fill()
	ui_value("mouse pos:", state.mouse.pos)
	ui_label("|")
	ui_value("window width:", state.window.size.x)
	ui_label("|")
	ui_value("fb width:", state.window.framebuffer.x)
	ui_label("|")
	ui_value("boxes:", state.ui.boxes.pool.nodes_used)
	ui_value("/", state.ui.boxes.pool.chunk_count)
	ui_label("|")
	ui_value("panels:", state.ui.panels.pool.nodes_used)
	ui_value("/", state.ui.panels.pool.chunk_count)
	ui_label("|")
	ui_value("fps:", state.delta_time)
	ui_spacer_pixels(6)
	ui_end()
}

ui_panel_testlist :: proc() {
	ui_begin()
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.TEXT, 1, .TEXT, 1)
		if ui_button("###p").released {
			ui_queue_panel(state.ui.ctx.panel, .Y, .FLOATING, .PANEL_LIST, 1.0, state.ui.ctx.panel.quad)
		}
	ui_pop()
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_label("RANDOM LIST:")
	ui_size(.PCT_PARENT, 1, .PIXELS, 150)
	ui_empty("ONE")
		ui_size(.PCT_PARENT, 1, .MIN_SIBLINGS, 1)
		ui_empty("TWO")
			ui_scrollbox()
				for index in 0..=50 {
					ui_axis(.Y)
					ui_size(.PCT_PARENT, 1, .TEXT, 1)
					x := ui_empty()
					for yindex in 0..=3 {
						ui_axis(.X)
						ui_size(.PIXELS, 150, .TEXT, 1)
						ui_button(fmt.tprintf("Fun | %v | %v", index, yindex))
					}
					ui_axis(.Y)
					ui_pop()
				}
			ui_pop()
			ui_axis(.X)
			ui_scrollbar()
		ui_pop()
		ui_pop()
		ui_pop()
	ui_sizebar_y()
	ui_pop()
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_button("whee")
	ui_end()
}

ui_panel_boxlist :: proc() {
	ui_begin()
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.TEXT, 1, .TEXT, 1)
		if ui_button("###p").released {
			ui_queue_panel(.Y, .FLOATING, .PANEL_LIST, 1.0, state.ui.ctx.panel.quad)
		}
	ui_pop()
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_value("box length", len(state.ui.boxes.all))
	ui_size(.PCT_PARENT, 1, .TEXT, 4)
	ui_empty()
	ui_scrollbox()
		ui_axis(.Y)
		ui_size(.PCT_PARENT, 1, .TEXT, 1)
		ui_label("Panel List:")
		for key, panel in state.ui.panels.all {
			if panel.box != nil {
				ui_button(fmt.tprintf("%v | %v ###d %v", panel.uid, panel.content, panel.box.key.len))
			} else {
				ui_button(fmt.tprintf("%v | %v", panel.uid, panel.content))
			}
		}
		ui_pop()
		ui_axis(.X)
	ui_scrollbar()
	ui_pop()
	ui_pop()
	ui_end()
}

ui_panel_debug :: proc() {
	ui_begin()
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.TEXT, 1, .TEXT, 1)
		if ui_button("###p").released {
			ui_queue_panel(.Y, .FLOATING, .PANEL_LIST, 1.0, state.ui.ctx.panel.quad)
		}
	ui_pop()

	ui_size(.TEXT,1, .TEXT,1)
	ui_axis(.Y)
	ui_value("len panels", state.ui.panels.pool.nodes_used)
	ui_value("len boxes", len(state.ui.boxes.all))
	ui_end()
}

ui_panel_properties :: proc() {
	ui_begin()
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.TEXT, 1, .TEXT, 1)
		if ui_button("###p").released {
			ui_queue_panel(.Y, .FLOATING, .PANEL_LIST, 1.0, state.ui.ctx.panel.quad)
		}
	ui_pop()

	ui_axis(.Y)
	ui_size(.SUM_CHILDREN, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.TEXT, 1, .TEXT, 1)
		ui_button("test1")
		ui_button("test2")
		ui_button("test3")
		ui_button("test4")
	ui_pop()
	ui_axis(.Y)
	ui_size(.SUM_CHILDREN, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.TEXT, 1, .TEXT, 1)
		ui_button("test6")
		ui_button("test7")
		ui_button("test8")
		ui_button("test9")
	ui_pop()
	ui_end()
}

ui_panel_pick_panel :: proc() {
	panel := ui_begin_floating()
	ui_axis(.Y)
	ui_size(.SUM_CHILDREN, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.PIXELS, 250, .TEXT, 1)
		ui_drag_panel("Select Panel:")
		ui_size(.TEXT, 1, .TEXT, 1)
		// ui_spacer_pixels(120)
		if ui_button("###x").released {
			if state.ui.panels.floating != nil {
				ui_delete_panel(state.ui.panels.floating)
			}
		}
	ui_pop()

	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .SUM_CHILDREN, 1)
	ui_empty()
		ui_size(.PCT_PARENT, 1, .TEXT, 1)
		for p, i in Panel_Content {
			if i > 3 {
				if ui_button(fmt.tprintf("%v", p)).released {
					panel.parent.content = p
					ui_delete_panel(panel)
				}
			}
		}
	ui_pop()
	ui_end()
}

ui_panel_floater :: proc() {
	ui_begin_floating()
	ui_size(.SUM_CHILDREN, 1, .SUM_CHILDREN, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.TEXT, 1, .TEXT, 1)
		ui_label("FLOATING PANEL")
		ui_spacer_pixels(50)
		if ui_button("###x").released do ui_delete_panel(state.ui.panels.floating)
	ui_pop()
	ui_end()
}