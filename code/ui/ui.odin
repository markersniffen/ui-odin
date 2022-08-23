package ui

import "core:fmt"

// AXIS ------------------------------
X :: 0
Y :: 1
XY :: 2

Ui :: struct {
	panels: map[Uid]^Panel,
	panel_pool: Pool,
	panel_master: ^Panel,
	panel_active: ^Panel,

	boxes: map[string]^Box,
	box_pool: Pool,
	box_parent: ^Box,
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
	font_color: v4,
	bg_color: v4,
	border_color: v4,
	border: f32,
	size: [XY]UI_Size,
	direction: Direction,
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
}

Direction :: enum {
	HORIZONTAL,
	VERTICAL,
}

//______ INITIALIZATION ______ //
ui_init :: proc()
{
	ui_init_font()

	pool_init(&state.ui.panel_pool, size_of(Panel), MAX_PANELS, "Panels")

	// Setup panels ------------------------------
	state.ui.panel_master = ui_create_panel(nil, .VERTICAL, .FILE_MENU)
	sub_panel := ui_create_panel(state.ui.panel_master, .VERTICAL, .DEBUG, 0.5)
	ui_create_panel(sub_panel, .HORIZONTAL, .TEMP, 0.7)
	pool_init(&state.ui.box_pool, size_of(Box), MAX_BOXES, "Boxes")
}

//______ UI UPDATE ______//
ui_update :: proc()
{
	// temp input for testing ------------------------------ 
	if read_key(&state.keys.left) do state.debug.temp -= 1
	if read_key(&state.keys.right) do state.debug.temp += 1

	// TODO temp change panel type (not working)
	if state.ui.panel_active != nil {
		num := int(state.ui.panel_active.type)
		if state.mouse.scroll > 0 {
			num = clamp(num + 1, 1, 4)
			fmt.println(num)	
		}

		if state.mouse.scroll < 0 {
			num = clamp(num - 1, 1, 4)
			fmt.println(num)	
		}
		state.mouse.scroll = 0
		state.ui.panel_active.type = Panel_Type(num)
	}

	// fmt.println(">>>>", state.ui.panel_active.type)	
	// calculate panels, includes box-builder code ------------------------------
	ui_calc_panel(state.ui.panel_master, {0, 0, f32(state.window_size.x), f32(state.window_size.y)})

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
		root := panel.box
		if panel.child_a == nil {
			#partial switch panel.type {
				case .DEBUG: 		ui_panel_debug(panel)
				case .PANEL_LIST: 	ui_panel_panel_list(panel)
				case .TEMP: 		ui_panel_temp(panel)
				case .FILE_MENU:	ui_panel_file_menu(panel)
			}
		}
		iterate_boxes :: proc(box: ^Box) {
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
				if box.ops.hovering do push_quad_solid(box.ctx, state.ui.col.hot)
			}
			if .CLICKABLE in box.flags {
				if box.ops.clicked do push_quad_gradient_v(box.ctx, state.ui.col.active, state.ui.col.hot)
			}
			if .DRAWGRADIENT in box.flags {
				push_quad_gradient_v(box.ctx, {1,1,1,0.1}, {0,0,0,0})
			}

			if .DRAWTEXT in box.flags {
				draw_text(box.key, pt_offset_quad({0, -state.ui.font_offset_y}, box.ctx))
			}
			iterate_boxes(box.first)
			iterate_boxes(box.next)
		}
		iterate_boxes(panel.box)
	}
}

