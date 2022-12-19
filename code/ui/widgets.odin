package ui

import "core:fmt"
import "core:mem"

//______ BUILDER API ______//

//
// start each panel's content() with:
//   begin()
// this creates a root box and set's it to the context parent

reset_colors :: proc() {
	state.ctx.bg_color = state.col.bg
	state.ctx.border_color = state.col.border
	state.ctx.font_color = state.col.font
}

begin :: proc() -> ^Panel {
	reset_colors()
	if state.ctx.panel.type == .FLOATING {
		state.ctx.layer = 1
		state.ctx.box = nil
		state.ctx.parent = nil
		size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
		box := create_box("root_floating", {.ROOT, .DRAWBACKGROUND, .FLOATING})
		process_ops(box)
		state.ctx.panel.box = box
		push_parent(box)
	} else {
		state.ctx.box = nil
		state.ctx.parent = nil
		quad := state.ctx.panel.quad
		size(.PIXELS, quad.r - quad.l, .PIXELS, quad.b - quad.t)
		box := create_box("root", { .ROOT, .CLIP })
		process_ops(box)
		box.offset = {quad.l, quad.t}
		state.ctx.panel.box = box
		push_parent(box)
		size(.PIXELS, quad.r - quad.l, .PIXELS, quad.b - quad.t)
		axis(.Y)
	}
	return state.ctx.panel
}

// use 
//   end()
// at end of each panel's content().
//
end :: proc() {
	if state.ctx.panel.type == .FLOATING {
		if state.ctx.panel.box != nil {
			quad := state.ctx.panel.box.quad
			wquad := state.window.quad

			offset : [2]f32
			if quad.r > wquad.r do offset.x = -(quad.r - wquad.r)
			if quad.b > wquad.b do offset.y = -(quad.b - wquad.b)
			if quad.l < wquad.l do offset.x = wquad.l - quad.l
			if quad.t < wquad.t do offset.y = wquad.t - quad.t
			
			state.ctx.panel.box.offset += offset
		}
	} else {
		if mouse_in_quad(state.ctx.panel.quad) {
			if ctrl() && shift() {
				state.panels.locked = true
				state.ctx.layer = 1
				push_parent(state.ctx.panel.box)
				axis(.Y)
				size(.PCT_PARENT, 1, .PCT_PARENT, 1)
				extra_flags({.NO_OFFSET})
				empty("panel_splitter_1")
					axis(.Y)
					size(.PCT_PARENT, 1, .TEXT, 2)
					empty("panel_splitter_2")
						axis(.X)
						size(.PCT_PARENT, .45, .PCT_PARENT, 1)
						xops := button("SPLIT HORIZONTAL")
						if xops.released do split_panel(.Y)
						yops := button("SPLIT VERTICAL")
						if yops.released do split_panel(.X)
						size(.PCT_PARENT, .1, .PCT_PARENT, 1)
						if button("<#>x").released do delete_panel(state.ctx.panel)
					pop()

					axis(.Y)
					size(.PCT_PARENT, 1, .MIN_SIBLINGS, 1)
					ebox := create_box("empty_panel_splitter_line", {.DRAWBACKGROUND, .HOVERABLE})
					process_ops(ebox)
					ebox.bg_color = state.col.bg
					ebox.bg_color.a = .75
					
					push_parent(ebox)
					if yops.hovering {
						axis(.X)
						size(.PCT_PARENT, 0.5, .PCT_PARENT, 1)
						create_box("yspacer", {.DRAWBORDER})
						state.ctx.box.border_color = state.col.active	
						size(.PIXELS, 2, .PCT_PARENT, 1)
						bx := create_box("yline", {.DRAWBACKGROUND})
						bx.bg_color = state.col.active
						size(.MIN_SIBLINGS, 1, .PCT_PARENT, 1)
						create_box("yspacer2", {.DRAWBORDER})
						state.ctx.box.border_color = state.col.active
					} else if xops.hovering {
						axis(.Y)
						size(.PCT_PARENT, 1, .PCT_PARENT, 0.5)
						create_box("xspacer", {.DRAWBORDER})
						state.ctx.box.border_color = state.col.active
						size(.PCT_PARENT, 1, .PIXELS, 2)
						bx := create_box("xline", {.DRAWBACKGROUND})
						bx.bg_color = state.col.active
						size(.PCT_PARENT, 1, .MIN_SIBLINGS, 1)
						create_box("xspacer2", {.DRAWBORDER})
						state.ctx.box.border_color = state.col.active
					}

				pop()
				state.ctx.layer = 0
			}
		}
	}
	state.boxes.index = 0
	state.ctx.layer = 0
}

