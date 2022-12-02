package ui

import "core:fmt"
import "core:mem"

//______ BUILDER API ______//

//
// start each panel with:
//   ui_begin()
// this creates a root box and set's it to the context parent

ui_reset_colors :: proc() {
	state.ui.ctx.bg_color = state.ui.col.bg
	state.ui.ctx.border_color = state.ui.col.border
	state.ui.ctx.font_color = state.ui.col.font
}

ui_begin :: proc() -> ^Panel {
	ui_reset_colors()
	state.ui.ctx.box = nil
	state.ui.ctx.parent = nil
	quad := state.ui.ctx.panel.quad
	ui_size(.PIXELS, quad.r - quad.l, .PIXELS, quad.b - quad.t)
	box := ui_create_box("root", { .ROOT, .CLIP })
	ui_process_ops(box)
	box.offset = {quad.l, quad.t}
	state.ui.ctx.panel.box = box
	ui_push_parent(box)
	ui_size(.PIXELS, quad.r - quad.l, .PIXELS, quad.b - quad.t)
	ui_axis(.Y)
	return state.ui.ctx.panel
}

// use
//   ui_begin_floating()
// at the beginning of floating panels instead of ui_begin()
//
ui_begin_floating :: proc(flags:bit_set[Box_Flags]={.ROOT, .DRAWBACKGROUND, .FLOATING}) -> ^Panel {
	ui_reset_colors()
	state.ui.ctx.box = nil
	state.ui.ctx.parent = nil
	ui_size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
	box := ui_create_box("root_floating", flags)
	ui_process_ops(box)
	state.ui.ctx.panel.box = box
	ui_push_parent(box)
	return state.ui.ctx.panel
}

// use
//   ui_begin_menu()
// at the beginning of menu panels instead of ui_begin()
//
ui_begin_menu :: proc(flags:bit_set[Box_Flags]={.ROOT, .DRAWBACKGROUND, .MENU}) -> ^Panel {
	return ui_begin_floating(flags)
}

// use
//   ui_begin_floating_menu()
// at the beginning of menu panels instead of ui_begin()
//
ui_begin_floating_menu :: proc(flags:bit_set[Box_Flags]={.ROOT, .DRAWBACKGROUND, .FLOATING, .MENU}) -> ^Panel {
	return ui_begin_floating(flags)
}

// use 
//   ui_end()
// at end of each panel.
//
ui_end :: proc() {
	state.ui.boxes.index = 0
}

//______ PUSH and POP parent ______//
// there is a context parent that any newly generated box will be the next child of
// some widgets will automatically set new boxes they create to be the context parent
// however, sometimes you will want to manaully set the context parent
// use:
//   ui_push_parent(box: ^Box)
//
ui_push_parent :: proc(box: ^Box) {	state.ui.ctx.parent = box }

// you will need to pop out of a box regularly.
// use:
//   ui_pop()
//
ui_pop :: proc() { state.ui.ctx.parent = state.ui.ctx.parent.parent }

//______ SIZE and AXIS for new boxes ______//
//
// the direction each box is offset by is determined by the axis context
// you set the axis context by using:
//   ui_axis(.X)
// or
//   ui_axis(.Y)
// you can think of it of setting the context for a row or column.
//
ui_axis 				:: proc(axis: Axis) 	{ state.ui.ctx.axis = axis }

// the size of each box is determined by the size context
// you set this with the function:
//   ui_size(x_type, x_value, y_type, y_value)
//
// there is a type and value for each axis.
//
// for example:
//			  x type       x value   y type   y value
//   ui_size(.PCT_PARENT,  0.5,     .PIXELS,  100)
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

ui_size :: proc (x_type: Box_Size_Type, x_value: f32, y_type: Box_Size_Type, y_value: f32) {
	ui_size_x(x_type, x_value)
	ui_size_y(y_type, y_value)
}

ui_size_x :: proc(type: Box_Size_Type, value: f32) {
	state.ui.ctx.size.x.type = type
	state.ui.ctx.size.x.value = value
}

ui_size_y :: proc(type: Box_Size_Type, value: f32) {
	state.ui.ctx.size.y.type = type
	state.ui.ctx.size.y.value = value
}

// sets the border color

ui_set_border_color 	:: proc(color: HSL) 		{ state.ui.ctx.border_color = color }

// sets the border thickness

ui_set_border_thickness :: proc(value: f32)		{ state.ui.ctx.border = value }

// sets extra flags to add to next box (gets reset by ui_create_box())

