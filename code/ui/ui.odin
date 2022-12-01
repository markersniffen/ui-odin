package ui

when PROFILER do import tracy "../../../odin-tracy"

import "core:fmt"
import "core:strconv"
import "core:mem"

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
	
	fonts: UI_Fonts,

	font_size: f32,			// NOTE pixels tall
	font_offset_y: f32,
	margin: f32,
	line_space: f32,
	last_char: rune,
}

UI_Panels :: struct {
	pool: Pool,
	all: map[Uid]^Panel,
	root: ^Panel,
	queued: Panel,
	queued_parent: ^Panel,
	floating: ^Panel,
	active: ^Panel,
	hot: ^Panel,
	locked: bool,
}

UI_Boxes :: struct {
	pool: Pool,
	all: map[Key]^Box,
	to_delete: [MAX_BOXES]rawptr,
	root: ^Box,
	active: ^Box,
	hot: ^Box,
	editing: Key,
	index: int,
}

UI_Fonts :: struct {
	regular: Font,
	bold: Font,
	italic: Font,
	light: Font,
	icons: Font,
}

UI_Context :: struct {
	panel: ^Panel,

	box: ^Box,
	parent: ^Box,

	editable_string: String,

	axis: Axis,
	size: [XY]Box_Size,

	bg_color: HSL,
	border_color: HSL,
	font_color: HSL,
	border: f32,
	text_align: Text_Align,
	flags: bit_set[Box_Flags],
}

HSL :: struct {
	h:f32,
	s:f32,
	l:f32,
	a:f32,
}

UI_Colors :: struct {
	backdrop: HSL,
	bg: HSL,
	gradient: HSL,
	border: HSL,
	highlight: HSL,
	accent: HSL,
	hot: HSL,
	inactive: HSL,
	font: HSL,
	active: HSL,	
}

Axis :: enum {
	X,
	Y,
}

//______ INITIALIZATION ______ //
ui_init :: proc() {
	state.ui.col.backdrop 	= {0.0,   0.0,  .05,   1.0}
	state.ui.col.bg 		= {0.56,   0.0,  0.1,   1.0}
	state.ui.col.gradient	= {0.56,  0.55, .74,   0.2}
	state.ui.col.border 	= {0.56,  0.0,  0.0,   1.0}
	state.ui.col.font 		= {0.56,  1.0,  1.0,   1.0}
	state.ui.col.hot 		= {0.56,  .35,  0.28,  1.0}
	state.ui.col.inactive   = {0.56,  .67,  0.34,  1.0}
	state.ui.col.active 	= {0.56,  1,    0.41,  1.0}
	state.ui.col.highlight 	= {0.56,  1,    0.17,  1.0}
	
	state.ui.line_space = 20

	pool_init(&state.ui.panels.pool, size_of(Panel), MAX_PANELS, "Panels")
	pool_init(&state.ui.boxes.pool, size_of(Box), MAX_BOXES, "Boxes")
	
	// SET DEFAULT COLORS ------------------------------
	state.ui.ctx.font_color = { 1, 1, 1, 1 }
	state.ui.ctx.bg_color = state.ui.col.bg
	state.ui.ctx.border = 1
	state.ui.ctx.font_color = state.ui.col.border
}

//______ UI UPDATE ______//
ui_update :: proc() {
	when PROFILER do tracy.Zone()
	
	// create queued panel
	if state.ui.panels.queued != {} {
		q := state.ui.panels.queued
		ui_create_panel(state.ui.panels.queued_parent, q.axis, q.type, q.content, q.size, q.quad)
		state.ui.panels.queued = {}
	}

	ui_calc_panel(state.ui.panels.root, state.window.quad)
	if state.ui.panels.floating != nil {
		ui_calc_panel(state.ui.panels.floating, state.ui.panels.floating.quad)
	}
	
	{
	when PROFILER do tracy.ZoneN("Build Boxes")
		// NOTE build boxes
		for _, panel in state.ui.panels.all {
			state.ui.ctx.panel = panel
			if panel.type == .NULL {
				push_quad_solid(panel.bar, state.ui.col.inactive, panel.quad)
			} else {
				panel.content()
			}
		}
	}

	{
		when PROFILER do tracy.ZoneN("PRUNE BOXES")
	  	// prune boxes that aren't used ------------------------------
		box_index := 0
		for _, box in state.ui.boxes.all {
			if state.ui.frame > box.last_frame_touched {
				if box.key.len == 0 {
					assert(0 != 0)
				}
				state.ui.boxes.to_delete[box_index] = box
				box_index += 1
			}
		}

		if box_index > 0 {
			for i in 0..<box_index {
				box := cast(^Box)state.ui.boxes.to_delete[i]
				ui_delete_box(box)
				state.ui.boxes.to_delete[i] = nil
			}
		}
	}

	// TODO move this? check if .editing points to a real box, if not, delete it
	if state.ui.boxes.editing != {} {
		ebox, eok := state.ui.boxes.all[state.ui.boxes.editing]
		if !eok do state.ui.boxes.editing = {}
	}

	// CALC BOXES ------------------------------------------------	
	panels : [MAX_PANELS]^Panel
	index:= 0
	for _, panel in state.ui.panels.all {
		panels[index] = panel
		index += 1
	}
	
	{
		when PROFILER do tracy.ZoneN("CALC BOXES")
		for panel in panels {
			if panel != nil {
				if panel.box != nil do ui_calc_boxes(panel.box)
			}
		}
	}

	// advance frame / reset box index for keys -----------------------------
	state.ui.frame += 1

	// queue panels/boxes for rendering ------------------------------
	if state.ui.panels.hot != nil {
		if state.ui.panels.hot.type == .NULL {
			if state.ui.panels.hot.child_a != nil {
				if state.ui.panels.hot.child_a.type != .STATIC {
					push_quad_solid(state.ui.panels.hot.bar, state.ui.col.hot, state.ui.panels.hot.quad)
				}
			}
		}
	}

	if state.ui.panels.active != nil {
		if state.ui.panels.active.type == .NULL {
			push_quad_solid(state.ui.panels.active.bar, state.ui.col.active, state.ui.panels.active.quad)
		}
	}

 	{
		when PROFILER do tracy.ZoneN("DRAW BOXES")
		for _, panel in state.ui.panels.all {
			if panel.type != .FLOATING {
				when PROFILER do tracy.ZoneN(fmt.tprint("Draw", panel.content))
				ui_draw_boxes(panel.box, panel.quad)
			}
		}
 	}

 	{
	 	when PROFILER do tracy.ZoneN("DRAW Floating Box")
		if state.ui.panels.floating != nil {
			if state.ui.panels.floating.box.first != nil {
				push_quad_gradient_v(state.ui.panels.root.quad, {0,0,0,0.4},{0,0,0,0.2}, state.ui.panels.root.quad)
				ui_draw_boxes(state.ui.panels.floating.box, state.ui.panels.floating.quad)
			}
		}
 	}

	state.ui.last_char = 0
}

