package main	

// import "/demo"
import "/ui"
import "core:fmt"
import "core:os"
import "core:path/filepath"

// demo app
App :: struct {
	path: ui.String,
}

state : ^ui.State
app : App

main :: proc() {
	ok := false
	state, ok = ui.init(
		init = panels,
		frame = frame,
		title = "ui odin demo",
		width = 1280,
		height = 720,
	)
}

panels :: proc() {
	using ui

	app.path = from_string("C:/Users/marxn/Desktop/")
	//					parent			 	   direction	type			content						size
	ui_create_panel(nil, 					.Y,			.STATIC, 	top_bar, 		0.3)
	ui_create_panel(state.ui.ctx.panel, .Y,			.DYNAMIC, 	ui_panel_colors, 			0.1)
	// ui_create_panel(state.ui.ctx.panel, .X,			.DYNAMIC, 	ui_panel_properties, 					0.8)
	// ui_create_panel(state.ui.ctx.panel, .Y,			.DYNAMIC, 	ui_lorem, 	0.3)
}

frame :: proc() {
}


// DEMO //

top_bar :: proc() {
	using ui
	ui_begin()
	ui_size(.TEXT, 1, .TEXT, 1)
	ui_axis(.X)
	if ui_button("File").clicked do ui_queue_panel(state.ui.ctx.panel, .Y, .FLOATING, ui_file_menu, 1.0, state.ui.ctx.panel.quad)
	if ui_button("Edit").clicked do ui_queue_panel(state.ui.ctx.panel, .Y, .FLOATING, ui_edit_menu, 1.0, state.ui.ctx.panel.quad)
	if ui_button("View").clicked do ui_queue_panel(state.ui.ctx.panel, .Y, .FLOATING, ui_view_menu, 1.0, state.ui.ctx.panel.quad)
	ui_spacer_fill()
	ui_value("scroll:", state.input.mouse.scroll)
	ui_label("|")
	ui_value("mouse pos:", state.input.mouse.pos)
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
	ui_spacer_pixels(6)
	ui_end()
}

ui_file_menu :: proc() {
	using ui
	panel := ui_begin_menu()
	ui_axis(.Y)
	ui_size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
	ui_empty()
		ui_size(.PIXELS, 200, .TEXT, 1)
		ui_menu_button("New")
		ui_menu_button("Open")
		ui_menu_button("Save")
		ui_menu_button("Save As")
		if ui_menu_button("Exit").clicked do quit()
	ui_pop()
}

