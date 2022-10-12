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
	state.ui.ctx.render_layer = 0
	state.ui.ctx.box = nil
	state.ui.ctx.parent = nil
	quad := state.ui.ctx.panel.quad
	ui_size(.PIXELS, quad.r - quad.l, .PIXELS, quad.b - quad.t)
	box := ui_create_box("root", { .ROOT, .CLIP })
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
	state.ui.ctx.render_layer = 1
	state.ui.ctx.box = nil
	state.ui.ctx.parent = nil
	ui_size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
	box := ui_create_box("root_floating", flags)
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

// NOTE render layers are currently only used to keep floating panels on top

ui_set_render_layer 	:: proc(layer: int) 	{ state.ui.ctx.render_layer = layer }

// sets the border color

ui_set_border_color 	:: proc(color: HSL) 		{ state.ui.ctx.border_color = color }

// sets the border thickness

ui_set_border_thickness :: proc(value: f32)		{ state.ui.ctx.border = value }

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

	if color != {} do bar.bg_color = color

	return bar
}

// draws a color filled box

ui_color :: proc(color:HSL) -> ^Box {
	box := ui_create_box("editable_text", {
		.DRAWBACKGROUND,
		.DRAWBORDER,
	})
	box.bg_color = color
	return box
}


// creates a box that draws static text
// don't use this for values that change

ui_label :: proc(key: string) -> Box_Ops {
	box := ui_create_box(key, { .DRAWTEXT, })
	return box.ops
}

// creates a box that draws text that is
// attached to a value and is dynamic.
// uses fmt.tprintf() to convert value to text

ui_value :: proc(key: string, value: any) -> Box_Ops {
	box := ui_create_box(key,{ .DISPLAYVALUE }, value)
	return box.ops	
}

// creates single line editable text

ui_edit_text :: proc(editable: ^String) -> Box_Ops {
	box := ui_create_box("editable_text", {
		.CLICKABLE,
		.HOVERABLE,
		.EDITTEXT,
		.DRAWBACKGROUND,
		.DRAWBORDER,
		.DRAWGRADIENT,
	})
	box.editable_string = editable
	return box.ops
}

ui_paragraph :: proc(value: any) -> Box_Ops {
	assert(value.id == V_String)
	val := cast(^V_String)value.data
	
	sbox := ui_scrollbox()



	if val.width != sbox.calc_size.x {
		val.width = sbox.calc_size.x
		val.lines = 1
		width : f32 = 0
		last_space := 0
		for char, index in val.mem {
			if char == ' ' do last_space = index
			if char == '\n' {
				val.lines += 1
			} else {
				width += state.ui.fonts.regular.char_data[rune(char)].advance
			}
		}
	}


	ui_size(.PIXELS, val.width, .PIXELS, (state.ui.line_space-4) * f32(val.lines))
	box := ui_create_box("paragraph", { .HOVERABLE, .DRAWPARAGRAPH, .DEBUG }, value)

	val.index = clamp( (int( (-box.scroll.y / box.calc_size.y) * f32(val.len) ) ), 0, val.len)

	return box.ops
}


// creates a slider for editing float values