//______ PUSH and POP parent ______//
// there is a context parent that any newly generated box will be the next child of
// some widgets will automatically set new boxes they create to be the context parent
// however, sometimes you will want to manaully set the context parent
// use:
//   push_parent(box: ^Box)
//
push_parent :: proc(box: ^Box) {	state.ctx.parent = box }

// you will need to pop out of a box regularly.
// use:
//   pop()
//
pop :: proc(pops:int=1) { 
	for i in 0..<pops {
		if state.ctx.parent.parent != nil {
			state.ctx.parent = state.ctx.parent.parent 
		}
	}
}

//______ SIZE and AXIS for new boxes ______//
//
// the direction each box is offset by is determined by the axis context
// you set the axis context by using:
//   axis(.X)
// or
//   axis(.Y)
// you can think of it of setting the context for a row or column.
//
axis 				:: proc(axis: Axis) 	{ state.ctx.axis = axis }

// the size of each box is determined by the size context
// you set this with the function:
//   size(x_type, x_value, y_type, y_value)
//
// there is a type and value for each axis.
//
// for example:
//			  x type       x value   y type   y value
//   size(.PCT_PARENT,  0.5,     .PIXELS,  100)
// this means that for any subsequently generated boxes, the height will be
// half the height of the parent and the width will be 100 pixels.
//
// there are several differnt size types:
// 
//   .PIXELS			- number of pixels (value = number of pixels)
//   .TEXT				- height of # of line of text in pixels (value multiplied times the height of 1 line of text)
//   .PCT_PARENT		- size of parent in that axis (value multiplied times size of parent)
//   .SUM_CHILDREN	- the sum of all the box's children in that axis (value not used)
//   .MAX_CHILD		- the size of the largest child of that box (value not used)
//   .MIN_SIBLINGS	- the size of the parent minus the sum of the box's siblings (value not used)
//   .MAX_SIBLING		- the size of the largest sibling of that box (value not used)

size :: proc (x_type: Box_Size_Type, x_value: f32, y_type: Box_Size_Type, y_value: f32) {
	size_x(x_type, x_value)
	size_y(y_type, y_value)
}

size_x :: proc(type: Box_Size_Type, value: f32) {
	state.ctx.size.x.type = type
	state.ctx.size.x.value = value
}

size_y :: proc(type: Box_Size_Type, value: f32) {
	state.ctx.size.y.type = type
	state.ctx.size.y.value = value
}

// sets the border color

set_border_color 	:: proc(color: HSL) 		{ state.ctx.border_color = color }

// sets the border thickness

set_border_thickness :: proc(value: f32)		{ state.ctx.border = value }

// set text justification

just :: proc(align: Text_Align)					{ state.ctx.text_align = align }

// sets extra flags to add to next box (gets reset by create_box())

extra_flags :: proc(flags:bit_set[Box_Flags]) { state.ctx.flags = flags }

//______ WIDGETS ______//
//
//
// each box has a set of "ops" that are calculated for each frame
// these ops are:
//
//	clicked: 		bool = initial mouse click while over box
//	double_clicked: bool = not implemented
//	right_clicked: 	bool = not implemented
//	pressed: 		bool = mouse held down after clicking while over box
//	released: 		bool = mouse released after clicking or pressed
//	selected: 		bool = same as released, useful two have to paths for this behavior (maybe not?)
//	dragging: 		bool = same as pressed, useful two have to paths for this behavior (maybe not?)
//	hovering: 		bool = mouse over box while not being clicked, pressed, etc.
//
// most boxes return their ops so you can test on them, e.g.
//   button()
// return box.ops, so you could do:
//
// if button().clicked {
//     do somthing here	
// }
//
// some widgets return a pointer to the whole box instead of box.ops
// an example of this is:
//   empty()
//
// creates an empty container box to house visible boxes
// returns the box itself 

