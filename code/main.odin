package main	

import "/ui"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:mem"

// demo app
App :: struct {
	path: ui.String,
	panels: [5]Panel,
	lorem: ui.String,
	image: ui.Image,
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

	// ui.load_image("C:/Users/marxn/Desktop/jack2.png", &app.image)
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

simple :: proc() {
	ui.begin()
	ui.label("Sokol")
	ui.end()
}

// DEMO //
top_bar :: proc() {
	panel := ui.begin()
	ui.size(.MIN_SIBLINGS, 1, .TEXT, 1)
	labels: []string = {"File", "Edit", "View"}
	mbuttons, active := ui.menu("Main Menu", labels)
	if active != nil {
		for button, i in mbuttons {
			if button.key == active.key {
				ui.size(.PIXELS, 200, .TEXT, 1)
				switch labels[i] {
					case "File":
						if ui.menu_button("Open").released {
							ui.queue_panel(ui.state.ctx.panel, .Y, .FLOATING, file_browser, 1.0, ui.state.ctx.panel.quad)
							active.ops.selected = false
						}
						ui.menu_button("Close")
						if ui.menu_button("Exit").released do ui.quit()
					case "Edit":
						ui.menu_button("Edit?")
					case "View":
						ui.menu_button("View?")
				}
				ui.layer(0)
				ui.pop(3)
			}
		}
	}
	ui.menu_end()
	ui.axis(.X)
	ui.size(.TEXT, 1, .TEXT, 1)
	ui.label("scroll:")
	ui.value("scroll:", ui.state.input.mouse.scroll)
	ui.label("|###1")
	ui.value("mouse pos:", ui.state.input.mouse.pos)
	ui.label("|###2")
	ui.value("window width:", ui.state.window.size.x)
	ui.label("|###3")
	ui.value("fb width:", ui.state.window.framebuffer.x)
	ui.label("pages")
	ui.value("pages:", ui.state.boxes.pool.num_pages)
	ui.label("boxes")
	ui.value("boxes:", ui.state.boxes.pool.nodes_used)
	ui.label("nodes per pg")
	ui.value("nodes per page:", ui.state.boxes.pool.nodes_per_page)
	ui.label(fmt.tprint("total memory alloced:", ui.state.boxes.pool.num_pages * ui.state.boxes.pool.page_size))
	ui.label("|###4")
	ui.value("panels:", ui.state.panels.pool.nodes_used)
	ui.value("/", ui.state.panels.pool.nodes_per_page)
	ui.spacer_pixels("topbar", 6)
	ui.end()
}

ctx_panel :: proc() {
	panel := ui.begin()
	ui.axis(.Y)
	ui.size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
	ui.empty("ctx panel")
		ui.size(.PIXELS, 200, .TEXT, 1)
		ui.menu_button("Cut")
		ui.menu_button("Copy")
		ui.menu_button("Paste")
	ui.pop()
}

panel_colors :: proc() {
	panel := ui.begin()
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty("panel_switcher_icon")
		ui.axis(.X)
		ui.size(.TEXT, 1, .TEXT, 1)
		if ui.button("<#> p ").released {
			ui.queue_panel(ui.state.ctx.panel, .Y, .FLOATING, panel_pick_panel, 1.0, ui.state.ctx.panel.quad)
		}
	ui.pop()

	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty("color_labels")
		ui.axis(.X)
		ui.label("<b>UI Colors")
		ui.spacer_fill("color_labels")
		ui.size(.PCT_PARENT, .2, .TEXT, 1)
		ui.label("<i>Hue")
		ui.label("<i>Saturation")
		ui.label("<i>Value")
		ui.label("<i>Alpha")
	ui.pop()
	ui.bar("color_separator", 1, ui.state.col.highlight)

	color_row :: proc(name: string, col:^ui.HSL) {
		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		ui.empty(ui.concat(name, "color_values"))
			ui.axis(.X)
			ui.size(.PCT_PARENT, .15, .TEXT, 1)
			ui.label(name)
			ui.size(.PCT_PARENT, .05, .TEXT, 1)
			ui.color(ui.concat(name, "col"), col^)
			ui.size(.PCT_PARENT, .2, .TEXT, 1)
			ui.slider(ui.concat(name, "h:"), &col.h)
			ui.slider(ui.concat(name, "s:"), &col.s)
			ui.slider(ui.concat(name, "l:"), &col.l)
			ui.slider(ui.concat(name, "v:"), &col.a)
		ui.pop()
	}

	color_row("Backdrop:", &ui.state.col.backdrop)
	color_row("Background:", &ui.state.col.bg)
	color_row("Gradient:", &ui.state.col.gradient)
	color_row("Border:", &ui.state.col.border)
	color_row("Font:", &ui.state.col.font)
	color_row("Hot:", &ui.state.col.hot)
	color_row("Inactive:", &ui.state.col.inactive)
	color_row("Active:", &ui.state.col.active)
	color_row("Highlight:", &ui.state.col.highlight)
	ui.end()
}

panel_lorem :: proc() {
	panel := ui.begin()
		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		ui.empty("panel_switcher_icon")
			ui.axis(.X)
			ui.size(.TEXT, 1, .TEXT, 1)
			if ui.button("<#> p ").released {
				ui.queue_panel(ui.state.ctx.panel, .Y, .FLOATING, panel_pick_panel, 1.0, ui.state.ctx.panel.quad)
			}
		ui.pop()

		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		ui.empty("open_text_file_header")
			ui.axis(.X)
			ui.size(.PCT_PARENT, 1, .TEXT, 1)
			if ui.menu_button("Open Text File").clicked {
				ui.queue_panel(panel, .Y, .FLOATING, file_browser, 1.0, ui.state.ctx.panel.quad)
			}
		ui.pop()
		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .MIN_SIBLINGS, 1)
		ui.empty("text_body")
		ui.size(.PCT_PARENT, 1, .PCT_PARENT, 1)
			ui.paragraph("main_text", &app.lorem)
			ui.pop()
		ui.pop()
	ui.end()
}