// recursive draw boxes
ui_draw_boxes :: proc(box: ^Box, clip_to:Quad) {
	if box == nil do return
	
	quad := box.quad
	clip_ok := true

	box.clip, clip_ok = quad_clamp_or_reject(box.quad, clip_to)

	// NOTE COLORS
	// if .ROOT in box.flags do push_quad_border(quad, state.ui.col.backdrop, 1)

	if clip_ok {
		// NOTE editing-check
		
		is_editing := box.ops.editing // (box.key == state.ui.boxes.editing)
		value := "NO VALUE"
		if box.value != nil do value = fmt.tprint(box.value)

		if .DRAWBACKGROUND in box.flags {
			push_quad_solid(quad, box.bg_color, box.clip)
			if box.ops.selected {
				push_quad_gradient_v(quad, state.ui.col.active, state.ui.col.active, box.clip)
			} 
		}
		if .DRAWBORDER in box.flags {
			push_quad_border(quad, box.border_color, box.border, box.clip)
		}
		if .HOTANIMATION in box.flags {
			hot := state.ui.col.hot
			push_quad_gradient_v(quad, {hot.h, hot.s, hot.l, hot.a * box.hot_t}, {hot.h, hot.s, hot.l, hot.a * box.hot_t}, box.clip)
		}
		if .ACTIVEANIMATION in box.flags {
			active := state.ui.col.active
			push_quad_gradient_v(quad, {active.h, active.s, active.l, active.a * box.active_t}, {active.h, active.s, active.l, active.a * box.active_t}, box.clip)	
		}
		if .DRAWGRADIENT in box.flags {
			if is_editing {
				push_quad_gradient_v(quad, {0,0,0,0}, state.ui.col.gradient, box.clip)
			} else {
				push_quad_gradient_v(quad, state.ui.col.gradient, {0,0,0,0}, box.clip)
			}
		}
		if .DRAWTEXT in box.flags {
			draw_text(to_string(&box.name), pt_offset_quad({0, -state.ui.font_offset_y}, quad), box.text_align, box.font_color, box.clip)
		} else if .EDITTEXT in box.flags {
			if is_editing do push_quad_border(box.parent.quad, state.ui.col.active, box.border, box.parent.quad)
			draw_editable_text(is_editing, box.editable_string, pt_offset_quad({0, -state.ui.font_offset_y}, quad), box.text_align, box.font_color, box.clip)
		} else if .EDITVALUE in box.flags {
			if is_editing {
				push_quad_border(box.parent.quad, state.ui.col.active, box.border, box.parent.quad)
				if box.editable_string != nil {
					draw_editable_text(is_editing, box.editable_string, pt_offset_quad({0, -state.ui.font_offset_y}, quad), box.text_align, box.font_color, box.clip)
				}
			} else {
				draw_text(value, pt_offset_quad({0, -state.ui.font_offset_y}, quad), box.text_align, box.font_color, box.clip)
			}
		} else if .DRAWPARAGRAPH in box.flags {
			if box.value != nil do draw_text_multiline(box.value, quad, .LEFT, 2, box.clip)
		}
		if .DISPLAYVALUE in box.flags {
			draw_text(value, pt_offset_quad({0, -state.ui.font_offset_y}, quad), box.text_align, box.font_color, box.clip)
		}

		// TODO DEBUG
		if .DEBUG in box.flags {
			push_quad_border(quad, {0.85,1,0.5,1}, 1, box.clip)
		}
		if .DEBUGCLIP in box.flags {
			push_quad_border(box.clip, {0.23,1,0.5,1}, 1, box.clip)
		}

	}

	ui_draw_boxes(box.next, clip_to)

	clip_quad := clip_to
	if .CLIP in box.flags {
		clip_quad = quad
	}
	ui_draw_boxes(box.first, clip_quad)
}