empty :: proc(name:string) -> ^Box {
	box := create_box(concat(name, "_empty"), { })
	process_ops(box)
	push_parent(box)
	return box
}

bar :: proc(name:string, pixels:f32=1, color:HSL={}, _axis:Axis=.Y) -> ^Box {
	old_size := state.ctx.size
	axis(_axis)
	if _axis == .Y {
		size(.PCT_PARENT, 1, .PIXELS, pixels)
	} else {
		size(.PIXELS, pixels, .PCT_PARENT, 1)
	}
	bar := create_box(fmt.tprint(name, "_bar"), { .DRAWBACKGROUND })
	process_ops(bar)

	if color != {} do bar.bg_color = color
	
	state.ctx.size = old_size
	return bar
}

// draws a color filled box

color :: proc(name:string, color:HSL) -> ^Box {
	box := create_box(concat(name, "_color"), {
		.DRAWBACKGROUND,
		.DRAWBORDER,
	})
	process_ops(box)
	box.bg_color = color
	return box
}

// creates a box that draws static text
// don't use this for values that change

label :: proc(text: string) -> ^Box {
	box := create_box(concat(text, "###_label"), { .DRAWTEXT, })
	process_ops(box)
	return box
}

// creates a box that draws text that is
// attached to a value and is dynamic.
// uses fmt.tprint() to convert value to text

value :: proc(name: string, value: any) -> Box_Ops {
	box := create_box(concat(name, "_value"), { .DISPLAYVALUE }, value)
	process_ops(box)
	return box.ops	
}

label_value :: proc(text: string, val:any, pixels:f32=0) {
	// axis(.Y)
	if pixels > 0 {
		size(.PIXELS, pixels, .TEXT, 1)
	} else {
		size(.PCT_PARENT, 1, .TEXT, 1)
	}
	empty(text)
		axis(.X)
		size(.MIN_SIBLINGS, 1, .PCT_PARENT, 1)
		label(text)
		size(.TEXT, 1, .PCT_PARENT, 1)
		value(text, val)
	pop()
}

label_values :: proc(text: string, vals:[]any, pixels:f32=0) {
	axis(.Y)
	if pixels > 0 {
		size(.PIXELS, pixels, .TEXT, 1)
	} else {
		size(.PCT_PARENT, 1, .TEXT, 1)
	}
	empty(concat("lab val1", text))
		axis(.X)
		size(.PIXELS, state.ctx.parent.calc_size.x/2, .PCT_PARENT, 1)
		label(concat(text, "###label_values"))
		sizebar_x(concat("split_vals", text))
		size(.MIN_SIBLINGS, 1, .PCT_PARENT, 1)
		empty(concat("lab val2", text))
			for val, i in vals {
				size(.PCT_PARENT, 1/f32(len(vals)), .PCT_PARENT, 1)
				value(concat(text, "the val", i), val)
			}
		pop()
	pop()
}

edit_value:: proc(key: string, ev: any) -> ^Box {
	box := create_box(concat(key, "_parent"), {
		.CLICKABLE,
		.HOVERABLE,
		.DRAWBACKGROUND,
		.DRAWBORDER,
		.DRAWGRADIENT,
		.HOTANIMATION,
	})

	push_parent(box)
	process_ops(box)

	size(.PCT_PARENT, 1, .PCT_PARENT, 1)
	text_box := create_box(concat(key, "_text_box"), {
		.EDITVALUE,
		.CLIP,
	}, ev)

	is_editing := (text_box.key == state.boxes.editing)	

	// NOTE editing-check
	if is_editing {
		excl(&box.flags, Box_Flags.HOTANIMATION)
		if box.ops.off_clicked || box.ops.right_clicked || esc() || enter() {
			end_editing_value(text_box)
		}
	// NOTE editing-check
	} else if box.ops.clicked && state.boxes.editing == {} {
		start_editing_value(text_box)
	}

	process_ops(text_box)
	pop()
	return box
}