panel_tab_test :: proc() {
	ui.begin()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty("panel_switcher_icon")
		ui.axis(.X)
		ui.size(.TEXT, 1, .TEXT, 1)
		if ui.button("<#> p ").released {
			ui.queue_panel(ui.state.ctx.panel, .Y, .FLOATING, panel_pick_panel, 1.0, ui.state.ctx.panel.quad)
		}
	ui.pop()

	tab_names : []string = {"First", "Second", "Third"}
	
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .MIN_SIBLINGS, 1)
	ui.empty("etab_test")
		ui.axis(.X)
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		tabs, index := ui.tab("tab_test", tab_names)
		

		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .SUM_CHILDREN, 1)
		ui.empty("tab_test2")
		ui.size(.TEXT, 1, .TEXT, 1)
		ui.axis(.Y)
		if len(tabs) > 0 {
			switch index {
				case 0:
					ui.label("Pressed:")
					ui.value("pressed:", ui.state.boxes.pressed)
					ui.label("Locked")
					ui.value("locked:", ui.state.panels.locked)
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

		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		ui.label("Sokol Active Layer:")
		ui.value("active layer", ui.state.sokol.current_layer)
		ui.label("Window Size")
		ui.value("win size", ui.state.window.size)
		ui.label("font size")
		ui.value("font size", ui.state.font.size)
		ui.label("line space")
		ui.value("line space", ui.state.font.line_space)
		ui.label("offsety")
		ui.value("offsety", ui.state.font.offset_y)


	ui.pop()
	ui.end()
}

panel_boxlist :: proc() {
	ui.begin()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty("panel_switcher_icon")
		ui.axis(.X)
		ui.size(.TEXT, 1, .TEXT, 1)
		if ui.button("<#> p ").released {
			ui.queue_panel(ui.state.ctx.panel, .Y, .FLOATING, panel_pick_panel, 1.0, ui.state.ctx.panel.quad)
		}
	ui.pop()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .MIN_SIBLINGS, 1)
	ui.scrollbox("panel_boxlist")
	{
		ui.axis(.Y)
		ui.size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
		ui.empty("panel_list")
			ui.size(.TEXT, 1, .TEXT, 1)
			ui.label("Panel List:")
			index := 0
			for key, panel in ui.state.panels.all {
				if panel.box != nil {
					ui.axis(.Y)
					ui.size(.TEXT, 1, .TEXT, 1)
					ui.label(ui.concat("PANEL ID:", panel.uid, "###_", index))
					indent :f32= 0
					for first := panel.box; first != nil; first = first.first {
						indent += 1
						for next := first.next; next != nil; next = next.next {
							ui.axis(.Y)
							ui.size(.SUM_CHILDREN, 1, .TEXT, 1)
							ui.empty(ui.concat("row_holder", panel.uid, index))
								ui.spacer_pixels(ui.concat("row_spacer", index), 10*indent)
								ui.axis(.X)
								ui.size(.TEXT, 1, .TEXT, 1)
								ui.label(ui.concat(" <> ", ui.to_odin_string(&next.name), "###", index))
							ui.pop()
							index += 1
						}
						index += 1
					}
				}
				index += 1
			}
		ui.pop()
	}
	ui.pop()
	ui.end()
}