ui_slider :: proc(label:string, value:^f32) -> Box_Ops {
	old_size := state.ui.ctx.size
	box := ui_create_box(label, {
		.CLICKABLE,
		.HOVERABLE,
		.DRAWBACKGROUND,
		.DRAWBORDER,
		.DRAWGRADIENT,
		.HOTANIMATION,
		// .ACTIVEANIMATION,
	}, any(value))

	if box.ops.clicked {
		state.mouse.delta_temp = state.mouse.pos - linear(value^, 0, 1, 0, box.calc_size.x)
	}

	if box.ops.pressed {
		value^ = clamp(linear(state.mouse.pos.x-state.mouse.delta_temp.x, 0, box.calc_size.x, 0, 1), 0, 1)
	}
	
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
	
	ui_size(.PCT_PARENT, 1, .PCT_PARENT, 1)
	display_value := ui_create_box("", {
		.NO_OFFSET,
		.DISPLAYVALUE,
	}, value^)
	
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
	if box.ops.selected {
		box.name = from_string(fmt.tprintf("<#>s<r> %v", key))
	} else {
		box.name = from_string(fmt.tprintf("<#>d<r> %v", key))
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
	return box
}

// creates a tab

ui_tab :: proc(names: []string) -> (^Box, ^Box) {
	ui_size(.PCT_PARENT, 1, .TEXT, 1)
	tab := ui_empty()
	ui_axis(.X)
	ui_size(.TEXT, 1, .TEXT, 1)
	selected : ^Box
	clicked := false
	for name in names {
		radio := ui_radio(name)
		if radio.ops.clicked {
			selected = radio
			clicked = true
		}
	}
	if tab.first != nil {
		if state.ui.frame - tab.first.frame_created <= 10 {
			selected = tab.first
			selected.ops.selected = true
		}
	}

	if clicked {
		for child := tab.first; child != nil; child = child.next {
			child.ops.selected = string(child.name.mem[:child.name.len]) == string(selected.name.mem[:selected.name.len])
		}
	}

	ui_pop()
	ui_bar(state.ui.col.active)
	for child := tab.first; child != nil; child = child.next {
		if child.ops.selected do return tab, child
	}
	return tab, selected
}

// creates a spacer that fills up the .X axis, subtracting the sum of siblings from the parent size
// TODO make this work for the .Y axis
// parent must not rely solely on children for .X size

ui_spacer_fill :: proc() -> Box_Ops {
	oldsize := state.ui.ctx.size[X]
	ui_size_x(.MIN_SIBLINGS, 1)
	box := ui_create_box("spacer_fill", {
	})
	ui_size_x(oldsize.type, oldsize.value)
	return box.ops
}

// creates a spacer in the .X axis by pixels
// TODO make this work for the .Y axis

ui_spacer_pixels :: proc(pixels: f32) -> Box_Ops {
	oldsize := state.ui.ctx.size.x
	ui_size_x(.PIXELS, pixels)
	box := ui_create_box("spacer_pixels", {
	})
	ui_size_x(oldsize.type, oldsize.value)
	return box.ops
}

// creates a box that will clip it's contents by it's height
// and offset the first child by x and y

ui_scrollbox :: proc(_x:bool=false, _y:bool=false) -> ^Box {
	scrollbox := ui_create_box("scrollbox", { })
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
	viewport := ui_create_box("viewport", { .CLIP, .VIEWSCROLL })

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
			sby.offset.x = viewport_width
			ui_push_parent(sby)

			ui_size(.PCT_PARENT, 1, .PIXELS, db_size.y)
			y_handle := ui_create_box("y_handle", { .DRAWGRADIENT, .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .CLICKABLE } )
			y_handle.bg_color = state.ui.col.inactive
			y_handle.offset.y = -db_value.y
			ui_pop()

			if y_handle.ops.pressed {
				if y_handle.ops.clicked {
					state.mouse.delta_temp.y = state.mouse.pos.y * (scr_range.y/db_range.y) + viewport.first.offset.y
				}
				viewport.first.scroll.y = ((state.mouse.pos.y*(scr_range.y/db_range.y)) - state.mouse.delta_temp.y) * -1
			}
		}
		if x {
			ui_size(.PIXELS, viewport_width, .PIXELS, bar_width)
			sbx := ui_create_box("scrollbar_x", { .NO_OFFSET, .DRAWBACKGROUND })
			sbx.offset.y = viewport_height
			ui_push_parent(sbx)

			ui_size(.PIXELS, db_size.x, .PCT_PARENT, 1)
			x_handle := ui_create_box("x_handle", { .DRAWGRADIENT, .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .CLICKABLE } )
			x_handle.bg_color = state.ui.col.inactive
			x_handle.offset.x = -db_value.x
			ui_pop()

			if x_handle.ops.pressed {
				if x_handle.ops.clicked {
					state.mouse.delta_temp.x = state.mouse.pos.x * (scr_range.x/db_range.x) + viewport.first.offset.x
				}
				viewport.first.scroll.x = ((state.mouse.pos.x*(scr_range.x/db_range.x)) - state.mouse.delta_temp.x) * -1
			}
		}

		if viewport.ops.middle_dragged {
			if viewport.ops.middle_clicked {
				state.mouse.delta_temp = state.mouse.pos - viewport.first.offset
			}
			viewport.first.scroll = state.mouse.pos - state.mouse.delta_temp
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
	if box.ops.pressed {
		box.parent.expand.y += f32(state.mouse.delta.y)
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
	return box
}