// creates single line editable text

edit_text :: proc(key: string, es: ^String) -> Box_Ops {
	old_size := state.ctx.size
	box := create_box(concat(key, "_edit_text"), {
		.CLICKABLE,
		.HOVERABLE,
		.DRAWBACKGROUND,
		.DRAWBORDER,
		.DRAWGRADIENT,
		.VIEWSCROLL,
		.CLIP,
	})

	push_parent(box)
	process_ops(box)

	size(.TEXT, 1, .PCT_PARENT, 1)
	text_box := create_box(concat(key, "editable_text_box"), {
		.EDITTEXT,
	})
	text_box.editable_string = es

	if box.ops.clicked {
		state.boxes.editing = text_box.key
	} else if box.ops.off_clicked || box.ops.right_clicked {
		state.boxes.editing = {}
	}

	process_ops(text_box)

	pop()

	if box.ops.middle_dragged {
		if box.ops.middle_clicked {
			state.input.mouse.delta_temp.x = state.input.mouse.pos.x - text_box.offset.x
		}
		text_box.scroll.x = state.input.mouse.pos.x - state.input.mouse.delta_temp.x
	}

	state.ctx.size = old_size
	return box.ops
}


paragraph :: proc(name:string, value: ^String) -> Box_Ops {
	// assert(value.id == Document)
	// val := cast(^Document)value.data
	
	sbox := scrollbox(name)
	
	width : f32 = 0
	last_space := 0
	start := 0

	if value.width != sbox.calc_size.x {
		value.width = sbox.calc_size.x
		value.lines = 0
		i : int = 0
		for i < len(value.mem) {
			char := value.mem[i]
			if char == ' ' do last_space = i
			return_break := (char == '\n')
			width_break := (width >= value.width-30)
			last_char := (i == len(value.mem)-1)
			if return_break || width_break || last_char {
				if width_break {
					if last_space > start do i = last_space+1
				}
				start = i
				value.lines += 1
				width = 0
			} else {
				width += state.font.weight[Weight_Type.REGULAR].char_data[rune(char)].advance
			}
			i += 1
		}
	}
	
	size(.PIXELS, value.width, .PIXELS, (state.font.line_space-4) * f32(value.lines+1))
	box := create_box(concat(name, "paragraph"), { .HOVERABLE, .DRAWPARAGRAPH })
	box.editable_string = value
	process_ops(box)

	value.current_line = clamp( (int( (-box.scroll.y / (box.calc_size.y)) * f32(value.lines+1) ) ), 0, value.lines)
	value.last_line = clamp( value.current_line + int(sbox.calc_size.y/(state.font.line_space-4)), 0, value.lines)

	return box.ops
}


// creates a slider for editing float values

slider :: proc(label:string, value:^f32, min:f32=0, max:f32=1) -> Box_Ops {
	old_size := state.ctx.size
	box := create_box(concat(label, "_slider"), {
		.CLICKABLE,
		.HOVERABLE,
		.DRAWBACKGROUND,
		.DRAWBORDER,
		.DRAWGRADIENT,
		.HOTANIMATION,
	}, any(value^))

	process_ops(box)
	push_parent(box)
	size(.PCT_PARENT, value^, .PCT_PARENT, 1)
	highlight := create_box(concat(label, "_highlight"), {
		.DRAWBACKGROUND,
		.DRAWGRADIENT,
		.ACTIVEANIMATION,
		.HOTANIMATION,
		.HOVERABLE,
		.CLICKABLE,
	})
	highlight.bg_color = state.col.highlight
	process_ops(highlight)
	
	size(.PCT_PARENT, 1, .PCT_PARENT, 1)
	display_value := create_box(concat(label, "_display_val"), {
		.EDITVALUE,
		.NO_OFFSET,
	}, value^)

	// NOTE editing-check
	if display_value.key == state.boxes.editing {
		excl(&box.flags, Box_Flags.HOVERABLE)
		excl(&highlight.flags, Box_Flags.CLICKABLE)
		excl(&highlight.flags, Box_Flags.ACTIVEANIMATION)
		excl(&highlight.flags, Box_Flags.HOTANIMATION)
		excl(&highlight.flags, Box_Flags.HOVERABLE)
	}
	process_ops(display_value)

	if box.ops.ctrl_clicked {
		start_editing_value(display_value)
	// NOTE editing-check
	} else if state.boxes.editing == display_value.key {
		if box.ops.off_clicked || enter() {
			end_editing_value(display_value)
		} else if esc() {
			end_editing_value(display_value, false)
		}
	}

	// NOTE editing-check
	if display_value.key != state.boxes.editing {
		if box.ops.clicked {
			state.input.mouse.delta_temp = state.input.mouse.pos - linear(value^, min, max, 0, box.calc_size.x)
		}

		if box.ops.pressed {
			value^ = clamp(linear(state.input.mouse.pos.x-state.input.mouse.delta_temp.x, 0, box.calc_size.x, min, max), min, max)
		}
	}

	pop()
	state.ctx.size = old_size
	return box.ops
}

