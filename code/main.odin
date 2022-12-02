package main	

import "/ui"
import "core:fmt"
import "core:os"
import "core:path/filepath"

// demo app
App :: struct {
	path: ui.String,
	panels: [3]Panel,
}

Panel :: struct {
	content: proc(),
	name: string,
}

// state : ^ui.State
app : App

main :: proc() {
	app.panels = {
		0 = {panel_colors, "colors"},
		1 = {panel_properties, "properties"},
		2 = {panel_boxlist, "boxlist"},
	}

	ui.init(
		init = panels,
		loop = loop,
		title = "ui odin demo",
		width = 1280,
		height = 720,
	)
}

panels :: proc() {
	app.path = ui.from_string("C:/Users/marxn/Desktop/")
	//					parent			 	   direction	type			content						size
	ui.create_panel(nil, 					.Y,			.STATIC, 	top_bar, 		0.3)
	ui.create_panel(ui.state.ctx.panel, .Y,			.DYNAMIC, 	panel_colors, 			0.1)
	ui.create_panel(ui.state.ctx.panel, .X,			.DYNAMIC, 	panel_properties, 					0.8)
	ui.create_panel(ui.state.ctx.panel, .Y,			.DYNAMIC, 	panel_boxlist, 	0.3)
}

loop :: proc() {
}


// DEMO //

top_bar :: proc() {
	using ui
	ui.begin()
	ui.size(.TEXT, 1, .TEXT, 1)
	ui.axis(.X)
	if ui.button("File").clicked do ui.queue_panel(state.ctx.panel, .Y, .FLOATING, file_menu, 1.0, state.ctx.panel.quad)
	if ui.button("Edit").clicked do ui.queue_panel(state.ctx.panel, .Y, .FLOATING, edit_menu, 1.0, state.ctx.panel.quad)
	if ui.button("View").clicked do ui.queue_panel(state.ctx.panel, .Y, .FLOATING, view_menu, 1.0, state.ctx.panel.quad)
	ui.spacer_fill()
	ui.value("scroll:", state.input.mouse.scroll)
	ui.label("|")
	ui.value("mouse pos:", state.input.mouse.pos)
	ui.label("|")
	ui.value("window width:", state.window.size.x)
	ui.label("|")
	ui.value("fb width:", state.window.framebuffer.x)
	ui.label("|")
	ui.value("boxes:", state.boxes.pool.nodes_used)
	ui.value("/", state.boxes.pool.chunk_count)
	ui.label("|")
	ui.value("panels:", state.panels.pool.nodes_used)
	ui.value("/", state.panels.pool.chunk_count)
	ui.spacer_pixels(6)
	ui.end()
}

file_menu :: proc() {
	using ui
	panel := ui.begin_menu()
	ui.axis(.Y)
	ui.size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
	ui.empty()
		ui.size(.PIXELS, 200, .TEXT, 1)
		ui.menu_button("New")
		if ui.menu_button("Open").clicked {
			ui.queue_panel(panel, .Y, .FLOATING, file_browser, 1.0, state.ctx.panel.quad)
		}
		ui.menu_button("Save")
		ui.menu_button("Save As")
		if ui.menu_button("Exit").clicked do quit()
	ui.pop()
}

edit_menu :: proc() {
	using ui
	panel := ui.begin_menu()
	ui.axis(.Y)
	ui.size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
	ui.empty()
		ui.size(.PIXELS, 200, .TEXT, 1)
		ui.menu_button("Cut")
		ui.menu_button("Copy")
		ui.menu_button("Paste")
	ui.pop()
}

view_menu :: proc() {
	using ui
	panel := ui.begin_menu()
	ui.axis(.Y)
	ui.size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
	ui.empty()
		ui.size(.PIXELS, 200, .TEXT, 1)
		ui.menu_button("Some Stuff")
		ui.menu_button("More Stuff")
		ui.menu_button("Everything")
	ui.pop()
}

ctx_panel :: proc() {
	using ui
	panel := ui.begin_floating_menu()
	ui.axis(.Y)
	ui.size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
	ui.empty()
		ui.size(.PIXELS, 200, .TEXT, 1)
		ui.menu_button("Cut")
		ui.menu_button("Copy")
		ui.menu_button("Paste")
	ui.pop()
}

