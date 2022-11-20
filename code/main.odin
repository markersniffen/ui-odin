package main	

// import "/demo"
import "/ui"

state : ^ui.State

/*

// GLFW METHOD

init()
 - ui_init()
	 - sets colors
	 - create memory pools
 - glfw_init()
	 - creates window
	 - sets callbacks for input
 - ui_render_init()
 	 - opengl_init()
	 	 - set's font stuff???

update()
 - time stuff
 - ui_update()
 - glfw_update()
	 - poll events
	 - gets input state
 - ui_render()


// SOKOL METHOD

	init()
	
*/


main :: proc() {
	using ui

	ok := false
	state, ok = ui.init()

	if ok
	{
		//					parent			 	   direction	type			content						size
		ui_create_panel(nil, 					.Y,			.STATIC, 	ui_panel_file_menu, 		0.3)
		ui_create_panel(state.ui.ctx.panel, .Y,			.DYNAMIC, 	ui_panel_colors, 			0.1)
		ui_create_panel(state.ui.ctx.panel, .X,			.DYNAMIC, 	ui_lorem, 					0.5)
		// ui_create_panel(state.ui.ctx.panel, .Y,			.DYNAMIC, 	ui_panel_tab_test, 	0.3)
	}

}

// mainx :: proc() {
// 	using ui
// 	using demo
	
// 	ok := false	
// 	state, ok = init()

// 	if ok
// 	{
// 		//					parent			 	   direction	type			content						size
// 		ui_create_panel(nil, 					.Y,			.STATIC, 	ui_panel_file_menu, 		0.3)
// 		ui_create_panel(state.ui.ctx.panel, .Y,			.DYNAMIC, 	ui_panel_colors, 			0.1)
// 		ui_create_panel(state.ui.ctx.panel, .X,			.DYNAMIC, 	ui_lorem, 					0.5)
// 		ui_create_panel(state.ui.ctx.panel, .Y,			.DYNAMIC, 	ui_panel_tab_test, 	0.3)

// 		for !state.quit
// 		{
// 			update()

// 			if rmb_click() {
// 				if state.ui.panels.hot.type != .NULL {
// 					ui_queue_panel(state.ui.panels.hot, .Y, .FLOATING, ui_ctx_panel, 1.0, state.ui.ctx.panel.quad)
// 				}
// 			}
// 		}
// 	}

// 	quit()
// }
