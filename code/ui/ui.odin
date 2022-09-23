package ui

import "core:fmt"

// AXIS ------------------------------
X  :: 0
Y  :: 1
XY :: 2

Ui :: struct {
	frame: u64,
	panels: UI_Panels,
	boxes: UI_Boxes,

	col: UI_Colors,
	ctx: UI_Context,

	font: Font,
	icons: Font,
	// char_data: map[rune]Char_Data,
	
	font_size: f32,					// NOTE pixels tall
	font_offset_y: f32,
	margin: f32,
	line_space: f32,
}

UI_Panels :: struct {
	pool: Pool,
	all: map[Uid]^Panel,
	root: ^Panel,
	floating: ^Panel,
	active: ^Panel,
	hot: ^Panel,
}

UI_Boxes :: struct {
	pool: Pool,
	all: map[Key]^Box,
	to_delete: [MAX_BOXES]rawptr,
	root: ^Box,
	active: ^Box,
	hot: ^Box,
	index: int,
}

UI_Context :: struct {
	panel: ^Panel,

	box: ^Box,
	parent: ^Box,

	render_layer: int,
	axis: Axis,
	size: [XY]Box_Size,

	font_color: v4,
	bg_color: v4,
	border_color: v4,
	border: f32,
	text_align: Text_Align,
}

UI_Colors :: struct {
	base: v4,
	bg: v4,
	bg_light: v4,
	border: v4,
	border_light: v4,
	font: v4,
	font_hot: v4,
	hot: v4,
	active: v4,	
	highlight: v4,
}

Axis :: enum {
	X,
	Y,
	XY,
}

//______ INITIALIZATION ______ //
ui_init :: proc() {
	ui_init_font()
	
	pool_init(&state.ui.panels.pool, size_of(Panel), MAX_PANELS, "Panels")
	pool_init(&state.ui.boxes.pool, size_of(Box), MAX_BOXES, "Boxes")

	ui_create_panel(.Y, .STATIC, .FILE_MENU, 0.3)
	ui_create_panel(.Y, .DYNAMIC, .TESTLIST, 0.1)
	ui_create_panel(.X, .DYNAMIC, .DEBUG, 0.5)
	ui_create_panel(.Y, .DYNAMIC, .PROPERTIES, 0.3)

	// SET DEFAULT COLORS ------------------------------
	state.ui.ctx.font_color = {1,1,1,1}
	state.ui.ctx.bg_color = state.ui.col.bg
	state.ui.ctx.border = 1 
	state.ui.ctx.font_color = state.ui.col.border
}

//______ UI UPDATE ______//
ui_update :: proc() {
	ui_calc_panel(state.ui.panels.root, state.window.quad)
	ui_calc_panel(state.ui.panels.floating, state.ui.panels.floating.quad)

	// NOTE build boxes
	for _, panel in state.ui.panels.all {
		state.ui.ctx.panel = panel
		if panel.type == .NULL {
			// push_quad_solid(panel.bar, {0.3,0.3,0.3,1})
		} else {
			build_panel_content(panel.content)
		}
	}

  // prune boxes that aren't used ------------------------------
	box_index := 0
	for _, box in state.ui.boxes.all {
		if state.ui.frame > box.last_frame_touched {
			if box.key.len == 0 {
				assert(0 != 0)
			} 
			// fmt.println("!!! Deleting !!!", box.name)
			state.ui.boxes.to_delete[box_index] = box
			box_index += 1
		}
	}
	if box_index > 0 {
		for i in 0..<box_index {
				box := cast(^Box)state.ui.boxes.to_delete[i]
				// fmt.println("About to prune box:")
				ui_delete_box(box)
				state.ui.boxes.to_delete[i] = nil
		}
	}
	
	// calculate size/position of boxes ------------------------------
	for _, panel in state.ui.panels.all {
		if panel.box != nil do ui_calc_boxes(panel.box)
	}

	// advance frame / reset box index for keys ------------------------------
	state.ui.frame += 1

	// queue panels/boxes for rendering ------------------------------
	if state.ui.panels.hot != nil {
		if state.ui.panels.hot.type == .NULL {
			if state.ui.panels.hot.child_a != nil {
				if state.ui.panels.hot.child_a.type != .STATIC {
					push_quad_solid(state.ui.panels.hot.bar, state.ui.col.hot)		
				}
			}
		}
	}

	if state.ui.panels.active != nil {
		if state.ui.panels.active.type == .NULL {
			push_quad_solid(state.ui.panels.active.bar, state.ui.col.active)		
		} else if state.ui.panels.active.type == .FLOATING {
			// push_quad_solid(state.ui.panels.active.quad, {1,0,1,1})
		} else {
			// push_quad_solid(state.ui.panels.active.quad, {1,0,0,1})
		}
	}

	for _, panel in state.ui.panels.all {
		if panel.type != .FLOATING {
			ui_draw_boxes(panel.box)
		}
	}

	if state.ui.panels.floating != nil {
		if state.ui.panels.floating.box.first != nil {
			ui_draw_boxes(state.ui.panels.floating.box)
		}
		// fmt.println("drawing the floater")
	}
}