panel_colors :: proc() {
	using ui
	ui.begin()
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty()
		ui.axis(.X)
		ui.size(.TEXT, 1, .TEXT, 1)
		if ui.button("<#>p").released {
			ui.queue_panel(state.ctx.panel, .Y, .FLOATING, panel_pick_panel, 1.0, state.ctx.panel.quad)
		}
	ui.pop()
	
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty()
		ui.axis(.X)
		ui.label("<b>UI Colors")
		ui.spacer_fill()
		ui.size(.PCT_PARENT, .2, .TEXT, 1)
		ui.label("<i>Hue")
		ui.label("<i>Saturation")
		ui.label("<i>Value")
		ui.label("<i>Alpha")
	ui.pop()
	ui.bar(state.col.highlight)
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty()
		ui.axis(.X)
		ui.size(.PCT_PARENT, .15, .TEXT, 1)
		ui.label("Backdrop:")
		ui.size(.PCT_PARENT, .05, .TEXT, 1)
		ui.color(state.col.bg)
		ui.size(.PCT_PARENT, .2, .TEXT, 1)
		ui.slider("h:", &state.col.backdrop.h)
		ui.slider("s:", &state.col.backdrop.s)
		ui.slider("l:", &state.col.backdrop.l)
		ui.slider("v:", &state.col.backdrop.a)
	ui.pop()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty()
		ui.axis(.X)
		ui.size(.PCT_PARENT, .15, .TEXT, 1)
		ui.label("BG:")
		ui.size(.PCT_PARENT, .05, .TEXT, 1)
		ui.color(state.col.bg)
		ui.size(.PCT_PARENT, .2, .TEXT, 1)
		ui.slider("h:", &state.col.bg.h)
		ui.slider("s:", &state.col.bg.s)
		ui.slider("l:", &state.col.bg.l)
		ui.slider("v:", &state.col.bg.a)
	ui.pop()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty()
		ui.axis(.X)
		ui.size(.PCT_PARENT, .15, .TEXT, 1)
		ui.label("Gradient:")
		ui.size(.PCT_PARENT, .05, .TEXT, 1)
		ui.color(state.col.gradient)
		ui.size(.PCT_PARENT, .2, .TEXT, 1)
		ui.slider("h:", &state.col.gradient.h)
		ui.slider("s:", &state.col.gradient.s)
		ui.slider("l:", &state.col.gradient.l)
		ui.slider("v:", &state.col.gradient.a)
	ui.pop()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty()
		ui.axis(.X)
		ui.size(.PCT_PARENT, .15, .TEXT, 1)
		ui.label("Border:")
		ui.size(.PCT_PARENT, .05, .TEXT, 1)
		ui.color(state.col.border)
		ui.size(.PCT_PARENT, .2, .TEXT, 1)
		ui.slider("h:", &state.col.border.h)
		ui.slider("s:", &state.col.border.s)
		ui.slider("l:", &state.col.border.l)
		ui.slider("v:", &state.col.border.a)
	ui.pop()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty()
		ui.axis(.X)
		ui.size(.PCT_PARENT, .15, .TEXT, 1)
		ui.label("Font:")
		ui.size(.PCT_PARENT, .05, .TEXT, 1)
		ui.color(state.col.font)
		ui.size(.PCT_PARENT, .2, .TEXT, 1)
		ui.slider("h:", &state.col.font.h)
		ui.slider("s:", &state.col.font.s)
		ui.slider("l:", &state.col.font.l)
		ui.slider("v:", &state.col.font.a)
	ui.pop()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty()
		ui.axis(.X)
		ui.size(.PCT_PARENT, .15, .TEXT, 1)
		ui.label("Hot:")
		ui.size(.PCT_PARENT, .05, .TEXT, 1)
		ui.color(state.col.hot)
		ui.size(.PCT_PARENT, .2, .TEXT, 1)
		ui.slider("h:", &state.col.hot.h)
		ui.slider("s:", &state.col.hot.s)
		ui.slider("l:", &state.col.hot.l)
		ui.slider("v:", &state.col.hot.a)
	ui.pop()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty()
		ui.axis(.X)
		ui.size(.PCT_PARENT, .15, .TEXT, 1)
		ui.label("Inactive:")
		ui.size(.PCT_PARENT, .05, .TEXT, 1)
		ui.color(state.col.inactive)
		ui.size(.PCT_PARENT, .2, .TEXT, 1)
		ui.slider("h:", &state.col.inactive.h)
		ui.slider("s:", &state.col.inactive.s)
		ui.slider("l:", &state.col.inactive.l)
		ui.slider("v:", &state.col.inactive.a)
	ui.pop()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty()
		ui.axis(.X)
		ui.size(.PCT_PARENT, .15, .TEXT, 1)
		ui.label("Active:")
		ui.size(.PCT_PARENT, .05, .TEXT, 1)
		ui.color(state.col.active)
		ui.size(.PCT_PARENT, .2, .TEXT, 1)
		ui.slider("h:", &state.col.active.h)
		ui.slider("s:", &state.col.active.s)
		ui.slider("l:", &state.col.active.l)
		ui.slider("v:", &state.col.active.a)
	ui.pop()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty()
		ui.axis(.X)
		ui.size(.PCT_PARENT, .15, .TEXT, 1)
		ui.label("Highlight:")
		ui.size(.PCT_PARENT, .05, .TEXT, 1)
		ui.color(state.col.highlight)
		ui.size(.PCT_PARENT, .2, .TEXT, 1)
		ui.slider("h:", &state.col.highlight.h)
		ui.slider("s:", &state.col.highlight.s)
		ui.slider("l:", &state.col.highlight.l)
		ui.slider("v:", &state.col.highlight.a)
	ui.pop()
	ui.end()
}