ui_extra_flags :: proc(flags:bit_set[Box_Flags]) { state.ui.ctx.flags = flags }

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
//   ui_button()
// return box.ops, so you could do:
//
// if ui_button().clicked {
//     do somthing here	
// }
//
// some widgets return a pointer to the whole box instead of box.ops
// an example of this is:
//   ui_empty()
//
// creates an empty container box to house visible boxes
// returns the box itself 

ui_empty :: proc(_name:string="") -> ^Box {
	name := "empty"
	if _name != "" do name = _name
	box := ui_create_box(name, { })
	ui_process_ops(box)
	ui_push_parent(box)
	return box
}

ui_bar :: proc(color:HSL={}, axis:Axis=.Y) -> ^Box {
	ui_axis(axis)
	if axis == .Y {
		ui_size(.PCT_PARENT, 1, .PIXELS, state.ui.margin/2)
	} else {
		ui_size(.PIXELS, state.ui.margin, .PCT_PARENT, 1)
	}
	bar := ui_create_box("bar", { .DRAWBACKGROUND })
	ui_process_ops(bar)

	if color != {} do bar.bg_color = color

	return bar
}

// draws a color filled box

ui_color :: proc(color:HSL) -> ^Box {
	box := ui_create_box("editable_text", {
		.DRAWBACKGROUND,
		.DRAWBORDER,
	})
	ui_process_ops(box)
	box.bg_color = color
	return box
}

// creates a box that draws static text
// don't use this for values that change

ui_label :: proc(key: string) -> ^Box {
	box := ui_create_box(key, { .DRAWTEXT, })
	ui_process_ops(box)
	return box
}

// creates a box that draws text that is
// attached to a value and is dynamic.
// uses fmt.tprint() to convert value to text

ui_value :: proc(key: string, value: any) -> Box_Ops {
	box := ui_create_box(key,{ .DISPLAYVALUE }, value)
	ui_process_ops(box)
	return box.ops	
}

ui_edit_value:: proc(key: string, ev: any) -> ^Box {
	box := ui_create_box(fmt.tprint("parent", key), {
		.CLICKABLE,
		.HOVERABLE,
		.DRAWBACKGROUND,
		.DRAWBORDER,
		.DRAWGRADIENT,
		.HOTANIMATION,
	})

	ui_push_parent(box)
	ui_process_ops(box)

	ui_size(.PCT_PARENT, 1, .PCT_PARENT, 1)
	text_box := ui_create_box(key, {
		.EDITVALUE,
		.CLIP,
	}, ev)

	is_editing := (text_box.key == state.ui.boxes.editing)	

	// NOTE editing-check
	if is_editing {
		excl(&box.flags, Box_Flags.HOTANIMATION)
		if box.ops.off_clicked || box.ops.right_clicked || esc() || enter() {
			end_editing_value(text_box)
		}
	// NOTE editing-check
	} else if box.ops.clicked && state.ui.boxes.editing == {} {
		start_editing_value(text_box)
	}

	ui_process_ops(text_box)
	ui_pop()
	return box
}

// creates single line editable text

ui_edit_text :: proc(key: string, es: ^String) -> Box_Ops {
	box := ui_create_box("editable_text", {
		.CLICKABLE,
		.HOVERABLE,
		.DRAWBACKGROUND,
		.DRAWBORDER,
		.DRAWGRADIENT,
		.VIEWSCROLL,
		.CLIP,
	})

	ui_push_parent(box)
	ui_process_ops(box)

	ui_size(.TEXT, 1, .PCT_PARENT, 1)
	text_box := ui_create_box("editable_text_box", {
		.EDITTEXT,
	})
	text_box.editable_string = es

	if box.ops.clicked {
		state.ui.boxes.editing = text_box.key
	} else if box.ops.off_clicked || box.ops.right_clicked {
		state.ui.boxes.editing = {}
	}

	ui_process_ops(text_box)

	ui_pop()

	if box.ops.middle_dragged {
		if box.ops.middle_clicked {
			state.input.mouse.delta_temp.x = state.input.mouse.pos.x - text_box.offset.x
		}
		text_box.scroll.x = state.input.mouse.pos.x - state.input.mouse.delta_temp.x
	}

	return box.ops
}


// ui_paragraph :: proc(value: any) -> Box_Ops {
// 	assert(value.id == Document)
// 	val := cast(^Document)value.data
	
// 	sbox := ui_scrollbox()
	
// 	width : f32 = 0
// 	last_space := 0
// 	start := 0

