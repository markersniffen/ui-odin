package main	

// import "/demo"
import "/ui"

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
	//					parent			 	   direction	type			content						size
	ui_create_panel(nil, 					.Y,			.STATIC, 	ui_panel_file_menu, 		0.3)
	ui_create_panel(state.ui.ctx.panel, .Y,			.DYNAMIC, 	ui_panel_colors, 			0.1)
	ui_create_panel(state.ui.ctx.panel, .X,			.DYNAMIC, 	ui_lorem, 					0.5)
	ui_create_panel(state.ui.ctx.panel, .Y,			.DYNAMIC, 	ui_panel_tab_test, 	0.3)
}

frame :: proc() {
	
}