lorem :: proc() {
	using ui
	ui.begin()
		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		ui.empty()
			ui.axis(.X)
			ui.size(.TEXT, 1, .TEXT, 1)
			ui.label("Load text file:")
		ui.pop()
		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		ui.empty()
			ui.axis(.X)
			ui.size(.MIN_SIBLINGS, 1, .TEXT, 1)
			ui.edit_text("edit text", &app.path)
			ui.size(.TEXT, 1, .TEXT, 1)
			if ui.button("Load").released {
				// load_doc(&app.lorem, to_string(&app.path))
			}
		ui.pop()
		ui.axis(.Y)
		if state.boxes.editing == {} {
			ui.label("no editing...")
		} else {
			ui.label(key_to_string(&state.boxes.editing))
		}
		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .MIN_SIBLINGS, 1)
		ui.empty()
		ui.size(.PCT_PARENT, 1, .PCT_PARENT, 1)
			// ui.paragraph(state.debug.lorem)
			// ui.pop()
		ui.pop()
	ui.end()
}

// ui.panel_tab_test :: proc() {
// 	using ui
// 	ui.begin()
// 	tab_names : []string = {"First", "Second", "Third"}
// 	tabs, index := ui.tab(tab_names)
	
// 	ui.axis(.Y)
// 	ui.size(.PCT_PARENT, 1, .SUM_CHILDREN, 1)
// 	ui.empty()
// 	ui.size(.TEXT, 1, .TEXT, 1)
// 	ui.axis(.Y)
// 	if len(tabs) > 0 {
// 		switch to_string(&tabs[index].name) {
// 			case "First":
// 				ui.button("Tab one | Button 1")
// 				ui.button("Tab one | Button 2")
// 				ui.button("Tab one | Button 3")
// 			case "Second":
// 				ui.button("Tab two | Button 1")
// 				ui.button("Tab two | Button 2")
// 				ui.button("Tab two | Button 3")
// 			case "Third":
// 				ui.button("Tab three | Button 1")
// 				ui.button("Tab three | Button 2")
// 				ui.button("Tab three | Button 3")
// 		}
// 	}
// 	ui.end()
// }

panel_boxlist :: proc() {
	using ui
	ui.begin()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty()
		ui.axis(.X)
		ui.size(.TEXT, 1, .TEXT, 1)
		if ui.button("<#>p").released {
			ui.queue_panel(state.ctx.panel, .Y, .FLOATING, panel_pick_panel, 1.0, state.ctx.panel.quad)
		}
	ui.pop()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 6)
	ui.scrollbox()
		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .SUM_CHILDREN, 1)
		ui.empty()
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		ui.label("Panel List:")
		for key, panel in state.panels.all {
			if panel.box != nil {
				ui.button(fmt.tprint(panel.uid, " | ", panel.content, "<#>d ", panel.box.key.len))
			} else {
				ui.button(fmt.tprint(panel.uid, " | ", panel.content))
			}
		}
		ui.pop()
	ui.end()
}