ui_edit_menu :: proc() {
	using ui
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
	using ui
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
	using ui
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

ui_panel_colors :: proc() {
	using ui
	ui_begin()
	
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_label("<b>UI Colors")
		ui_spacer_fill()
		ui_size(.PCT_PARENT, .2, .TEXT, 1)
		ui_label("<i>Hue")
		ui_label("<i>Saturation")
		ui_label("<i>Value")
		ui_label("<i>Alpha")
	ui_pop()
	ui_bar(state.ui.col.highlight)
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.PCT_PARENT, .15, .TEXT, 1)
		ui_label("Backdrop:")
		ui_size(.PCT_PARENT, .05, .TEXT, 1)
		ui_color(state.ui.col.bg)
		ui_size(.PCT_PARENT, .2, .TEXT, 1)
		ui_slider("h:", &state.ui.col.backdrop.h)
		ui_slider("s:", &state.ui.col.backdrop.s)
		ui_slider("l:", &state.ui.col.backdrop.l)
		ui_slider("v:", &state.ui.col.backdrop.a)
	ui_pop()
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.PCT_PARENT, .15, .TEXT, 1)
		ui_label("BG:")
		ui_size(.PCT_PARENT, .05, .TEXT, 1)
		ui_color(state.ui.col.bg)
		ui_size(.PCT_PARENT, .2, .TEXT, 1)
		ui_slider("h:", &state.ui.col.bg.h)
		ui_slider("s:", &state.ui.col.bg.s)
		ui_slider("l:", &state.ui.col.bg.l)
		ui_slider("v:", &state.ui.col.bg.a)
	ui_pop()
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.PCT_PARENT, .15, .TEXT, 1)
		ui_label("Gradient:")
		ui_size(.PCT_PARENT, .05, .TEXT, 1)
		ui_color(state.ui.col.gradient)
		ui_size(.PCT_PARENT, .2, .TEXT, 1)
		ui_slider("h:", &state.ui.col.gradient.h)
		ui_slider("s:", &state.ui.col.gradient.s)
		ui_slider("l:", &state.ui.col.gradient.l)
		ui_slider("v:", &state.ui.col.gradient.a)
	ui_pop()
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.PCT_PARENT, .15, .TEXT, 1)
		ui_label("Border:")
		ui_size(.PCT_PARENT, .05, .TEXT, 1)
		ui_color(state.ui.col.border)
		ui_size(.PCT_PARENT, .2, .TEXT, 1)
		ui_slider("h:", &state.ui.col.border.h)
		ui_slider("s:", &state.ui.col.border.s)
		ui_slider("l:", &state.ui.col.border.l)
		ui_slider("v:", &state.ui.col.border.a)
	ui_pop()
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.PCT_PARENT, .15, .TEXT, 1)
		ui_label("Font:")
		ui_size(.PCT_PARENT, .05, .TEXT, 1)
		ui_color(state.ui.col.font)
		ui_size(.PCT_PARENT, .2, .TEXT, 1)
		ui_slider("h:", &state.ui.col.font.h)
		ui_slider("s:", &state.ui.col.font.s)
		ui_slider("l:", &state.ui.col.font.l)
		ui_slider("v:", &state.ui.col.font.a)
	ui_pop()
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.PCT_PARENT, .15, .TEXT, 1)
		ui_label("Hot:")
		ui_size(.PCT_PARENT, .05, .TEXT, 1)
		ui_color(state.ui.col.hot)
		ui_size(.PCT_PARENT, .2, .TEXT, 1)
		ui_slider("h:", &state.ui.col.hot.h)
		ui_slider("s:", &state.ui.col.hot.s)
		ui_slider("l:", &state.ui.col.hot.l)
		ui_slider("v:", &state.ui.col.hot.a)
	ui_pop()
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.PCT_PARENT, .15, .TEXT, 1)
		ui_label("Inactive:")
		ui_size(.PCT_PARENT, .05, .TEXT, 1)
		ui_color(state.ui.col.inactive)
		ui_size(.PCT_PARENT, .2, .TEXT, 1)
		ui_slider("h:", &state.ui.col.inactive.h)
		ui_slider("s:", &state.ui.col.inactive.s)
		ui_slider("l:", &state.ui.col.inactive.l)
		ui_slider("v:", &state.ui.col.inactive.a)
	ui_pop()
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.PCT_PARENT, .15, .TEXT, 1)
		ui_label("Active:")
		ui_size(.PCT_PARENT, .05, .TEXT, 1)
		ui_color(state.ui.col.active)
		ui_size(.PCT_PARENT, .2, .TEXT, 1)
		ui_slider("h:", &state.ui.col.active.h)
		ui_slider("s:", &state.ui.col.active.s)
		ui_slider("l:", &state.ui.col.active.l)
		ui_slider("v:", &state.ui.col.active.a)
	ui_pop()
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	ui_empty()
		ui_axis(.X)
		ui_size(.PCT_PARENT, .15, .TEXT, 1)
		ui_label("Highlight:")
		ui_size(.PCT_PARENT, .05, .TEXT, 1)
		ui_color(state.ui.col.highlight)
		ui_size(.PCT_PARENT, .2, .TEXT, 1)
		ui_slider("h:", &state.ui.col.highlight.h)
		ui_slider("s:", &state.ui.col.highlight.s)
		ui_slider("l:", &state.ui.col.highlight.l)
		ui_slider("v:", &state.ui.col.highlight.a)
	ui_pop()
	ui_end()
}