ui_draw_boxes :: proc(box: ^Box, clip_to:Quad={0,0,0,0}) {
	if box == nil do return
	set_render_layer(box.render_layer)
	
	quad := box.quad
	clip_ok := true

	if .ROOT in box.flags {
		// push_quad_solid(quad, {0,0,0,1})
		push_quad_border(quad, {0.1,0.1,0.1,1}, 1)
	}
	
	if clip_to != {0,0,0,0} {
		quad, clip_ok = quad_clamp_or_reject(box.quad, clip_to)
	} 
	// if box.parent != nil {
		// else if .CLIP in box.parent.flags {
		// 	quad, clip_ok = quad_clamp_or_reject(box.quad, box.parent.quad)
		// }
	// }

	if clip_ok {
		if .DRAWBACKGROUND in box.flags {
			push_quad_gradient_v(quad, box.bg_color, box.bg_color)
		}
		if .DRAWBORDER in box.flags {
			push_quad_border(quad, state.ui.col.border, box.border)
		}
		if .HOVERABLE in box.flags {
			// if box.ops.hovering do push_quad_solid(quad, state.ui.col.hot)
		}
		if .DRAWGRADIENT in box.flags {
			push_quad_gradient_v(quad, {1,1,1,0.1}, {0,0,0,0})
		}
		if .CLICKABLE in box.flags {
			// if box.ops.pressed do push_quad_gradient_v(quad, {1,1,1, clamp(1 * box.active_t, 0, 1)}, state.ui.col.hot)
		}
		if .DRAWTEXT in box.flags {
			draw_text(short_to_string(&box.name), pt_offset_quad({0, -state.ui.font_offset_y}, quad), box.text_align)
		}
		if .DISPLAYVALUE in box.flags {
			text := fmt.tprintf("%v %v", short_to_string(&box.name), box.value)
			draw_text(text, pt_offset_quad({0, -state.ui.font_offset_y}, quad), box.text_align)
		}
		if .HOTANIMATION in box.flags {
			push_quad_gradient_v(quad, {1,1,1,0.4 * box.hot_t}, {1,1,1,0.2 * box.hot_t})
		}
		if .ACTIVEANIMATION in box.flags {
			push_quad_gradient_v(quad, {1,0,0,0.4 * box.active_t}, {0.5,0,0,0.2 * box.active_t})	
		}
		if .DEBUG in box.flags {
			push_quad_border(quad, {1,0,1,1}, 1)
			// draw_text(box.name, pt_offset_quad({0, -state.ui.font_offset_y}, quad), box.text_align, {1,0,1,1})
		}
	}

	clip_quad := clip_to
	if .CLIP in box.flags && clip_to == {0,0,0,0} do clip_quad = box.quad

	ui_draw_boxes(box.next, clip_quad)
	if clip_ok do ui_draw_boxes(box.first, clip_quad)
}