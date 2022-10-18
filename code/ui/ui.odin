package ui

import tracy "../../../odin-tracy"

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
}

UI_Boxes :: struct {
	pool: Pool,
	all: map[Key]^Box,
	to_delete: [MAX_BOXES]rawptr,
	root: ^Box,
	active: ^Box,
	editing: ^Box,
	hot: ^Box,
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

	render_layer: int,
	axis: Axis,
	size: [XY]Box_Size,

	bg_color: HSL,
	border_color: HSL,
	font_color: HSL,
	border: f32,
	text_align: Text_Align,
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
	ui_init_font()
	
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
	tracy.Zone()
	set_cursor()
	cursor(.NULL)

	{
		tracy.ZoneN("Keyboard input")

		// keyboard input for text editing
		if state.ui.boxes.editing != nil {
			box := state.ui.boxes.editing 
			es :=state.ui.boxes.editing.editable_string

			// TYPE LETTERS
			if state.ui.last_char > 0 {
				if es.end-es.start != 0 {
					backspace(es)
				}
				if !(es.len+1 > LONG_STRING_LEN) {
					if es.start >= es.len {
						es.mem[es.len] = u8(state.ui.last_char)
					} else {
						copy(es.mem[clamp(es.start+1, 0, es.len):], es.mem[es.start:es.len])
						es.mem[es.start] = u8(state.ui.last_char)
					}
					es.start +=	1
					es.end = es.start
					es.len += 1
					state.ui.last_char = -1
				} else {
					fmt.println("MAX STRING LENGTH REACHED")
				}
			}

			// LEFT
			if read_key(&state.input.keys.left) {
				if shift() {
					if ctrl() {
						es.end = editable_jump_left(es)
					} else {
						es.end = clamp(es.end - 1, 0, es.len)
					}
				} else if ctrl() {
					es.start = editable_jump_left(es)
					es.end = es.start
				} else {
					es.start = clamp(es.start - 1, 0, LONG_STRING_LEN)
					es.end = es.start
				}
			}

			// RIGHT
			if read_key(&state.input.keys.right) {
				if shift() {
					if ctrl() {
						es.end = editable_jump_right(es)
					} else {
						es.end = clamp(es.end + 1, 0, es.len+1)
					}
				} else if ctrl() {
					es.start = editable_jump_right(es)
					es.end = es.start
				} else {
					es.start = clamp(es.start + 1, 0, es.len)
					es.end = es.start
				}
			}

			if es.len > 0 {
		 		// BACKSPACE
				if read_key(&state.input.keys.backspace) {
					if ctrl() {
						es.start = editable_jump_left(es)
					}
					backspace(es)
				}
				// DELETE
				if read_key(&state.input.keys.delete) {
					if ctrl() {
						es.end = editable_jump_right(es)
					}
					if es.start == es.end {
						if es.start != es.len {
							copy(es.mem[es.start:], es.mem[es.start+1:])
							es.len -= 1
						}
					} else if es.end > es.start {
						copy(es.mem[es.start:], es.mem[es.end:])
						es.len -= (es.end - es.start)
						es.end = es.start
					} else {
						copy(es.mem[es.end:], es.mem[es.start:])
						es.len -= (es.start - es.end)
						es.start = es.end
					}
				}

				// SELECT ALL
				if ctrl() && read_key(&state.input.keys.a) {
					es.start = 0
					es.end = es.len
				}

			}
			// HOME
			if read_key(&state.input.keys.home) {
				es.start = 0
				es.end = 0
			}

			if read_key(&state.input.keys.end) {
				es.start = es.len
				es.end = es.len
			}

			// ESCAPE
			if read_key(&state.input.keys.escape) {
				state.ui.boxes.editing.ops.editing = false
				state.ui.boxes.editing = nil
			}

			// MOUSE SELECTION
			quad := box.quad
			quad.r = quad.l
			quad.t = box.panel.quad.t
			quad.b = box.panel.quad.b
			if lmb_click_drag() {
				cursor(.TEXT)
				for i in 0..=es.len {
					if i < es.len {
						quad.r += state.ui.fonts.regular.char_data[rune(es.mem[i])].advance
					} else {
						quad.r = box.quad.r
					}
					if mouse_in_quad(quad) {
						if lmb_click() {
							es.start = i
							break
						} else {
							es.end = i
							break
						}
					}
					quad.l += state.ui.fonts.regular.char_data[rune(es.mem[i])].advance
				}
			}
			
			for letter, i in es.mem {
				if letter == 0 {
					assert(es.len == i, "Editable_Text len doesn't match number of characters.")
					break
				}
			}
		}

	}
	
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
	tracy.ZoneN("Build Boxes")
		// NOTE build boxes
		for _, panel in state.ui.panels.all {
			state.ui.ctx.panel = panel
			if panel.type == .NULL {
				push_quad_solid(panel.bar, state.ui.col.inactive, panel.quad)
			} else {
				panel.content()
				// build_panel_cntent(panel.content)
			}
		}
	}

	{
		tracy.ZoneN("Prune Boxes")
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
	panels : [MAX_PANELS]^Panel

	index:= 0
	for _, panel in state.ui.panels.all {
		panels[index] = panel
		index += 1
	}
	
	{
		tracy.ZoneN("CALC BOXES")
		for panel in panels {
			if panel != nil {
				if panel.box != nil do ui_calc_boxes(panel.box)
			}
		}
	}

	// advance frame / reset box index for keys ------------------------------
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
		tracy.ZoneN("DRAW BOXES")
		for _, panel in state.ui.panels.all {
			if panel.type != .FLOATING {
				tracy.ZoneN(fmt.tprintf("Draw %v", panel.content))
				ui_draw_boxes(panel.box, panel.quad)
			}
		}
 	}

 	{
	 	tracy.ZoneN("DRAW Floating Box")
		if state.ui.panels.floating != nil {
			if state.ui.panels.floating.box.first != nil {
				ui_draw_boxes(state.ui.panels.floating.box, state.ui.panels.floating.quad)
			}
		}
 	}

	state.ui.last_char = 0
}

