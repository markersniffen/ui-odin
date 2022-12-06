package ui

import "core:fmt"
import "core:mem"

//______ BUILDER API ______//

//
// start each panel with:
//   begin()
// this creates a root box and set's it to the context parent

reset_colors :: proc() {
	state.ctx.bg_color = state.col.bg
	state.ctx.border_color = state.col.border
	state.ctx.font_color = state.col.font
}

begin :: proc() -> ^Panel {
	reset_colors()
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
	return state.ctx.panel
}

// use
//   begin_floating()
// at the beginning of floating panels instead of begin()
//
begin_floating :: proc(flags:bit_set[Box_Flags]={.ROOT, .DRAWBACKGROUND, .FLOATING}) -> ^Panel {
	reset_colors()
	state.ctx.box = nil
	state.ctx.parent = nil
	size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
	box := create_box("root_floating", flags)
	process_ops(box)
	state.ctx.panel.box = box
	push_parent(box)
	return state.ctx.panel
}


// TODO what's the difference between these two?
// use
//   begin_menu()
// at the beginning of menu panels instead of begin()
//
begin_menu :: proc(flags:bit_set[Box_Flags]={.ROOT, .DRAWBACKGROUND, .MENU}) -> ^Panel {
	return begin_floating(flags)
}

// use
//   begin_floating_menu()
// at the beginning of menu panels instead of begin()
//
begin_floating_menu :: proc(flags:bit_set[Box_Flags]={.ROOT, .DRAWBACKGROUND, .FLOATING, .MENU}) -> ^Panel {
	return begin_floating(flags)
}