// creates a button box

button :: proc(name: string) -> Box_Ops {
	box := create_box(concat(name, "###_button"), {
		.CLICKABLE,
		.HOVERABLE,
		.DRAWTEXT,
		.DRAWBORDER,
		.DRAWBACKGROUND,
		.DRAWGRADIENT,
		.HOTANIMATION,
		.ACTIVEANIMATION,
	})
	process_ops(box)
	box.text_align = .CENTER
	return box.ops
}

menu :: proc (name: string, labels:[]string) -> ([]^Box, ^Box) {
	state.ctx.layer = 1
	buttons := make([]^Box, len(labels), context.temp_allocator)
	active_button : ^Box
	box := empty(name)
		axis(.X)
		size(.TEXT, 1, .TEXT, 1)
		released_button : int = -1
		hovering_button : int = -1
		selected_button : int = -1
		off_clicked := false
		for label, i in labels { 
			buttons[i] = create_box(concat(label, "###", name), {
				.CLICKABLE,
				.HOVERABLE,
				.DRAWTEXT,
				.DRAWBACKGROUND,
				.DRAWGRADIENT,
				.HOTANIMATION,
				.ACTIVEANIMATION,
			})
			process_ops(buttons[i])
			if buttons[i].ops.released do released_button = i
			if buttons[i].ops.hovering do hovering_button = i
			if buttons[i].ops.selected do selected_button = i
			off_clicked = buttons[i].ops.off_clicked
		}

	pop()
	container : ^Box

	if selected_button >= 0 {
		active_button = buttons[selected_button]
		push_parent(active_button)
		axis(.Y)
		state.ctx.layer = 1
		size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
		container = create_box(concat(name, "_menu elements"), { .NOCLIP, .CLIP, .DRAWBACKGROUND })
		process_ops(container)
		container.offset.y = state.font.line_space
		push_parent(container)
	}

	if selected_button >= 0 && off_clicked && container != nil {
		if !mouse_in_quad(container.quad) {
			buttons[selected_button].ops.selected = false
			active_button = nil
		}
	} else if released_button >= 0 {
		buttons[released_button].ops.selected = true
		if selected_button >= 0 do buttons[selected_button].ops.selected = false
	} else if selected_button >= 0 {
		if hovering_button >= 0 && hovering_button != selected_button {
			buttons[hovering_button].ops.selected = true
			if selected_button >= 0 do buttons[selected_button].ops.selected = false
		}
	}
	if active_button == nil {
		state.ctx.layer = 0
	} else {
		state.panels.locked = true
	}
	return buttons, active_button
}

menu_end :: proc() {
	pop(3)
}

// creates a button without a border (for use in menus)
menu_button :: proc(name: string) -> Box_Ops {
	box := create_box(concat(name, "###menu_button"), {
		.CLICKABLE,
		.HOVERABLE,
		.DRAWTEXT,
		.DRAWBACKGROUND,
		.DRAWGRADIENT,
		.HOTANIMATION,
	})
	process_ops(box)
	box.text_align = .LEFT
	return box.ops
}

// creates a selectable box (for making dropdowns, checkboxes)