// ui_lorem :: proc() {
// 	using ui
// 	ui_begin()
// 		ui_axis(.Y)
// 		ui_size(.PCT_PARENT, 1, .TEXT, 1)
// 		ui_empty()
// 			ui_axis(.X)
// 			ui_size(.TEXT, 1, .TEXT, 1)
// 			ui_label("Load text file:")
// 		ui_pop()
// 		ui_axis(.Y)
// 		ui_size(.PCT_PARENT, 1, .TEXT, 1)
// 		ui_empty()
// 			ui_axis(.X)
// 			ui_size(.MIN_SIBLINGS, 1, .TEXT, 1)
// 			ui_edit_text("edit text", &state.debug.path)
// 			ui_size(.TEXT, 1, .TEXT, 1)
// 			if ui_button("Load").released {
// 				load_doc(&state.debug.lorem, to_string(&state.debug.path))
// 			}
// 		ui_pop()
// 		ui_axis(.Y)
// 		if state.ui.boxes.editing == {} {
// 			ui_label("no editing...")
// 		} else {
// 			ui_label(key_to_string(&state.ui.boxes.editing))
// 		}
// 		ui_axis(.Y)
// 		ui_size(.PCT_PARENT, 1, .MIN_SIBLINGS, 1)
// 		ui_empty()
// 		ui_size(.PCT_PARENT, 1, .PCT_PARENT, 1)
// 			ui_paragraph(state.debug.lorem)
// 			ui_pop()
// 		ui_pop()
// 	ui_end()
// }

// ui_panel_tab_test :: proc() {
// 	using ui
// 	ui_begin()
// 	tab_names : []string = {"First", "Second", "Third"}
// 	tabs, index := ui_tab(tab_names)
	
// 	ui_axis(.Y)
// 	ui_size(.PCT_PARENT, 1, .SUM_CHILDREN, 1)
// 	ui_empty()
// 	ui_size(.TEXT, 1, .TEXT, 1)
// 	ui_axis(.Y)
// 	if len(tabs) > 0 {
// 		switch to_string(&tabs[index].name) {
// 			case "First":
// 				ui_button("Tab one | Button 1")
// 				ui_button("Tab one | Button 2")
// 				ui_button("Tab one | Button 3")
// 			case "Second":
// 				ui_button("Tab two | Button 1")
// 				ui_button("Tab two | Button 2")
// 				ui_button("Tab two | Button 3")
// 			case "Third":
// 				ui_button("Tab three | Button 1")
// 				ui_button("Tab three | Button 2")
// 				ui_button("Tab three | Button 3")
// 		}
// 	}
// 	ui_end()
// }

// ui_panel_boxlist :: proc() {
// 	using ui
// 	ui_begin()
// 	ui_axis(.Y)
// 	ui_size(.PCT_PARENT, 1, .TEXT, 1)
// 	ui_empty()
// 		ui_axis(.X)
// 		ui_size(.TEXT, 1, .TEXT, 1)
// 		if ui_button("<#>p").released {
// 			ui_queue_panel(state.ui.ctx.panel, .Y, .FLOATING, ui_panel_pick_panel, 1.0, state.ui.ctx.panel.quad)
// 		}
// 	ui_pop()
// 	ui_axis(.Y)
// 	ui_size(.PCT_PARENT, 1, .TEXT, 1)
// 	ui_value("box length", len(state.ui.boxes.all))
// 	ui_size(.PCT_PARENT, 1, .TEXT, 6)
// 	ui_scrollbox()
// 		ui_axis(.Y)
// 		ui_size(.PCT_PARENT, 1, .SUM_CHILDREN, 1)
// 		ui_empty()
// 		ui_size(.PCT_PARENT, 1, .TEXT, 1)
// 		ui_label("Panel List:")
// 		for key, panel in state.ui.panels.all {
// 			if panel.box != nil {
// 				ui_button(fmt.tprint(panel.uid, " | ", panel.content, "<#>d ", panel.box.key.len))
// 			} else {
// 				ui_button(fmt.tprint(panel.uid, " | ", panel.content))
// 			}
// 		}
// 		ui_pop()
// 	ui_end()
// }