// use 
//   end()
// at end of each panel.
//
end :: proc() {
	state.boxes.index = 0
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
pop :: proc() { state.ctx.parent = state.ctx.parent.parent }

//______ SIZE and AXIS for new boxes ______//
//
// the direction each box is offset by is determined by the axis context
// you set the axis context by using:
//   axis(.X)
// or
//   axis(.Y)
// you can think of it of setting the context for a row or column.
//
axis 				:: proc(axis: UI_Axis) 	{ state.ctx.axis = axis }

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
//   .PIXELS		- number of pixels (value = number of pixels)
//   .TEXT			- height of # of line of text in pixels (value multiplied times the height of 1 line of text)
//   .PCT_PARENT	- size of parent in that axis (value multiplied times size of parent)
//   .SUM_CHILDREN	- the sum of all the box's children in that axis (value not used)
//   .MAX_CHILD		- the size of the largest child of that box (value not used)
//   .MIN_SIBLINGS	- the size of the parent minus the sum of the box's siblings (value not used)
//   .MAX_SIBLING	- the size of the largest sibling of that box (value not used)

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

empty :: proc(_name:string="") -> ^Box {
	name := "empty"
	if _name != "" do name = _name
	box := create_box(name, { })
	process_ops(box)
	push_parent(box)
	return box
}

bar :: proc(color:HSL={}, _axis:UI_Axis=.Y) -> ^Box {
	axis(_axis)
	if _axis == .Y {
		size(.PCT_PARENT, 1, .PIXELS, state.font.margin/2)
	} else {
		size(.PIXELS, state.font.margin, .PCT_PARENT, 1)
	}
	bar := create_box("bar", { .DRAWBACKGROUND })
	process_ops(bar)

	if color != {} do bar.bg_color = color

	return bar
}

// draws a color filled box

color :: proc(color:HSL) -> ^Box {
	box := create_box("editable_text", {
		.DRAWBACKGROUND,
		.DRAWBORDER,
	})
	process_ops(box)
	box.bg_color = color
	return box
}

// creates a box that draws static text
// don't use this for values that change

label :: proc(key: string) -> ^Box {
	box := create_box(key, { .DRAWTEXT, })
	process_ops(box)
	return box
}

// creates a box that draws text that is
// attached to a value and is dynamic.
// uses fmt.tprint() to convert value to text

value :: proc(key: string, value: any) -> Box_Ops {
	box := create_box(key,{ .DISPLAYVALUE }, value)
	process_ops(box)
	return box.ops	
}

edit_value:: proc(key: string, ev: any) -> ^Box {
	box := create_box(fmt.tprint("parent", key), {
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
	text_box := create_box(key, {
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
	box := create_box("editable_text", {
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
	text_box := create_box("editable_text_box", {
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

	return box.ops
}


paragraph :: proc(value: ^String) -> Box_Ops {
	// assert(value.id == Document)
	// val := cast(^Document)value.data
	
	sbox := scrollbox()
	
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
				width += state.font.fonts.regular.char_data[rune(char)].advance
			}
			i += 1
		}
	}
	
	size(.PIXELS, value.width, .PIXELS, (state.font.line_space-4) * f32(value.lines+1))
	box := create_box("paragraph", { .HOVERABLE, .DRAWPARAGRAPH })
	box.editable_string = value
	process_ops(box)

	value.current_line = clamp( (int( (-box.scroll.y / (box.calc_size.y)) * f32(value.lines+1) ) ), 0, value.lines)
	value.last_line = clamp( value.current_line + int(sbox.calc_size.y/(state.font.line_space-4)), 0, value.lines)

	return box.ops
}


// creates a slider for editing float values

slider :: proc(label:string, value:^f32, min:f32=0, max:f32=1) -> Box_Ops {
	old_size := state.ctx.size
	box := create_box(label, {
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
	highlight := create_box("highlight", {
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
	display_value := create_box(fmt.tprint("disp val", label), {
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

button :: proc(key: string) -> Box_Ops {
	box := create_box(key, {
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


menu :: proc (name: string, labels:[]string) -> ([]^Box, int) {
	buttons := make([]^Box, len(labels), context.temp_allocator)
	axis(.Y)
	size(.PCT_PARENT, 1, .TEXT, 1)
	box := empty(name)
	axis(.X)
	size(.TEXT, 1, .TEXT, 1)
	for label, i in labels { 
		buttons[i] = create_box(label, {
			.CLICKABLE,
			.HOVERABLE,
			.DRAWTEXT,
			.DRAWBORDER,
			.DRAWBACKGROUND,
			.DRAWGRADIENT,
			.HOTANIMATION,
			.ACTIVEANIMATION,
		})
		process_ops(buttons[i])
		if buttons[i].ops.released {
			box.ops.selected = true
			buttons[i].ops.selected = true
		}
		if box.ops.selected {
			fmt.println("selected")
			if buttons[i].ops.hovering {
				buttons[i].ops.selected = true
			}
		}
	}
	return buttons, 0
}

// creates a button without a border (for use in menus)
menu_button :: proc(key: string) -> Box_Ops {
	box := create_box(key, {
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

dropdown :: proc(key: string) -> Box_Ops {
	box := create_box(key, {
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
		box.name = from_odin_string(fmt.tprint("<#>s<r>", key))
	} else {
		box.name = from_odin_string(fmt.tprint("<#>d<r>", key))
	}
	box.text_align = .LEFT
	return box.ops
}

// creates a radio button

radio :: proc(key: string) -> ^Box {
	box := create_box(key, {
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

tab :: proc(names: []string, close_button:bool=false, select_tab:int=-1) -> ([]^Box, int) {
	tab := empty()
	tabs := make([]^Box, len(names), context.temp_allocator)

	clicked := select_tab
	index := -1

	for name, i in names {
		axis(.X)
		size(.SUM_CHILDREN, 1, .TEXT, 1)
		tab := create_box(fmt.tprint("###radio", i), {
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
			label := label(name)
			
			if close_button {
				close := button(fmt.tprint("<#>x###close", i))
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

		bar(state.col.active)
		bar(state.col.active)
	}

	pop()
	return tabs, index
}

// creates a spacer that fills up the .X axis, subtracting the sum of siblings from the parent size
// TODO make this work for the .Y axis
// parent must not rely solely on children for .X size

spacer_fill :: proc() -> Box_Ops {
	oldsize := state.ctx.size[X]
	size_x(.MIN_SIBLINGS, 1)
	box := create_box("spacer_fill", {
	})
	process_ops(box)
	size_x(oldsize.type, oldsize.value)
	return box.ops
}

// creates a spacer in the .X axis by pixels
// TODO make this work for the .Y axis

spacer_pixels :: proc(pixels: f32, name:="spacer_pixels") -> Box_Ops {
	oldsize := state.ctx.size.x
	size_x(.PIXELS, pixels)
	box := create_box(name, {})
	process_ops(box)
	size_x(oldsize.type, oldsize.value)
	return box.ops
}

// creates a box that will clip it's contents by it's height
// and offset the first child by x and y

scrollbox :: proc(_x:bool=false, _y:bool=false) -> ^Box {
	scrollbox := create_box("scrollbox", { })
	process_ops(scrollbox)
	push_parent(scrollbox)

	axis(.X)
	size(.NONE, 0, .NONE, 0)
	viewport := create_box("viewport", { .CLIP, .VIEWSCROLL, .SCROLLBOX, .NO_OFFSET })
	process_ops(viewport)

	size(.NONE, 0, .NONE, 0)
	sby := create_box("scrollbar_y", { .NO_OFFSET, .DRAWBACKGROUND })
	process_ops(sby)
	// TODO sby.offset.x = viewport_width
	push_parent(sby)

	size(.NONE, 1, .NONE, 0)
	y_handle := create_box("y_handle", { .DRAWGRADIENT, .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .ACTIVEANIMATION, .CLICKABLE } )
	process_ops(y_handle)
	y_handle.bg_color = state.col.inactive
	// TODO y_handle.offset.y = -handle_value.y 
	pop()

	size(.NONE, 0, .NONE, 0)
	sbx := create_box("scrollbar_x", { .NO_OFFSET, .DRAWBACKGROUND })
	process_ops(sbx)
	// sbx.offset.y = viewport_height
	push_parent(sbx)

	size(.NONE, 0, .NONE, 0)
	x_handle := create_box("x_handle", { .DRAWGRADIENT, .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .CLICKABLE } )
	process_ops(x_handle)
	x_handle.bg_color = state.col.inactive
	// x_handle.offset.x = -handle_value.x
	pop()

	push_parent(viewport)
	return viewport
}

scrollbox_old :: proc(_x:bool=false, _y:bool=false) -> ^Box {
	scrollbox := create_box("scrollbox", { })
	process_ops(scrollbox)
	push_parent(scrollbox)

	bar_width :f32= 14
	x := _x
	y := _y

	if scrollbox.first != nil {
		if scrollbox.first.first != nil {
			first := scrollbox.first.first
			x = (first.calc_size.x > scrollbox.first.calc_size.x)
			y = (first.calc_size.y > scrollbox.first.calc_size.y)
		}
	}
	
	viewport_width := scrollbox.calc_size.x
	if y do viewport_width -= bar_width

	viewport_height := scrollbox.calc_size.y
	if x do viewport_height -= bar_width

	axis(.X)
	size(.PIXELS, viewport_width, .PIXELS, viewport_height)
	viewport := create_box("viewport", { .CLIP, .VIEWSCROLL  })
	process_ops(viewport)

	if viewport.first != nil {
		db_size := ((viewport.calc_size + viewport.expand) / viewport.first.calc_size) * (viewport.calc_size + viewport.expand)
		db_size.x = max(db_size.x, 40)
		db_size.y = max(db_size.y, 40)
		db_range := (viewport.calc_size + viewport.expand) - db_size
		scr_range := viewport.first.calc_size - (viewport.calc_size + viewport.expand)
		scr_value := viewport.first.offset
		mpl := scr_value / scr_range
		db_value := db_range * mpl
		if y {
			size(.PIXELS, bar_width, .PIXELS, viewport_height)
			sby := create_box("scrollbar_y", { .NO_OFFSET, .DRAWBACKGROUND })
			process_ops(sby)
			sby.offset.x = viewport_width
			push_parent(sby)

			size(.PCT_PARENT, 1, .PIXELS, db_size.y)
			y_handle := create_box("y_handle", { .DRAWGRADIENT, .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .ACTIVEANIMATION, .CLICKABLE } )
			process_ops(y_handle)
			y_handle.bg_color = state.col.inactive
			y_handle.offset.y = -db_value.y
			pop()

			if y_handle.ops.pressed {
				state.panels.locked = true
				if y_handle.ops.clicked {
					state.input.mouse.delta_temp.y = state.input.mouse.pos.y * (scr_range.y/db_range.y) + viewport.first.offset.y
				}
				viewport.first.scroll.y = ((state.input.mouse.pos.y*(scr_range.y/db_range.y)) - state.input.mouse.delta_temp.y) * -1
			} else {
				state.panels.locked = false
			}
		}
		if x {
			size(.PIXELS, viewport_width, .PIXELS, bar_width)
			sbx := create_box("scrollbar_x", { .NO_OFFSET, .DRAWBACKGROUND })
			process_ops(sbx)
			sbx.offset.y = viewport_height
			push_parent(sbx)

			size(.PIXELS, db_size.x, .PCT_PARENT, 1)
			x_handle := create_box("x_handle", { .DRAWGRADIENT, .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .CLICKABLE } )
			process_ops(x_handle)
			x_handle.bg_color = state.col.inactive
			x_handle.offset.x = -db_value.x
			pop()

			if x_handle.ops.pressed {
				if x_handle.ops.clicked {
					state.input.mouse.delta_temp.x = state.input.mouse.pos.x * (scr_range.x/db_range.x) + viewport.first.offset.x
				}
				viewport.first.scroll.x = ((state.input.mouse.pos.x*(scr_range.x/db_range.x)) - state.input.mouse.delta_temp.x) * -1
			}
		}

		if viewport.ops.middle_dragged {
			if viewport.ops.middle_clicked {
				state.input.mouse.delta_temp = state.input.mouse.pos - viewport.first.offset
			}
			viewport.first.scroll = state.input.mouse.pos - state.input.mouse.delta_temp
		}
	}

	push_parent(viewport)
	return viewport
}

// add this at the end of an empty to be able to manually change the scale
// TODO only works in the .Y axis for right now

sizebar_y :: proc() -> ^Box {
	axis(.Y)
	size(.PCT_PARENT, 1, .PIXELS, 4)
	box := create_box("sizebar_y", { .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .CLICKABLE })
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

sizebar_x :: proc() -> ^Box {
	axis(.X)
	size(.PIXELS, 4, .PCT_PARENT, 1)
	box := create_box("sizebar_y", { .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .CLICKABLE })
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

drag_panel :: proc(label:string="") -> ^Box {
	box: ^Box
	if label == "" {
		box = create_box("drag_panel", {
			.CLICKABLE,
			.HOVERABLE,
			.DRAGGABLE,
			.DRAWBACKGROUND,
		})
	} else {
		box = create_box(label, {
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