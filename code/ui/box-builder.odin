package ui

import "core:fmt"

Panel_Content :: enum {
	NONE,
	FILE_MENU,
	MENU_FILE,
	MENU_EDIT,
	MENU_VIEW,
	CTX_PANEL,
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
		case .PANEL_LIST: 	ui_panel_pick_panel()

		case .MENU_FILE:	ui_file_menu()
		case .MENU_EDIT:	ui_edit_menu()
		case .MENU_VIEW:	ui_view_menu()

		case .CTX_PANEL:    ui_ctx_panel()
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
	if ui_button("File").clicked do ui_queue_panel(state.ui.ctx.panel, .Y, .FLOATING, .MENU_FILE, 1.0, state.ui.ctx.panel.quad)
	if ui_button("Edit").clicked do ui_queue_panel(state.ui.ctx.panel, .Y, .FLOATING, .MENU_EDIT, 1.0, state.ui.ctx.panel.quad)
	if ui_button("View").clicked do ui_queue_panel(state.ui.ctx.panel, .Y, .FLOATING, .MENU_VIEW, 1.0, state.ui.ctx.panel.quad)
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
	ui_value("fps:", state.fps)
	ui_label("|")
	ui_value("dt:", state.delta_time)
	ui_spacer_pixels(6)
	ui_end()
}

ui_file_menu :: proc() {
	panel := ui_begin_menu()
	ui_axis(.Y)
	ui_size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
	ui_empty()
		ui_size(.PIXELS, 200, .TEXT, 1)
		ui_menu_button("New")
		ui_menu_button("Open")
		ui_menu_button("Save")
		ui_menu_button("Save As")
		if ui_menu_button("Exit").clicked do state.quit=true
	ui_pop()
}

ui_edit_menu :: proc() {
	panel := ui_begin_menu()
	ui_axis(.Y)
	ui_size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
	ui_empty()
		ui_size(.PIXELS, 200, .TEXT, 1)
		ui_menu_button("Cut")
		ui_menu_button("Copy")
		ui_menu_button("Paste")
	ui_pop()
}

ui_view_menu :: proc() {
	panel := ui_begin_menu()
	ui_axis(.Y)
	ui_size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
	ui_empty()
		ui_size(.PIXELS, 200, .TEXT, 1)
		ui_menu_button("Some Stuff")
		ui_menu_button("More Stuff")
		ui_menu_button("Everything")
	ui_pop()
}

ui_ctx_panel :: proc() {
	panel := ui_begin_floating_menu()
	ui_axis(.Y)
	ui_size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
	ui_empty()
		ui_size(.PIXELS, 200, .TEXT, 1)
		ui_menu_button("Cut")
		ui_menu_button("Copy")
		ui_menu_button("Paste")
	ui_pop()
}

ui_panel_testlist :: proc() {
	ui_begin()
	ui_scrollbox()
		ui_axis(.Y)
		ui_size(.PCT_PARENT, 1, .TEXT, 1)
		ui_empty()
			ui_axis(.X)
			ui_size(.TEXT, 1, .TEXT, 1)
			if ui_button("###p").released {
				ui_queue_panel(state.ui.ctx.panel, .Y, .FLOATING, .PANEL_LIST, 1.0, state.window.quad)
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
						ui_size(.PCT_PARENT, 1, .PIXELS, 30)
							ui_empty()
							ui_size(.PCT_PARENT, 1, .MIN_SIBLINGS, 1)
							x := ui_empty()
								for yindex in 0..=3 {
									ui_axis(.X)
									ui_size(.PIXELS, 150, .PCT_PARENT, 1)
									ui_button(fmt.tprintf("Fun | %v | %v", index, yindex))
								}
							ui_pop()
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
		if ui_dropdown("Select Me").selected {
			ui_button("first")
			ui_button("second")
		}
		ui_pop()
		ui_axis(.X)
		ui_scrollbar()
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
			ui_queue_panel(state.ui.ctx.panel, .Y, .FLOATING, .PANEL_LIST, 1.0, state.ui.ctx.panel.quad)
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
			ui_queue_panel(state.ui.ctx.panel, .Y, .FLOATING, .PANEL_LIST, 1.0, state.ui.ctx.panel.quad)
		}
	ui_pop()

	ui_size(.PCT_PARENT,0.5, .TEXT,1)
	ui_axis(.Y)
	ui_label("Editable Text:")
	ui_edit_text(&state.debug.text)
	ui_value("TEXT", state.debug.text.mem)
	ui_value("LEN", state.debug.text.len)
	ui_value("START", state.debug.text.start)
	ui_value("END", state.debug.text.end)
	ui_value("len panels", state.ui.panels.pool.nodes_used)
	ui_value("len boxes", len(state.ui.boxes.all))
	ui_end()
}

ui_panel_properties :: proc() {
	ui_begin()
	vp := ui_scrollbox()
		ui_axis(.Y)
		ui_size(.PCT_PARENT, 1, .TEXT, 1)
		for i in 0..=22 {
			label := fmt.tprintf("Label %v", i)
			ui_label(label)
		}
		ui_pop()
	ui_scrollbar()
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
		draw_button := false
		for p, i in Panel_Content {
			if p == .DEBUG do draw_button = true
			if draw_button {
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