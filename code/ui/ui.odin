package ui

import "core:fmt"

// AXIS ------------------------------
X :: 0
Y :: 1
XY :: 2

Ui :: struct {
	panels: map[Uid]^Panel,
	panel_pool: Pool,
	panel_root: ^Panel,
	panel_active: ^Panel,

	boxes: map[string]^Box,
	box_pool: Pool,
	box_parent: ^Box,
	box_active_building: ^Box,
	box_index: u64,

	frame: u64,

	col: Ui_Colors,

	ctx: UI_Context,

	// "GLOBAL" FONT INFO
	char_data: map[rune]Char_Data,
	font_size: f32,					// NOTE pixels tall
	font_offset_y: f32,
	margin: f32,
	line_space: f32,
}

UI_Context :: struct {
	panel: ^Panel,
	box_parent: ^Box,
	box: ^Box,
	box_hot: ^Box,
	box_active: ^Box,
	font_color: v4,
	bg_color: v4,
	border_color: v4,
	border: f32,
	text_align: Text_Align,
	size: [XY]UI_Size,
	// direction: Direction,
	axis: Axis,
}

Ui_Colors :: struct {
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

UI_Size :: struct {
	type: UI_Size_Type,
	value: f32,
	// strictness: ??
}

UI_Size_Type :: enum {
  NIL,
  PIXELS,
  TEXT_CONTENT,
  PERCENT_PARENT,
  CHILDREN_SUM,
  MIN_SIBLINGS,
  MAX_SIBLING,
}

Direction :: enum {
	HORIZONTAL,
	VERTICAL,
}

Axis :: enum {
	X,
	Y,
	XY,
}

//______ INITIALIZATION ______ //
ui_init :: proc() {
	ui_init_font()

	pool_init(&state.ui.panel_pool, size_of(Panel), MAX_PANELS, "Panels")

	// Setup panels ------------------------------
	state.ui.panel_root = ui_create_panel(nil, .VERTICAL, .FILE_MENU)
	sub_panel := ui_create_panel(state.ui.panel_root, .VERTICAL, .DEBUG, 0.5)
	ui_create_panel(sub_panel, .HORIZONTAL, .TEMP, 0.7)
	pool_init(&state.ui.box_pool, size_of(Box), MAX_BOXES, "Boxes")

	// SET DEFAULT COLORS ------------------------------
	state.ui.ctx.font_color = {1,1,1,1}
	state.ui.ctx.bg_color = state.ui.col.bg
	state.ui.ctx.border = 1 
	state.ui.ctx.font_color = state.ui.col.border
}

//______ UI UPDATE ______//
ui_update :: proc() {
	// temp input for testing ------------------------------ 
	if read_key(&state.keys.left) do state.debug.temp -= 1
	if read_key(&state.keys.right) do state.debug.temp += 1

	// calculate panels, includes box-builder code ------------------------------
	ui_calc_panel(state.ui.panel_root, {0, 0, f32(state.window_size.x), f32(state.window_size.y)})

   // prune nodes that aren't used ------------------------------
	for _, box in state.ui.boxes {
		if state.ui.frame > box.last_frame_touched {
			ui_delete_box(box)
		}
	}

	// calculate size of boxes ------------------------------
	ui_calc_boxes()

	// advance frame / reset box index for keys ------------------------------
	state.ui.frame += 1
	state.ui.box_index = 0

	// queue panels/boxes for rendering ------------------------------
	for _, panel in state.ui.panels {
		state.ui.ctx.panel = panel
		root_box := panel.box
		if panel.child_a == nil {
			#partial switch panel.type {
				case .DEBUG: 			ui_panel_debug()
				case .PANEL_LIST: 	ui_panel_panel_list()
				case .TEMP: 			ui_panel_temp()
				case .FILE_MENU:		ui_panel_file_edit_view()
			}
		}

		draw_boxes(root_box)
		draw_boxes(panel.menu_box)
	}
	// state.ui.ctx.box_hot = nil
}

draw_boxes :: proc(box: ^Box) {
	if box == nil do return
	if box.parent != nil {
		box.ctx.l = box.parent.ctx.l + box.offset.x
		box.ctx.t = box.parent.ctx.t + box.offset.y
		box.ctx.r = box.ctx.l + box.calc_size.x
		box.ctx.b = box.ctx.t + box.calc_size.y
	}

	if .DRAWBACKGROUND in box.flags {
		push_quad_gradient_v(box.ctx, state.ui.col.bg, state.ui.col.bg_light)
	}
	if .DRAWBORDER in box.flags {
		push_quad_border(box.ctx, state.ui.col.border, box.border)
	}

	if .HOVERABLE in box.flags {
		// if box.ops.hovering do push_quad_solid(box.ctx, state.ui.col.hot)
	}
	if .DRAWGRADIENT in box.flags {
		push_quad_gradient_v(box.ctx, {1,1,1,0.1}, {0,0,0,0})
	}
	if .CLICKABLE in box.flags {
		// if box.ops.pressed do push_quad_gradient_v(box.ctx, {1,1,1, clamp(1 * box.active_t, 0, 1)}, state.ui.col.hot)
	}

	if .DRAWTEXT in box.flags {
		draw_text(box.name, pt_offset_quad({0, -state.ui.font_offset_y}, box.ctx), box.text_align)
	}

	if .DISPLAYVALUE in box.flags {
		text := fmt.tprintf("%v %v", box.name, box.value)
		draw_text(text, pt_offset_quad({0, -state.ui.font_offset_y}, box.ctx), box.text_align)
	}

	if .HOTANIMATION in box.flags {
		push_quad_gradient_v(box.ctx, {1,1,1,0.4 * box.hot_t}, {1,1,1,0.2 * box.hot_t})
	}

	if .ACTIVEANIMATION in box.flags {
		push_quad_gradient_v(box.ctx, {1,0,0,0.4 * box.active_t}, {1,0,0,0.2 * box.active_t})	
	}

	if !(.MENU in box.flags) {
		draw_boxes(box.next)
	}
	draw_boxes(box.first)
}