dropdown :: proc(name: string) -> Box_Ops {
	box := create_box(concat(name, "###_dropdown"), {
		.CLICKABLE,
		.SELECTABLE,
		.HOVERABLE,
		.DRAWTEXT,
		.DRAWBACKGROUND,
		.DRAWGRADIENT,
		.HOTANIMATION,
		.ACTIVEANIMATION,
	})
	process_ops(box)
	if box.ops.selected {
		box.name = from_odin_string(concat("<#>s<r>", name))
	} else {
		box.name = from_odin_string(concat("<#>d<r>", name))
	}

	box.text_align = .LEFT
	return box.ops
}

image :: proc(key: string, image: ^Image) -> Box_Ops {
	box := create_box(concat(key, "_image"), {
		.DRAWIMAGE,
	}, image)
	return box.ops
}

// creates a radio button

radio :: proc(key: string) -> ^Box {
	box := create_box(concat(key, "###_radio"), {
		.CLICKABLE,
		.HOVERABLE,
		.DRAWTEXT,
		.DRAWBACKGROUND,
		.DRAWGRADIENT,
		.HOTANIMATION,
		.ACTIVEANIMATION,
	})
	process_ops(box)
	return box
}

// creates a set of tabs

tab :: proc(_name:string, names: []string, close_button:bool=false, select_tab:int=-1) -> ([]^Box, int) {
	tab := empty(_name)
	tabs := make([]^Box, len(names), context.temp_allocator)

	clicked := select_tab
	index := -1

	for name, i in names {
		axis(.X)
		size(.SUM_CHILDREN, 1, .TEXT, 1)
		tab := create_box(concat("###radio", _name, name, i), {
			.CLICKABLE,
			.HOVERABLE,
			.DRAWTEXT,
			.DRAWBACKGROUND,
			.DRAWGRADIENT,
			.HOTANIMATION,
			.ACTIVEANIMATION,
		})
		process_ops(tab)
		push_parent(tab)
			size(.TEXT, 1, .TEXT, 1)
			label := label(concat(name, "###", i))
			
			if close_button {
				close := button(fmt.tprint("<#>x###close", _name, name, i))
				excl(&state.ctx.box.flags, Box_Flags.DRAWBACKGROUND, Box_Flags.DRAWGRADIENT, Box_Flags.DRAWBORDER)
				if close.released do tab.ops.middle_clicked = true
			}

			if tab.ops.clicked {
				clicked = i
				index = i
			}
			if tab.ops.selected {
				index = i
			}
			tabs[i] = tab
		pop()
	}

	if index == -1 do index = len(names)-1
	
	if len(names) == 1 {
		tabs[0].ops.selected = true
		index = 0
	} else {
		if tab.first != nil {
			if state.frame - tab.first.frame_created <= 10 {
				index = len(names)-1
			}
		}

		for tab, i in tabs {
			if clicked >= 0 {
				tab.ops.selected = (i == clicked)
			} else {
				tab.ops.selected = (i == index)
			}
		}

		bar(concat(_name, "_tabbar1"), 2, state.col.active)
	}

	pop()
	return tabs, index
}

// creates a spacer that fills up the .X axis, subtracting the sum of siblings from the parent size
// TODO make this work for the .Y axis
// parent must not rely solely on children for .X size

spacer_fill :: proc(name: string) -> Box_Ops {
	oldsize := state.ctx.size[X]
	size_x(.MIN_SIBLINGS, 1)
	box := create_box(concat(name, "_spacer_fill"), {
	})
	process_ops(box)
	size_x(oldsize.type, oldsize.value)
	return box.ops
}

// creates a spacer in the .X axis by pixels
// TODO make this work for the .Y axis

spacer_pixels :: proc(name: string, pixels: f32) -> Box_Ops {
	oldsize := state.ctx.size.x
	size_x(.PIXELS, pixels)
	box := create_box(concat(name, "_spacer_pixels"), {})
	process_ops(box)
	size_x(oldsize.type, oldsize.value)
	return box.ops
}

// creates a box that will clip it's contents by it's height
// and offset the first child by x and y