// ui_panel_debug :: proc() {
// 	using ui
// 	ui_begin()
// 	ui_axis(.Y)
// 	ui_size(.PCT_PARENT, 1, .TEXT, 1)
// 	ui_empty()
// 		ui_axis(.X)
// 		ui_size(.TEXT, 1, .TEXT, 1)
// 		if ui_button("<#>p").released {
// 			ui_queue_panel(state.ui.ctx.panel, .Y, .FLOATING, ui_panel_pick_panel, 1.0, state.ui.ctx.panel.quad)
// 		}
// 	ui_pop()

// 	ui_size(.PCT_PARENT,0.5, .TEXT,1)
// 	ui_axis(.Y)
// 	ui_label("Editable Text:")
// 	ui_edit_text("editable text", &state.debug.text)
// 	ui_value("TEXT", state.debug.text.mem)
// 	ui_value("LEN", state.debug.text.len)
// 	ui_value("START", state.debug.text.start)
// 	ui_value("END", state.debug.text.end)
// 	ui_value("len panels", state.ui.panels.pool.nodes_used)
// 	ui_value("len boxes", len(state.ui.boxes.all))
// 	ui_end()
// }

// ui_panel_properties :: proc() {
// 	using ui
// 	ui_begin()
// 	ui_scrollbox()
// 		ui_axis(.Y)
// 		ui_size(.PCT_PARENT, 1, .SUM_CHILDREN, 1 )
// 		ui_empty()
// 		ui_size(.PCT_PARENT, 1, .TEXT, 1)
// 		// ui_label("WHEE")
// 		ui_edit_value("Float", state.debug.float)
// 		for i in 0..=22 {
// 			label := fmt.tprint("Label", i)
// 			ui_button(label)
// 		}
// 		ui_pop()
// 	ui_end()
// }

// ui_panel_pick_panel :: proc() {
// 	using ui
// 	panel := ui_begin_floating()
// 	ui_axis(.Y)
// 	ui_size(.SUM_CHILDREN, 1, .TEXT, 1)
// 	ui_empty()
// 		ui_axis(.X)
// 		ui_size(.PIXELS, 250, .TEXT, 1)
// 		ui_drag_panel("Select Panel:")
// 		ui_size(.TEXT, 1, .TEXT, 1)
// 		// ui_spacer_pixels(120)
// 		if ui_button("<#>x").released {
// 			if state.ui.panels.floating != nil {
// 				ui_delete_panel(state.ui.panels.floating)
// 			}
// 		}
// 	ui_pop()

// 	ui_axis(.Y)
// 	ui_size(.PCT_PARENT, 1, .SUM_CHILDREN, 1)
// 	ui_empty()
// 		ui_size(.PCT_PARENT, 1, .TEXT, 1)
// 		if ui_button("ui_panel_pick_panel()").released {
// 			panel.parent.content = ui_panel_pick_panel
// 			ui_delete_panel(panel)
// 		}
// 	ui_pop()
// 	ui_end()
// }

// ui_panel_floater :: proc() {
// 	using ui
// 	ui_begin_floating()
// 	ui_size(.SUM_CHILDREN, 1, .SUM_CHILDREN, 1)
// 	ui_empty()
// 		ui_axis(.X)
// 		ui_size(.TEXT, 1, .TEXT, 1)
// 		ui_label("FLOATING PANEL")
// 		ui_spacer_pixels(50)
// 		if ui_button("<#>x").released do ui_delete_panel(state.ui.panels.floating)
// 	ui_pop()
// 	ui_end()
// }