// 	if val.width != sbox.calc_size.x {
// 		val.width = sbox.calc_size.x
// 		val.lines = 0
// 		i : int = 0
// 		for i < len(val.mem) {
// 			char := val.mem[i]
// 			if char == ' ' do last_space = i
// 			return_break := (char == '\n')
// 			width_break := (width >= val.width-30)
// 			last_char := (i == len(val.mem)-1)
// 			if return_break || width_break || last_char {
// 				if width_break {
// 					if last_space > start do i = last_space+1
// 				}
// 				start = i
// 				val.lines += 1
// 				width = 0
// 			} else {
// 				width += state.ui.fonts.regular.char_data[rune(char)].advance
// 			}
// 			i += 1
// 		}
// 	}
	
// 	ui_size(.PIXELS, val.width, .PIXELS, (state.ui.line_space-4) * f32(val.lines+1))
// 	box := ui_create_box("paragraph", { .HOVERABLE, .DRAWPARAGRAPH }, value)
// 	ui_process_ops(box)

// 	val.current_line = clamp( (int( (-box.scroll.y / (box.calc_size.y)) * f32(val.lines+1) ) ), 0, val.lines)
// 	val.last_line = clamp( val.current_line + int(sbox.calc_size.y/(state.ui.line_space-4)), 0, val.lines)

// 	return box.ops
// }


// creates a slider for editing float values

ui_slider :: proc(label:string, value:^f32, min:f32=0, max:f32=1) -> Box_Ops {
	old_size := state.ui.ctx.size
	box := ui_create_box(label, {
		.CLICKABLE,
		.HOVERABLE,
		.DRAWBACKGROUND,
		.DRAWBORDER,
		.DRAWGRADIENT,
		.HOTANIMATION,
	}, any(value^))

	ui_process_ops(box)
	ui_push_parent(box)
	ui_size(.PCT_PARENT, value^, .PCT_PARENT, 1)
	highlight := ui_create_box("highlight", {
		.DRAWBACKGROUND,
		.DRAWGRADIENT,
		.ACTIVEANIMATION,
		.HOTANIMATION,
		.HOVERABLE,
		.CLICKABLE,
	})
	highlight.bg_color = state.ui.col.highlight
	ui_process_ops(highlight)
	
	ui_size(.PCT_PARENT, 1, .PCT_PARENT, 1)
	display_value := ui_create_box(fmt.tprint("disp val", label), {
		.EDITVALUE,
		.NO_OFFSET,
	}, value^)

	// NOTE editing-check
	if display_value.key == state.ui.boxes.editing {
		excl(&box.flags, Box_Flags.HOVERABLE)
		excl(&highlight.flags, Box_Flags.CLICKABLE)
		excl(&highlight.flags, Box_Flags.ACTIVEANIMATION)
		excl(&highlight.flags, Box_Flags.HOTANIMATION)
		excl(&highlight.flags, Box_Flags.HOVERABLE)
	}
	ui_process_ops(display_value)

	if box.ops.ctrl_clicked {
		start_editing_value(display_value)
	// NOTE editing-check
	} else if state.ui.boxes.editing == display_value.key {
		if box.ops.off_clicked || enter() {
			end_editing_value(display_value)
		} else if esc() {
			end_editing_value(display_value, false)
		}
	}

	// NOTE editing-check
	if display_value.key != state.ui.boxes.editing {
		if box.ops.clicked {
			state.input.mouse.delta_temp = state.input.mouse.pos - linear(value^, min, max, 0, box.calc_size.x)
		}

		if box.ops.pressed {
			value^ = clamp(linear(state.input.mouse.pos.x-state.input.mouse.delta_temp.x, 0, box.calc_size.x, min, max), min, max)
		}
	}

	ui_pop()
	state.ui.ctx.size = old_size
	return box.ops
}

// creates a button box

ui_button :: proc(key: string) -> Box_Ops {
	box := ui_create_box(key, {
		.CLICKABLE,
		.HOVERABLE,
		.DRAWTEXT,
		.DRAWBORDER,
		.DRAWBACKGROUND,
		.DRAWGRADIENT,
		.HOTANIMATION,
		.ACTIVEANIMATION,
	})
	ui_process_ops(box)
	box.text_align = .CENTER
	return box.ops
}

// creates a button without a border (for use in menus)

ui_menu_button :: proc(key: string) -> Box_Ops {
	box := ui_create_box(key, {
		.CLICKABLE,
		.HOVERABLE,
		.DRAWTEXT,
		.DRAWBACKGROUND,
		.DRAWGRADIENT,
		.HOTANIMATION,
	})
	ui_process_ops(box)
	box.text_align = .LEFT
	return box.ops
}

