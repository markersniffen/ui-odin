package main	

// import "/demo"
import "/ui"
import "core:fmt"

state : ^ui.State

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

	state.debug.path = from_string("Test Text Goes Here That Is A Really Long Line Of Text My Man")
	//					parent			 	   direction	type			content						size
	ui_create_panel(nil, 					.Y,			.STATIC, 	ui_panel_file_menu, 		0.3)
	ui_create_panel(state.ui.ctx.panel, .Y,			.DYNAMIC, 	ui_panel_colors, 			0.1)
	ui_create_panel(state.ui.ctx.panel, .X,			.DYNAMIC, 	ui_panel_properties, 					0.8)
	ui_create_panel(state.ui.ctx.panel, .Y,			.DYNAMIC, 	ui_lorem, 	0.3)
}

frame :: proc() {
}