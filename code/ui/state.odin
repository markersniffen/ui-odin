package ui

PROFILER :: false

when PROFILER do import tracy "../../../odin-tracy"
import sapp "../../../sokol-odin/sokol/app"

import "core:fmt"

when ODIN_OS == .Windows { import win "core:sys/windows" }

Uid :: u64

v2 :: [2]f32
v3 :: [3]f32
v4 :: [4]f32

v2i :: [2]i32
v3i :: [3]i32
v4i :: [4]i32

state : ^State

State :: struct {
	init:		proc(),
	loop:		proc(),

	frame: 	u64,
	uid: 		Uid,
	
	sokol:	Sokol,
	window: 	Window,
	input: 	Input,
	
	font: 	UI_Font,
	panels: 	UI_Panels,
	boxes: 	UI_Boxes,
	col: 		UI_Colors,
	ctx: 		UI_Context,
}

UI_Font :: struct {
	fonts: UI_Fonts,
	size: f32,			// NOTE pixels tall
	offset_y: f32,
	margin: f32,
	line_space: f32,
	last_char: rune,
}

Input :: struct {
	mouse: Mouse,
	keys: Keys,
}

Mouse :: struct {
	pos: v2,
	delta: v2,
	delta_temp: v2,
	left: Button,
	right: Button,
	middle: Button,
	scroll: v2,
}

Button :: enum { 
	UP,
	CLICK,
	RELEASE,
	DRAG,
}