panel_properties :: proc() {
	ui.begin()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty()
		ui.axis(.X)
		ui.size(.TEXT, 1, .TEXT, 1)
		if ui.button("<#>p").released {
			ui.queue_panel(ui.state.ctx.panel, .Y, .FLOATING, panel_pick_panel, 1.0, ui.state.ctx.panel.quad)
		}
	ui.pop()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .MIN_SIBLINGS, 1)
	ui.empty()
		ui.scrollbox()
			ui.axis(.Y)
			ui.size(.PCT_PARENT, 1, .SUM_CHILDREN, 1 )
			ui.empty()
				ui.size(.PCT_PARENT, 1, .TEXT, 1)
				ui.empty("e frame")
					ui.axis(.X)
					ui.size(.PCT_PARENT, 0.5, .PCT_PARENT, 1)
					ui.label("frame:")
					ui.value("vframe", ui.state.frame)
				ui.pop()
				ui.axis(.Y)
				ui.size(.PCT_PARENT, 1, .TEXT, 1)
				ui.label(fmt.tprint("font size:", ui.state.font.size))

				for i in 0..=22 {
					label := fmt.tprint("Random Label", i)
					ui.button(label)
				}
			ui.pop()
	ui.pop()
	ui.end()
}

panel_pick_panel :: proc() {
	using ui
	panel := ui.begin_floating()
	ui.axis(.Y)
	ui.size(.SUM_CHILDREN, 1, .TEXT, 1)
	ui.empty()
		ui.axis(.X)
		ui.size(.PIXELS, 250, .TEXT, 1)
		ui.drag_panel("Select Panel:")
		ui.size(.TEXT, 1, .TEXT, 1)
		// ui.spacer_pixels(120)
		if ui.button("<#>x").released {
			if state.panels.floating != nil {
				ui.delete_panel(state.panels.floating)
			}
		}
	ui.pop()

	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .SUM_CHILDREN, 1)
	ui.empty()
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		for p in app.panels {
			if ui.button(p.name).released {
				panel.parent.content = p.content
				ui.delete_panel(panel)
			}
		}
	ui.pop()
	ui.end()
}

// ui.panel_floater :: proc() {
// 	using ui
// 	ui.begin_floating()
// 	ui.size(.SUM_CHILDREN, 1, .SUM_CHILDREN, 1)
// 	ui.empty()
// 		ui.axis(.X)
// 		ui.size(.TEXT, 1, .TEXT, 1)
// 		ui.label("FLOATING PANEL")
// 		ui.spacer_pixels(50)
// 		if ui.button("<#>x").released do ui.delete_panel(state.panels.floating)
// 	ui.pop()
// 	ui.end()
// }

file_browser :: proc () {
	using ui
	ui.begin_floating()
	ui.axis(.Y)
	ui.size(.PIXELS, 600, .SUM_CHILDREN, 1)
	ui.empty()
		ui.axis(.X)
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		ui.empty()
			ui.size(.MIN_SIBLINGS, 1, .TEXT, 1)
			ui.drag_panel("Load file:")
			ui.size(.TEXT, 1, .TEXT, 1)
			if ui.button("<#>x").released do ui.delete_panel(state.panels.floating)
		ui.pop()
		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		ui.edit_text("file browser", &app.path)
		ui.size(.PCT_PARENT, 1, .TEXT, 12)
		ui.scrollbox()
		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .SUM_CHILDREN, 1)
		ui.empty()
		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .TEXT, 1)

		find_files_and_run(ui.button, ".txt")
	ui.pop()
	ui.end()
}

find_files_and_run :: proc(run:proc(string) -> ui.Box_Ops, filter:string="") {
	using ui, filepath
	if app.path.mem[app.path.len] == '\\' {
		app.path.mem[app.path.len] = 0
		app.path.len -= 1
	}
	path := to_string(&app.path)
	if os.is_dir(path) {
		handle, hok := os.open(path)
		file_list, fok := os.read_dir(handle, 0)

		if run("..").released {
			for i := app.path.len-1; i > 0; i -= 1 {
				char := app.path.mem[i]
				app.path.mem[i] = 0
				app.path.len -= 1
				if char == '\\' {
					break
				}
			}
		}
		for file in file_list {
			if file.is_dir {
				if run(fmt.tprintf("%v%v", "<#>g<b>", file.name)).released {
					replace_string(&app.path, fmt.tprintf("%v%v%v", path[:len(path)], '\\', file.name))
				}
			} else {
				skip := false
				if filter != "" && ext(file.name) != filter do skip = true
				if !skip {
					if run(file.name).released {
						switch ext(file.name) {
							case ".txt":
								// open_tsv(file.fullpath)
						}
						state.boxes.editing = {}
						ui.delete_panel(state.panels.floating)
					}
				}
			}
		}
	}
}

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