ui_draw_boxes :: proc(box: ^Box, clip_to:Quad) {
	nme := "Draw Box..."
	if box != nil {
		nme = to_string(&box.name)
	}
	tracy.ZoneN(nme)
	if box == nil do return
	set_render_layer(box.render_layer)
	
	quad := box.quad
	clip_ok := true

	box.clip, clip_ok = quad_clamp_or_reject(box.quad, clip_to)

	// NOTE COLORS
	// if .ROOT in box.flags do push_quad_border(quad, state.ui.col.backdrop, 1)

	if clip_ok {
		if .DRAWBACKGROUND in box.flags {
			push_quad_solid(quad, box.bg_color, box.clip)
			if box.ops.selected {
				push_quad_gradient_v(quad, state.ui.col.active, state.ui.col.active, box.clip)
			}
		}
		if .DRAWBORDER in box.flags {
			push_quad_border(quad, state.ui.col.border, box.border, box.clip)
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
			if box.ops.editing {
				push_quad_gradient_v(quad, {0,0,0,0}, state.ui.col.gradient, box.clip)
			} else {
				push_quad_gradient_v(quad, state.ui.col.gradient, {0,0,0,0}, box.clip)
			}
		}
		if .DRAWTEXT in box.flags {
			draw_text(to_string(&box.name), pt_offset_quad({0, -state.ui.font_offset_y}, quad), box.text_align, box.font_color, box.clip)
		} else if .EDITTEXT in box.flags {
			if box.ops.editing do push_quad_border(quad, state.ui.col.active, box.border, box.clip)
			draw_editable_text(box.ops.editing, box.editable_string, pt_offset_quad({0, -state.ui.font_offset_y}, quad), box.text_align, box.font_color, box.clip)
		} else if .DRAWPARAGRAPH in box.flags {
			draw_text_multiline(box.value, quad, .LEFT, 2, box.clip)
		}
		if .DISPLAYVALUE in box.flags {
			text := fmt.tprintf("%v %v", to_string(&box.name), box.value)
			draw_text(text, pt_offset_quad({0, -state.ui.font_offset_y}, quad), box.text_align, box.font_color, box.clip)
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
	if .CLIP in box.flags do clip_quad = quad
	ui_draw_boxes(box.first,clip_quad)
}