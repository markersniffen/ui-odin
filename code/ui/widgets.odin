package ui

import "core:fmt"

//______ BUILDER API ______//

ui_root_box :: proc() -> ^Box {

	key := ui_gen_key("root")
	ctx := state.ui.ctx.panel.ctx
	box, box_ok := state.ui.boxes[key]
	if !box_ok {
		box = ui_generate_box("root")
	}
	box.flags = { .ROOT }
	box.last_frame_touched = state.ui.frame
	box.ctx = ctx
	box.size.x.value = ctx.r - ctx.l
	box.size.x.type = .PIXELS
	box.size.y.value = ctx.b - ctx.t
	box.size.y.type = .PIXELS
	box.offset = {ctx.l, ctx.t}
	box.calc_size = {box.size.x.value, box.size.y.value}
	box.border = 2
	box.border_color = {1,0,0,0.5}
	state.ui.ctx.panel.box = box
	box.hash_prev = nil
	box.hash_next = nil
	state.ui.ctx.box = box
	ui_push_parent(box)
	ui_size(.PERCENT_PARENT, 1, .PERCENT_PARENT, 1)
	return box
}	

ui_push_parent :: proc(box: ^Box) {
	state.ui.ctx.box_parent = box
}

ui_pop_parent :: proc() {
	state.ui.ctx.box_parent = state.ui.ctx.box_parent.parent
}

ui_pop :: proc() { ui_pop_parent() }
ui_end_row :: proc() { ui_pop_parent() }
ui_end_col :: proc() { ui_pop_parent() }

ui_size :: proc (x_type: UI_Size_Type, x_value: f32, y_type: UI_Size_Type, y_value: f32) {
	ui_size_x(x_type, x_value)
	ui_size_y(y_type, y_value)
}

ui_size_x :: proc(type: UI_Size_Type, value: f32) {
	state.ui.ctx.size.x.type = type
	state.ui.ctx.size.x.value = value
}

ui_size_y :: proc(type: UI_Size_Type, value: f32) {
	state.ui.ctx.size.y.type = type
	state.ui.ctx.size.y.value = value
}

ui_axis :: proc(axis: Axis) {
	state.ui.ctx.axis = axis
}

ui_set_border_color :: proc(color: v4) {
	state.ui.ctx.border_color = color
}

ui_set_border_thickness :: proc(value: f32) {
	state.ui.ctx.border = value
}

//______ WDIGETS ______//

ui_empty :: proc(axis: Axis) -> ^Box {
	state.ui.box_index += 1 // TODO is this a good idea?
	oldsize := state.ui.ctx.size[X]
	name: string
	ui_axis(.Y)
	if axis == .X {
		ui_size_x(.PERCENT_PARENT, 1)
		ui_size_y(.PIXELS, state.ui.line_space)
		name = "row"
	} else if axis == .X {
		// ui_axis(.HORIZONTAL)
		ui_size_x(.CHILDREN_SUM, 1)
		ui_size_y(.CHILDREN_SUM, 1)
		name = "col"
	}
	box := ui_create_box(fmt.tprintf("%v_%v", name, state.ui.box_index), {.DRAWBORDER})
	ui_push_parent(box)
	ui_axis(axis)
	state.ui.ctx.size = oldsize
	return box
}

ui_layout :: proc(
		axis: 		Axis,
		x: 			UI_Size_Type	=	.PERCENT_PARENT,
		x_value: 	f32				=	1,
		y: 			UI_Size_Type	=	.PERCENT_PARENT,
		y_value: 	f32				=	1,
	) -> ^Box {

	ui_axis(axis)
	ui_size(x, x_value, y, y_value)

	state.ui.box_index += 1 // TODO is this a good idea?
	box := ui_create_box(fmt.tprintf("layout_%v", state.ui.box_index), {})
	ui_push_parent(box)
	return box
}


ui_row :: proc() {
	ui_layout(.Y, .PERCENT_PARENT, 1, .CHILDREN_SUM, 1)
	ui_axis(.X)
	ui_size(.TEXT_CONTENT, 1, .TEXT_CONTENT, 1)
	// return ui_empty(.X)
}

ui_col :: proc(x: UI_Size_Type=.PERCENT_PARENT, x_value:f32=1) {
	ui_layout(.X, x, x_value, .CHILDREN_SUM, 1)
	ui_axis(.Y)
	ui_size(.PERCENT_PARENT, 1, .TEXT_CONTENT, 1)
	// return ui_empty(.Y)
}


ui_label :: proc(key: string) -> Box_Ops {
	box := ui_create_box(key,{
		.DRAWTEXT,
	})
	return box.ops
}

ui_value :: proc(key: string, value: any) -> Box_Ops {
	box := ui_create_box(key,{ .DISPLAYVALUE }, value)
	return box.ops	
}

ui_button_value :: proc(key: string, value: any) -> Box_Ops {
	box := ui_create_box(key, {
		.CLICKABLE,
		.HOVERABLE,
		.DISPLAYVALUE,
		.DRAWBORDER,
		.DRAWBACKGROUND,
		.DRAWGRADIENT,
		.HOTANIMATION,
	}, value)
	box.text_align = .CENTER
	return box.ops
}

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

ui_dropdown :: proc(key: string) -> Box_Ops {
	box := ui_create_box(key, {
		.HOVERABLE,
		.CLICKABLE,
		.SELECTABLE,
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

ui_menu :: proc() -> Box_Ops {
	ui_size(.PIXELS, 0, .PIXELS, 0)
	box := ui_create_box(fmt.tprintf("%v Menu", state.ui.ctx.box_parent.name), { .MENU })
	state.ui.ctx.panel.menu_box = box
	ui_push_parent(box)
	return box.ops
}

ui_spacer_fill :: proc() -> Box_Ops {
	state.ui.box_index += 1 // TODO is this a good idea?
	oldsize := state.ui.ctx.size[X]
	ui_size_x(.MIN_SIBLINGS, 1)
	box := ui_create_box(fmt.tprintf("space_%v", state.ui.box_index), {
	})
	ui_size_x(oldsize.type, oldsize.value)
	return box.ops
}