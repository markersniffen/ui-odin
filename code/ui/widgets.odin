package ui

import "core:fmt"
import "core:mem"


//______ BUILDER API ______//

//
// start each panel with:
//   ui_begin()
// this creates a root box and set's it to the context parent

ui_begin :: proc() -> ^Panel {
	state.ui.ctx.render_layer = 0
	state.ui.ctx.box = nil
	state.ui.ctx.parent = nil
	quad := state.ui.ctx.panel.quad
	ui_size(.PIXELS, quad.r - quad.l, .PIXELS, quad.b - quad.t)
	box := ui_create_box("root", { .ROOT, .CLIP })
	box.offset = {quad.l, quad.t}
	state.ui.ctx.panel.box = box
	ui_push_parent(box)
	ui_size(.PCT_PARENT, 1, .PCT_PARENT, 1)
	return state.ui.ctx.panel
}

// use
//   ui_begin_floating()
// at the beginning of floating panels instead of ui_begin()
//
ui_begin_floating :: proc() -> ^Panel {
	state.ui.ctx.render_layer = 1
	state.ui.ctx.box = nil
	state.ui.ctx.parent = nil
	ui_size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
	box := ui_create_box("root_floating", { .ROOT, .DRAWBACKGROUND, .FLOATING })
	state.ui.ctx.panel.box = box
	ui_push_parent(box)
	return state.ui.ctx.panel
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

ui_set_border_color 	:: proc(color: v4) 		{ state.ui.ctx.border_color = color }

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

// creates a box that draws static text
// don't use this for values that change

ui_label :: proc(key: string) -> Box_Ops {
	box := ui_create_box(key, { .DRAWTEXT, })
	return box.ops
}

// creates a box that draws text that is attached to a value
// and is dynamic
// uses fmt.tprintf() to convert value to text

ui_value :: proc(key: string, value: any) -> Box_Ops {
	box := ui_create_box(key,{ .DISPLAYVALUE }, value)
	return box.ops	
}

// creates single line editable text

ui_edit_text :: proc(editable: ^Editable_String) -> Box_Ops {
	box := ui_create_box("editable_text", {
		.CLICKABLE,
		.HOVERABLE,
		.EDITTEXT,
		.DRAWBACKGROUND,
		.DRAWBORDER,
		.DRAWGRADIENT,
		.HOTANIMATION,
		.ACTIVEANIMATION,
	})
	box.editable_string = editable
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

// creates a selectable box

ui_selectable :: proc(key: string) -> Box_Ops {
	box := ui_create_box(key, {
		.CLICKABLE,
		.SELECTABLE,
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
// and scroll when the scroll wheel is used

ui_scrollbox :: proc() -> ^Box {
	empty := ui_create_box("scrollbox", { .DRAWBORDER })
	ui_push_parent(empty)
	ui_axis(.X)
	ui_size(.MIN_SIBLINGS, 1, .PCT_PARENT, 1)
	viewport := ui_create_box("viewport", { .VIEWSCROLL, .CLIP })
	ui_push_parent(viewport)
	ui_axis(.Y)
	return viewport
}

// add at the end of of a scrollbox to add a draggable bar to scroll with

ui_scrollbar :: proc() -> ^Box {
	viewport := state.ui.ctx.parent.first
	dragbar_height := ((viewport.calc_size.y + viewport.expand.y) / viewport.sum_children.y) * (viewport.calc_size.y + viewport.expand.y)

	if viewport.calc_size.y > dragbar_height {
		ui_size(.PIXELS, 12, .PCT_PARENT, 1)
	} else {
		ui_size(.PIXELS, 0, .PCT_PARENT, 1)
	}
	
	dragbar := ui_create_box("scrollbar", { .DRAWBORDER, .CLIP } )
	ui_push_parent(dragbar)
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .PIXELS, min(dragbar_height, viewport.calc_size.y))
	handle := ui_create_box("handle", { .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .CLICKABLE } )

	dragbar_range := (viewport.calc_size.y + viewport.expand.y) - dragbar_height
	scroll_range := viewport.sum_children.y - (viewport.calc_size.y + viewport.expand.y)
	scroll_value := viewport.first.offset.y
	multiplier := scroll_value / scroll_range
	dragbar_value := dragbar_range * multiplier
	handle.offset.y = -dragbar_value

	handle.bg_color = state.ui.col.highlight
	if handle.ops.pressed {
		if handle.ops.clicked {
			state.mouse.delta_temp.y = (f32(state.mouse.pos.y) * (scroll_range/dragbar_range)) + viewport.first.offset.y
		}
		viewport.first.scroll.y = ((f32(state.mouse.pos.y)*(scroll_range/dragbar_range)) - state.mouse.delta_temp.y) * -1
	}
	return dragbar
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
// TODO might be used for draggable boxes with boxes at some point?

ui_drag_panel :: proc(label:string="") -> ^Box {
	box: ^Box
	if label == "" {
		box = ui_create_box("drag_panel", {
			.CLICKABLE,
			.SELECTABLE,
			.HOVERABLE,
			.DRAGGABLE,
			.DRAWBACKGROUND,
		})
	} else {
		box = ui_create_box(label, {
			.CLICKABLE,
			.SELECTABLE,
			.HOVERABLE,
			.DRAGGABLE,
			.DRAWBACKGROUND,
			.DRAWTEXT,
		})
	}
	return box
}