Keys :: struct {
	left: bool,
	right: bool,
	up: bool,
	down: bool,

	escape: bool,
	tab: bool,
	enter: bool,
	space: bool,
	backspace: bool,
	delete: bool,
	home: bool,
	end: bool,

	n_enter: bool,
	n_plus: bool,
	n_minus: bool,

	ctrl: bool,
	alt: bool,
	shift: bool,

	a: bool,
	c: bool,
	x: bool,
	v: bool,
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

	axis: UI_Axis,
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


UI_Axis :: enum {
	X,
	Y,
}

X  :: 0
Y  :: 1
XY :: 2

init :: proc(init: proc() = nil, loop: proc() = nil, title:string="My App", width:i32=1280, height:i32=720) {
	state = new(State)
	state.init = init
	state.loop = loop
	state.window.title = title
	state.window.size = {width, height}

	state.col.backdrop 	= {0.0,   0.0,  .05,   1.0}
	state.col.bg 		= {0.56,   0.0,  0.1,   1.0}
	state.col.gradient	= {0.56,  0.55, .74,   0.2}
	state.col.border 	= {0.56,  0.0,  0.0,   1.0}
	state.col.font 		= {0.56,  1.0,  1.0,   1.0}
	state.col.hot 		= {0.56,  .35,  0.28,  1.0}
	state.col.inactive   = {0.56,  .67,  0.34,  1.0}
	state.col.active 	= {0.56,  1,    0.41,  1.0}
	state.col.highlight 	= {0.56,  1,    0.17,  1.0}
	
	state.font.line_space = 20

	pool_init(&state.panels.pool, size_of(Panel), MAX_PANELS, "Panels")
	pool_init(&state.boxes.pool, size_of(Box), MAX_BOXES, "Boxes")
	
	// SET DEFAULT COLORS ------------------------------
	state.ctx.font_color = { 1, 1, 1, 1 }
	state.ctx.bg_color = state.col.bg
	state.ctx.border = 1
	state.ctx.font_color = state.col.border

	sokol()
}


//______ UI UPDATE ______//
update :: proc() {
	when PROFILER do tracy.Zone()
	
	// create queued panel
	if state.panels.queued != {} {
		q := state.panels.queued
		create_panel(state.panels.queued_parent, q.axis, q.type, q.content, q.size, q.quad)
		state.panels.queued = {}
	}

	cursor(.ARROW)
	
	calc_panel(state.panels.root, state.window.quad)
	if state.panels.floating != nil {
		calc_panel(state.panels.floating, state.panels.floating.quad)
	}
	
	{
	when PROFILER do tracy.ZoneN("Build Boxes")
		// NOTE build boxes
		for _, panel in state.panels.all {
			state.ctx.panel = panel
			if panel.type == .NULL {
				push_quad_solid(panel.bar, state.col.inactive, panel.quad)
			} else {
				panel.content()
			}
		}
	}

	{
		when PROFILER do tracy.ZoneN("PRUNE BOXES")
	  	// prune boxes that aren't used ------------------------------
		box_index := 0
		for _, box in state.boxes.all {
			if state.frame > box.last_frame_touched {
				if box.key.len == 0 {
					assert(0 != 0)
				}
				state.boxes.to_delete[box_index] = box
				box_index += 1
			}
		}

		if box_index > 0 {
			for i in 0..<box_index {
				box := cast(^Box)state.boxes.to_delete[i]
				delete_box(box)
				state.boxes.to_delete[i] = nil
			}
		}
	}

	// TODO move this? check if .editing points to a real box, if not, delete it
	if state.boxes.editing != {} {
		ebox, eok := state.boxes.all[state.boxes.editing]
		if !eok do state.boxes.editing = {}
	}

	// CALC BOXES ------------------------------------------------	
	panels : [MAX_PANELS]^Panel
	index:= 0
	for _, panel in state.panels.all {
		panels[index] = panel
		index += 1
	}
	
	{
		when PROFILER do tracy.ZoneN("CALC BOXES")
		for panel in panels {
			if panel != nil {
				if panel.box != nil do calc_boxes(panel.box)
			}
		}
	}

	// advance frame / reset box index for keys -----------------------------
	state.frame += 1

	// queue panels/boxes for rendering ------------------------------
	if state.panels.hot != nil {
		if state.panels.hot.type == .NULL {
			if state.panels.hot.child_a != nil {
				if state.panels.hot.child_a.type != .STATIC {
					push_quad_solid(state.panels.hot.bar, state.col.hot, state.panels.hot.quad)
				}
			}
		}
	}

	if state.panels.active != nil {
		if state.panels.active.type == .NULL {
			push_quad_solid(state.panels.active.bar, state.col.active, state.panels.active.quad)
		}
	}

 	{
		when PROFILER do tracy.ZoneN("DRAW BOXES")
		for _, panel in state.panels.all {
			if panel.type != .FLOATING {
				when PROFILER do tracy.ZoneN(fmt.tprint("Draw", panel.content))
				draw_boxes(panel.box, panel.quad)
			}
		}
 	}

 	{
	 	when PROFILER do tracy.ZoneN("DRAW Floating Box")
		if state.panels.floating != nil {
			if state.panels.floating.box.first != nil {
				push_quad_gradient_v(state.panels.root.quad, {0,0,0,0.4},{0,0,0,0.2}, state.panels.root.quad)
				draw_boxes(state.panels.floating.box, state.panels.floating.quad)
			}
		}
 	}

	state.font.last_char = 0
}

// recursive draw boxes
draw_boxes :: proc(box: ^Box, clip_to:Quad) {
	if box == nil do return
	
	quad := box.quad
	clip_ok := true

	box.clip, clip_ok = quad_clamp_or_reject(box.quad, clip_to)

	// NOTE COLORS
	// if .ROOT in box.flags do push_quad_border(quad, state.col.backdrop, 1)

	if clip_ok {
		// NOTE editing-check
		
		is_editing := box.ops.editing // (box.key == state.boxes.editing)
		value := "NO VALUE"
		if box.value != nil do value = fmt.tprint(box.value)

		if .DRAWBACKGROUND in box.flags {
			push_quad_solid(quad, box.bg_color, box.clip)
			if box.ops.selected {
				push_quad_gradient_v(quad, state.col.active, state.col.active, box.clip)
			} 
		}
		if .DRAWBORDER in box.flags {
			push_quad_border(quad, box.border_color, box.border, box.clip)
		}
		if .HOTANIMATION in box.flags {
			hot := state.col.hot
			push_quad_gradient_v(quad, {hot.h, hot.s, hot.l, hot.a * box.hot_t}, {hot.h, hot.s, hot.l, hot.a * box.hot_t}, box.clip)
		}
		if .ACTIVEANIMATION in box.flags {
			active := state.col.active
			push_quad_gradient_v(quad, {active.h, active.s, active.l, active.a * box.active_t}, {active.h, active.s, active.l, active.a * box.active_t}, box.clip)	
		}
		if .DRAWGRADIENT in box.flags {
			if is_editing {
				push_quad_gradient_v(quad, {0,0,0,0}, state.col.gradient, box.clip)
			} else {
				push_quad_gradient_v(quad, state.col.gradient, {0,0,0,0}, box.clip)
			}
		}
		if .DRAWTEXT in box.flags {
			draw_text(to_odin_string(&box.name), pt_offset_quad({0, -state.font.offset_y}, quad), box.text_align, box.font_color, box.clip)
		} else if .EDITTEXT in box.flags {
			if is_editing do push_quad_border(box.parent.quad, state.col.active, box.border, box.parent.quad)
			draw_editable_text(is_editing, box.editable_string, pt_offset_quad({0, -state.font.offset_y}, quad), box.text_align, box.font_color, box.clip)
		} else if .EDITVALUE in box.flags {
			if is_editing {
				push_quad_border(box.parent.quad, state.col.active, box.border, box.parent.quad)
				if box.editable_string != nil {
					draw_editable_text(is_editing, box.editable_string, pt_offset_quad({0, -state.font.offset_y}, quad), box.text_align, box.font_color, box.clip)
				}
			} else {
				draw_text(value, pt_offset_quad({0, -state.font.offset_y}, quad), box.text_align, box.font_color, box.clip)
			}
		} else if .DRAWPARAGRAPH in box.flags {
			// TODO implement this without a Documentc struct?
			if box.editable_string != nil do draw_text_multiline(box.editable_string, quad, .LEFT, 2, box.clip)
		}
		if .DISPLAYVALUE in box.flags {
			draw_text(value, pt_offset_quad({0, -state.font.offset_y}, quad), box.text_align, box.font_color, box.clip)
		}

		// TODO DEBUG
		if .DEBUG in box.flags {
			push_quad_border(quad, {0.85,1,0.5,1}, 1, box.clip)
		}
		if .DEBUGCLIP in box.flags {
			push_quad_border(box.clip, {0.23,1,0.5,1}, 1, box.clip)
		}

	}

	draw_boxes(box.next, clip_to)

	clip_quad := clip_to
	if .CLIP in box.flags {
		clip_quad = quad
	}
	draw_boxes(box.first, clip_quad)
}

quit :: proc() {
	sapp.quit()
}

read_key :: proc(key: ^bool) -> bool {
	if key^ {
		key^ = false
		return true
	} else {
		return false
	}
}

enter :: proc() -> bool { return state.input.keys.enter }
esc :: proc() -> bool { return state.input.keys.escape }
shift :: proc() -> bool { return state.input.keys.shift }
alt :: proc() -> bool { return state.input.keys.alt }
ctrl :: proc() -> bool { return state.input.keys.ctrl }

mouse_button :: proc(button: Button, type: Button) -> bool { return (button == type) }

lmb_click :: proc() -> bool { return mouse_button(state.input.mouse.left, .CLICK) }
lmb_drag :: proc() -> bool { return mouse_button(state.input.mouse.left, .DRAG) }
lmb_click_drag :: proc() -> bool { return lmb_click() || lmb_drag() }
lmb_release :: proc() -> bool { return mouse_button(state.input.mouse.left, .RELEASE) }
lmb_release_up :: proc() -> bool { return (mouse_button(state.input.mouse.left, .RELEASE) || mouse_button(state.input.mouse.left, .UP)) }
lmb_up :: proc() -> bool { return mouse_button(state.input.mouse.left, .UP) }

rmb_click :: proc() -> bool { return mouse_button(state.input.mouse.right, .CLICK) }
rmb_drag :: proc() -> bool { return mouse_button(state.input.mouse.right, .DRAG) }
rmb_click_drag :: proc() -> bool { return rmb_click() || rmb_drag() }
rmb_release :: proc() -> bool { return mouse_button(state.input.mouse.right, .RELEASE) }
rmb_release_up :: proc() -> bool { return (mouse_button(state.input.mouse.right, .RELEASE) || mouse_button(state.input.mouse.right, .UP)) }
rmb_up :: proc() -> bool { return mouse_button(state.input.mouse.right, .UP) }

mmb_click :: proc() -> bool { return mouse_button(state.input.mouse.middle, .CLICK) }
mmb_drag :: proc() -> bool { return mouse_button(state.input.mouse.middle, .DRAG) }
mmb_click_drag :: proc() -> bool { return mmb_click() || mmb_drag() }
mmb_release :: proc() -> bool { return mouse_button(state.input.mouse.middle, .RELEASE) }
mmb_release_up :: proc() -> bool { return (mouse_button(state.input.mouse.middle, .RELEASE) || mouse_button(state.input.mouse.middle, .UP)) }
mmb_up :: proc() -> bool { return mouse_button(state.input.mouse.middle, .UP) }