panel_properties :: proc() {
	ui.begin()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	ui.empty("panel_switcher_icon")
		ui.axis(.X)
		ui.size(.TEXT, 1, .TEXT, 1)
		if ui.button("<#> p ").released {
			ui.queue_panel(ui.state.ctx.panel, .Y, .FLOATING, panel_pick_panel, 1.0, ui.state.ctx.panel.quad)
		}
	ui.pop()
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	if ui.dropdown("State:").selected {
		ui.label_values("Current Frame", {ui.state.frame})
		ui.label_values("UID", {ui.state.uid})
		ui.label_values("Number of Panels", {ui.state.panels.pool.nodes_used})
		ui.label_values("Mouse Pos",  {ui.state.input.mouse.pos.x, ui.state.input.mouse.pos.y})
	}
	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .TEXT, 1)
	if ui.dropdown("Image").selected {
		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .MIN_SIBLINGS, 1)
		ui.image("myimage", &app.image)
	}


	ui.end()
}

panel_pick_panel :: proc() {
	panel := ui.begin()
	ui.axis(.Y)
	ui.size(.SUM_CHILDREN, 1, .TEXT, 1)
	ui.empty("pick_panel")
		ui.axis(.X)
		ui.size(.PIXELS, 250, .TEXT, 1)
		ui.drag_panel("sel_panel", "Select Panel:")
		ui.size(.TEXT, 1, .TEXT, 1)
		if ui.button("<#> x ").released {
			if ui.state.panels.floating != nil {
				ui.delete_panel(ui.state.panels.floating)
			}
		}
	ui.pop()

	ui.axis(.Y)
	ui.size(.PCT_PARENT, 1, .SUM_CHILDREN, 1)
	ui.empty("list_of_panels")
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
	ui.begin()
	ui.axis(.Y)
	ui.size(.PIXELS, 600, .SUM_CHILDREN, 1)
	ui.empty("file_browser_header")
		ui.axis(.X)
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		ui.empty("file_browser")
			ui.size(.MIN_SIBLINGS, 1, .TEXT, 1)
			ui.drag_panel("load_file", "Load file:")
			ui.size(.TEXT, 1, .TEXT, 1)
			if ui.button("<#> x ").released do ui.delete_panel(ui.state.panels.floating)
		ui.pop()
		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .TEXT, 1)
		ui.edit_text("file browser", &app.path)
		ui.size(.PCT_PARENT, 1, .TEXT, 12)
		ui.scrollbox("file_browser")
		ui.axis(.Y)
		ui.size(.PCT_PARENT, 1, .SUM_CHILDREN, 1)
		ui.empty("file_scroller")
			ui.axis(.Y)
			ui.size(.PCT_PARENT, 1, .TEXT, 1)
			find_files_and_run(ui.button, ".txt")
		ui.pop()
	ui.pop()
	ui.end()
}

find_files_and_run :: proc(run:proc(string) -> ui.Box_Ops, filter:string="") {
	using filepath
	if app.path.mem[app.path.len] == '\\' {
		app.path.mem[app.path.len] = 0
		app.path.len -= 1
	}
	path := ui.to_odin_string(&app.path)
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
				if run(ui.concat("<#>g<b> ", file.name)).released {
					ui.replace_string(&app.path, fmt.tprintf("%v%v%v", path[:len(path)], '\\', file.name))
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
						ui.state.boxes.editing = {}
						ui.delete_panel(ui.state.panels.floating)
					}
				}
			}
		}
	}
}