scrollbox :: proc(name:string, freeze:bool=false) -> ^Box {
	scrollbox := create_box(concat(name, "_scrollbox"), { })
	process_ops(scrollbox)
	push_parent(scrollbox)

	axis(.X)
	size(.NONE, 0, .NONE, 0)
	// if freeze {
	// 	extra_flags({ .NO_OFFSET })
	// } else {
	// 	extra_flags({ .NO_OFFSET })
	// }
	viewport := create_box(concat(name, "_viewport"), { .CLIP, .VIEWSCROLL, .SCROLLBOX, .NO_OFFSET })
	process_ops(viewport)

	size(.NONE, 0, .NONE, 0)
	sby := create_box(concat(name, "_scrollbar_y"), { .NO_OFFSET, .DRAWBACKGROUND })
	process_ops(sby)
	// TODO sby.offset.x = viewport_width
	push_parent(sby)

	size(.NONE, 1, .NONE, 0)
	y_handle := create_box(concat(name, "_y_handle"), { .DRAWGRADIENT, .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .ACTIVEANIMATION, .CLICKABLE } )
	process_ops(y_handle)
	y_handle.bg_color = state.col.inactive
	// TODO y_handle.offset.y = -handle_value.y 
	pop()

	size(.NONE, 0, .NONE, 0)
	sbx := create_box(concat(name, "_scrollbar_x"), { .NO_OFFSET, .DRAWBACKGROUND })
	process_ops(sbx)
	// sbx.offset.y = viewport_height
	push_parent(sbx)

	size(.NONE, 0, .NONE, 0)
	x_handle := create_box(concat(name, "_x_handle"), { .DRAWGRADIENT, .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .CLICKABLE } )
	process_ops(x_handle)
	x_handle.bg_color = state.col.inactive
	// x_handle.offset.x = -handle_value.x
	pop()

	push_parent(viewport)
	return viewport
}


// set size of window
// axis(.Y)
// size(.PCT_PARENT, 1, .PCT_PARENT, 1)
scroller :: proc(name: string) {
	
}
 
// add this at the end of an empty to be able to manually change the scale
// TODO only works in the .Y axis for right now

sizebar_y :: proc(name:string, pixels:f32=4, color:HSL={}) -> ^Box {
	axis(.Y)
	size(.PCT_PARENT, 1, .PIXELS, pixels)
	box := create_box(concat(name, "sizebar_y"), { .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .CLICKABLE })
	if color != {} do box.bg_color = color
	process_ops(box)
	if box.ops.pressed {
		if box.ops.clicked {
			state.input.mouse.delta_temp.y = state.input.mouse.pos.y - box.prev.expand.y
		}
		box.prev.expand.y = state.input.mouse.pos.y - state.input.mouse.delta_temp.y
	}
	if box.ops.hovering do cursor_size(box.axis)
	return box
}

sizebar_x :: proc(name:string, pixels:f32=4, color:HSL={}) -> ^Box {
	axis(.X)
	size(.PIXELS, pixels, .PCT_PARENT, 1)
	box := create_box(concat(name, "_sizebar_x"), { .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .CLICKABLE })
	if color != {} do box.bg_color = color
	process_ops(box)
	if box.ops.pressed {
		if box.ops.clicked {
			state.input.mouse.delta_temp.x = state.input.mouse.pos.x - box.prev.expand.x
		}
		box.prev.expand.x = state.input.mouse.pos.x - state.input.mouse.delta_temp.x
	}
	if box.ops.hovering do cursor_size(box.axis)
	return box
}

// add this anywhere in a floating panel and you use the space to drag the panel around
// TODO might be used for draggable boxes within boxes at some point?

drag_panel :: proc(name:string, label:string="") -> ^Box {
	box: ^Box
	if label == "" {
		box = create_box(concat(name, "drag_panel"), {
			.CLICKABLE,
			.HOVERABLE,
			.DRAGGABLE,
			.DRAWBACKGROUND,
		})
	} else {
		box = create_box(concat(label, "###drag_panel", name), {
			.CLICKABLE,
			.HOVERABLE,
			.DRAGGABLE,
			.DRAWBACKGROUND,
			.DRAWTEXT,
		})
	}
	process_ops(box)
	return box
}