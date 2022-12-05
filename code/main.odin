package main	

import "/ui"
import "core:fmt"
import "core:os"
import "core:path/filepath"

// demo app
App :: struct {
	path: ui.String,
	panels: [5]Panel,
	lorem: ui.String,
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
		3 = {panel_lorem, "Lorem"},
		4 = {panel_tab_test, "Tab Test"},
	}

	ui.init(
		init = app_init,
		loop = app_loop,
		title = "ui odin demo",
		width = 1280,
		height = 720,
	)
}

app_init :: proc() {
	app.lorem = ui.from_odin_string("This is some text\nthat goes on two linse!\n\nHere is somre more text. Even more text that doesn't have returns in it, but goes on for a bit.\n")
	app.path = ui.from_odin_string("C:/Users/marxn/Desktop/")

	//					parent			 	   direction	type			content						size
	ui.create_panel(nil, 					.Y,			.STATIC, 	top_bar, 		0.3)
	ui.create_panel(ui.state.ctx.panel, .Y,			.DYNAMIC, 	panel_colors, 			0.1)
	ui.create_panel(ui.state.ctx.panel, .X,			.DYNAMIC, 	panel_lorem, 					0.7)
	ui.create_panel(ui.state.ctx.panel, .Y,			.DYNAMIC, 	panel_tab_test, 	0.4)
}

app_loop :: proc() {
	if ui.rmb_click() {
		ui.queue_panel(ui.state.panels.hot, .Y, .FLOATING, panel_pick_panel, 1.0, ui.state.panels.hot.quad)
	}
}

app_load_text_file :: proc(_path:string="") {
	fmt.println("trying to load", ui.to_odin_string(&app.path))
	path : string  
	if _path != "" {
		path = _path
	} else {
		path = ui.to_odin_string(&app.path)
	}

	data, ok := os.read_entire_file(path)
	if !ok {
		fmt.println("Failed to load file!")
		return
	}

	app.lorem = ui.from_odin_string(string(data[:]))

}

// DEMO //
top_bar :: proc() {
	using ui
	ui.begin()
	ui.size(.TEXT, 1, .TEXT, 1)
	ui.axis(.X)
	labels: []string = {"File", "Edit", "View"}
	epanels: []proc() = {file_menu, edit_menu, view_menu}

	mbuttons, active := ui.menu("Main Menu", labels)
	for ep, i in epanels {
		if mbuttons[i].ops.released do ui.queue_panel(state.ctx.panel, .Y, .FLOATING, ep, 1.0, state.ctx.panel.quad)
	}

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

	color_row :: proc(name: string, col:^ui.HSL) {
		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		ui.empty()
			ui.axis(.X)
			ui.size(.PCT_PARENT, .15, .TEXT, 1)
			ui.label(name)
			ui.size(.PCT_PARENT, .05, .TEXT, 1)
			ui.color(col^)
			ui.size(.PCT_PARENT, .2, .TEXT, 1)
			ui.slider("h:", &col.h)
			ui.slider("s:", &col.s)
			ui.slider("l:", &col.l)
			ui.slider("v:", &col.a)
		ui.pop()
	}

	color_row("Backdrop:", &state.col.backdrop)
	color_row("Background:", &state.col.bg)
	color_row("Gradient:", &state.col.gradient)
	color_row("Border:", &state.col.border)
	color_row("Font:", &state.col.font)
	color_row("Hot:", &state.col.hot)
	color_row("Inactive:", &state.col.inactive)
	color_row("Active:", &state.col.active)
	color_row("Highlight:", &state.col.highlight)
}

panel_lorem :: proc() {
	using ui
	panel := ui.begin()
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
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		ui.empty()
			ui.axis(.X)
			ui.size(.PCT_PARENT, 1, .TEXT, 1)
			if ui.menu_button("Open Text File").clicked {
				ui.queue_panel(panel, .Y, .FLOATING, file_browser, 1.0, state.ctx.panel.quad)
			}
		ui.pop()
		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .MIN_SIBLINGS, 1)
		ui.empty()
		ui.size(.PCT_PARENT, 1, .PCT_PARENT, 1)
			ui.paragraph(&app.lorem)
			ui.pop()
		ui.pop()
	ui.end()
}

panel_tab_test :: proc() {
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

	tab_names : []string = {"First", "Second", "Third"}
	
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .MIN_SIBLINGS, 1)
	ui.empty()
		ui.axis(.X)
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		tabs, index := ui.tab(tab_names)
		

		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .SUM_CHILDREN, 1)
		ui.empty()
		ui.size(.TEXT, 1, .TEXT, 1)
		ui.axis(.Y)
		if len(tabs) > 0 {
			switch index {
				case 0:
					ui.button("Tab one | Button 1")
					ui.button("Tab one | Button 2")
					ui.button("Tab one | Button 3")
				case 1:
					ui.button("Tab two | Button 1")
					ui.button("Tab two | Button 2")
					ui.button("Tab two | Button 3")
				case 2:
					ui.button("Tab three | Button 1")
					ui.button("Tab three | Button 2")
					ui.button("Tab three | Button 3")
			}
		}
	ui.pop()
	ui.end()
}

panel_boxlist :: proc() {
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
	ui.scrollbox()
		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .SUM_CHILDREN, 1)
		ui.empty()
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		ui.label("Panel List:")
		for key, panel in ui.state.panels.all {
			if panel.box != nil {
				ui.axis(.Y)
				ui.size(.PCT_PARENT, 1, .TEXT, 1)
				ui.label(fmt.tprint("PANEL ID:", panel.uid))
				indent :f32= 0
				for first := panel.box; first != nil; first = first.first {
					indent += 1
					for next := first.next; next != nil; next = next.next {
						ui.axis(.Y)
						ui.size(.PCT_PARENT, 1, .TEXT, 1)
						ui.empty()
						ui.spacer_pixels(10*indent)
						ui.axis(.X)
						ui.size(.TEXT, 1, .TEXT, 1)
						ui.label(fmt.tprint(" <> ", ui.key_to_odin_string(&next.key)))
						ui.pop()
					}
				}
			} else {
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
	path := to_odin_string(&app.path)
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
								app_load_text_file(file.fullpath)
						}
						state.boxes.editing = {}
						ui.delete_panel(state.panels.floating)
					}
				}
			}
		}
	}
}