// file_browser :: proc () {
// 	using ui
// 	ui_begin_floating()
// 	ui_axis(.Y)
// 	ui_size(.PIXELS, 600, .SUM_CHILDREN, 1)
// 	ui_empty()
// 		ui_axis(.X)
// 		ui_size(.PCT_PARENT, 1, .TEXT, 1)
// 		ui_empty()
// 			ui_size(.MIN_SIBLINGS, 1, .TEXT, 1)
// 			ui_drag_panel("Load file:")
// 			ui_size(.TEXT, 1, .TEXT, 1)
// 			if ui_button("<#>x").released do ui_delete_panel(state.ui.panels.floating)
// 		ui_pop()
// 		ui_axis(.Y)
// 		ui_size(.PCT_PARENT, 1, .TEXT, 1)
// 		ui_edit_text("file browser", &app.path)
// 		ui_size(.PCT_PARENT, 1, .TEXT, 12)
// 		ui_scrollbox()
// 		ui_axis(.Y)
// 		ui_size(.PCT_PARENT, 1, .SUM_CHILDREN, 1)
// 		ui_empty()
// 		ui_axis(.Y)
// 		ui_size(.PCT_PARENT, 1, .TEXT, 1)

// 		find_files_and_run(ui_button, ".txt")
// 	ui_pop()
// 	ui_end()
// }

// find_files_and_run :: proc(run:proc(string) -> ui.Box_Ops, filter:string="") {
// 	using ui, filepath
// 	if app.path.mem[app.path.len] == '\\' {
// 		app.path.mem[app.path.len] = 0
// 		app.path.len -= 1
// 	}
// 	path := to_string(&app.path)
// 	if os.is_dir(path) {
// 		handle, hok := os.open(path)
// 		file_list, fok := os.read_dir(handle, 0)

// 		if run("..").released {
// 			for i := app.path.len-1; i > 0; i -= 1 {
// 				char := app.path.mem[i]
// 				app.path.mem[i] = 0
// 				app.path.len -= 1
// 				if char == '\\' {
// 					break
// 				}
// 			}
// 		}
// 		for file in file_list {
// 			if file.is_dir {
// 				if run(fmt.tprintf("%v%v", "<#>g<b>", file.name)).released {
// 					replace_string(&app.path, fmt.tprintf("%v%v%v", path[:len(path)], '\\', file.name))
// 				}
// 			} else {
// 				skip := false
// 				if filter != "" && ext(file.name) != filter do skip = true
// 				if !skip {
// 					if run(file.name).released {
// 						switch ext(file.name) {
// 							case ".txt":
// 								open_tsv(file.fullpath)
// 						}
// 						state.ui.boxes.editing = {}
// 						ui_delete_panel(state.ui.panels.floating)
// 					}
// 				}
// 			}
// 		}
// 	}
// }

// // DOC DEMO //

// Document :: struct {
// 	mem: []u8,
// 	len: int,

// 	returns: []int,
// 	return_count: int,

// 	width: f32,
// 	lines: int,
// 	current_line: int,
// 	last_line: int,
// 	current_char: int,
// 	// index: int,
// 	// start: int,
// 	// end: int,
// }

// load_doc :: proc(doc:^Document, filename:string) -> bool {
// 	close_doc(doc)
	
// 	fmt.println("trying to load doc:", filename)
// 	doc_ok := false
// 		doc.mem, doc_ok = os.read_entire_file(filename)
// 	if !doc_ok {
// 		fmt.println("ERROR LOADING", filename)
// 		return false
// 	}
// 	doc.len = len(doc.mem)

// 	temp_returns := make([]int, doc.len)
// 	defer delete(temp_returns)

// 	return_count := 0
// 	for char, index in doc.mem {
// 		if char == '\n' {
// 			return_count += 1
// 			temp_returns[return_count] = index
// 		}
// 	}
	
// 	doc.returns = make([]int, return_count)
// 	copy(doc.returns[:], temp_returns[:return_count])
// 	doc.return_count = return_count

// 	return true
// }

// close_doc :: proc(doc: ^Document) -> bool {
// 	fmt.println("closing doc")
// 	delete(doc.mem)
// 	delete(doc.returns)
// 	doc^ = {}
// 	return true
// }