// creates a selectable box (for making dropdowns, checkboxes)

ui_dropdown :: proc(key: string) -> Box_Ops {
	box := ui_create_box(key, {
		.CLICKABLE,
		.SELECTABLE,
		.HOVERABLE,
		.DRAWTEXT,
		.DRAWBACKGROUND,
		.DRAWGRADIENT,
		.HOTANIMATION,
		.ACTIVEANIMATION,
	})
	ui_process_ops(box)
	if box.ops.selected {
		box.name = from_string(fmt.tprint("<#>s<r>", key))
	} else {
		box.name = from_string(fmt.tprint("<#>d<r>", key))
	}
	box.text_align = .LEFT
	return box.ops
}

// creates a radio button

ui_radio :: proc(key: string) -> ^Box {
	box := ui_create_box(key, {
		.CLICKABLE,
		.HOVERABLE,
		.DRAWTEXT,
		.DRAWBACKGROUND,
		.DRAWGRADIENT,
		.HOTANIMATION,
		.ACTIVEANIMATION,
	})
	ui_process_ops(box)
	return box
}

// creates a tab

ui_tab :: proc(names: []string, active:^int=nil) -> ([]^Box, int) {
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	tab := ui_empty()
	tabs := make([]^Box, len(names), context.temp_allocator)

	clicked := false
	index := 0
	if active != nil do index = active^

	for name, i in names {
		ui_axis(.X)
		ui_size(.SUM_CHILDREN, 1, .TEXT, 1)
		radio := ui_radio(fmt.tprint("###radio", i))
		ui_push_parent(radio)
			ui_size(.TEXT, 1, .TEXT, 1)
			label := ui_label(name)
			
			close := ui_button(fmt.tprint("<#>x###close", i))
			excl(&state.ui.ctx.box.flags, Box_Flags.DRAWBACKGROUND, Box_Flags.DRAWGRADIENT, Box_Flags.DRAWBORDER)

			if radio.ops.clicked {
				index = i
				clicked = true
			} else {
				radio.ops.selected = false
			}
			tabs[i] = radio
			if close.released do radio.ops.middle_clicked = true
		ui_pop()
	}

	if tab.first != nil {
		if state.ui.frame - tab.first.frame_created <= 10 {
			tab.first.ops.selected = true
		}
	}

	if clicked == false && index < len(tabs) {
		tabs[index].ops.selected = true
	}

	ui_pop()
	ui_bar(state.ui.col.active)

	if active != nil do active^ = index
	return tabs, index
}

// creates a spacer that fills up the .X axis, subtracting the sum of siblings from the parent size
// TODO make this work for the .Y axis
// parent must not rely solely on children for .X size

ui_spacer_fill :: proc() -> Box_Ops {
	oldsize := state.ui.ctx.size[X]
	ui_size_x(.MIN_SIBLINGS, 1)
	box := ui_create_box("spacer_fill", {
	})
	ui_process_ops(box)
	ui_size_x(oldsize.type, oldsize.value)
	return box.ops
}

// creates a spacer in the .X axis by pixels
// TODO make this work for the .Y axis

ui_spacer_pixels :: proc(pixels: f32, name:="spacer_pixels") -> Box_Ops {
	oldsize := state.ui.ctx.size.x
	ui_size_x(.PIXELS, pixels)
	box := ui_create_box(name, {})
	ui_process_ops(box)
	ui_size_x(oldsize.type, oldsize.value)
	return box.ops
}

// creates a box that will clip it's contents by it's height
// and offset the first child by x and y

ui_scrollbox :: proc(_x:bool=false, _y:bool=false) -> ^Box {
	scrollbox := ui_create_box("scrollbox", { })
	ui_process_ops(scrollbox)
	ui_push_parent(scrollbox)

	ui_axis(.X)
	ui_size(.NONE, 0, .NONE, 0)
	viewport := ui_create_box("viewport", { .CLIP, .VIEWSCROLL, .SCROLLBOX, .NO_OFFSET })
	ui_process_ops(viewport)

	ui_size(.NONE, 0, .NONE, 0)
	sby := ui_create_box("scrollbar_y", { .NO_OFFSET, .DRAWBACKGROUND })
	ui_process_ops(sby)
	// TODO sby.offset.x = viewport_width
	ui_push_parent(sby)

	ui_size(.NONE, 1, .NONE, 0)
	y_handle := ui_create_box("y_handle", { .DRAWGRADIENT, .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .ACTIVEANIMATION, .CLICKABLE } )
	ui_process_ops(y_handle)
	y_handle.bg_color = state.ui.col.inactive
	// TODO y_handle.offset.y = -handle_value.y 
	ui_pop()

	ui_size(.NONE, 0, .NONE, 0)
	sbx := ui_create_box("scrollbar_x", { .NO_OFFSET, .DRAWBACKGROUND })
	ui_process_ops(sbx)
	// sbx.offset.y = viewport_height
	ui_push_parent(sbx)

	ui_size(.NONE, 0, .NONE, 0)
	x_handle := ui_create_box("x_handle", { .DRAWGRADIENT, .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .CLICKABLE } )
	ui_process_ops(x_handle)
	x_handle.bg_color = state.ui.col.inactive
	// x_handle.offset.x = -handle_value.x
	ui_pop()

	ui_push_parent(viewport)
	return viewport
}

ui_scrollbox_old :: proc(_x:bool=false, _y:bool=false) -> ^Box {
	scrollbox := ui_create_box("scrollbox", { })
	ui_process_ops(scrollbox)
	ui_push_parent(scrollbox)

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

	ui_axis(.X)
	ui_size(.PIXELS, viewport_width, .PIXELS, viewport_height)
	viewport := ui_create_box("viewport", { .CLIP, .VIEWSCROLL  })
	ui_process_ops(viewport)

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
			ui_size(.PIXELS, bar_width, .PIXELS, viewport_height)
			sby := ui_create_box("scrollbar_y", { .NO_OFFSET, .DRAWBACKGROUND })
			ui_process_ops(sby)
			sby.offset.x = viewport_width
			ui_push_parent(sby)

			ui_size(.PCT_PARENT, 1, .PIXELS, db_size.y)
			y_handle := ui_create_box("y_handle", { .DRAWGRADIENT, .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .ACTIVEANIMATION, .CLICKABLE } )
			ui_process_ops(y_handle)
			y_handle.bg_color = state.ui.col.inactive
			y_handle.offset.y = -db_value.y
			ui_pop()

			if y_handle.ops.pressed {
				state.ui.panels.locked = true
				if y_handle.ops.clicked {
					state.input.mouse.delta_temp.y = state.input.mouse.pos.y * (scr_range.y/db_range.y) + viewport.first.offset.y
				}
				viewport.first.scroll.y = ((state.input.mouse.pos.y*(scr_range.y/db_range.y)) - state.input.mouse.delta_temp.y) * -1
			} else {
				state.ui.panels.locked = false
			}
		}
		if x {
			ui_size(.PIXELS, viewport_width, .PIXELS, bar_width)
			sbx := ui_create_box("scrollbar_x", { .NO_OFFSET, .DRAWBACKGROUND })
			ui_process_ops(sbx)
			sbx.offset.y = viewport_height
			ui_push_parent(sbx)

			ui_size(.PIXELS, db_size.x, .PCT_PARENT, 1)
			x_handle := ui_create_box("x_handle", { .DRAWGRADIENT, .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .CLICKABLE } )
			ui_process_ops(x_handle)
			x_handle.bg_color = state.ui.col.inactive
			x_handle.offset.x = -db_value.x
			ui_pop()

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

	ui_push_parent(viewport)
	return viewport
}

// add this at the end of an empty to be able to manually change the scale
// TODO only works in the .Y axis for right now

ui_sizebar_y :: proc() -> ^Box {
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .PIXELS, 4)
	box := ui_create_box("sizebar_y", { .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .CLICKABLE })
	ui_process_ops(box)
	if box.ops.pressed {
		if box.ops.clicked {
			state.input.mouse.delta_temp.y = state.input.mouse.pos.y - box.prev.expand.y
		}
		box.prev.expand.y = state.input.mouse.pos.y - state.input.mouse.delta_temp.y
	}
	if box.ops.hovering do cursor_size(box.axis)
	return box
}

ui_sizebar_x :: proc() -> ^Box {
	ui_axis(.X)
	ui_size(.PIXELS, 4, .PCT_PARENT, 1)
	box := ui_create_box("sizebar_y", { .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .CLICKABLE })
	ui_process_ops(box)
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

ui_drag_panel :: proc(label:string="") -> ^Box {
	box: ^Box
	if label == "" {
		box = ui_create_box("drag_panel", {
			.CLICKABLE,
			.HOVERABLE,
			.DRAGGABLE,
			.DRAWBACKGROUND,
		})
	} else {
		box = ui_create_box(label, {
			.CLICKABLE,
			.HOVERABLE,
			.DRAGGABLE,
			.DRAWBACKGROUND,
			.DRAWTEXT,
		})
	}
	ui_process_ops(box)
	return box
}