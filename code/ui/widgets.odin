package ui

import "core:fmt"

//______ BUILDER API ______//

ui_master_box :: proc(key: string, ctx: Quad) -> ^Box {
	box, box_ok := state.ui.boxes[key]
	if !box_ok {
		box = ui_generate_box(key)
	}
	box.last_frame_touched = state.ui.frame
	box.flags = { .MASTER }
	box.ctx = ctx
	box.size.x.value = ctx.r - ctx.l
	box.size.x.type = .PIXELS
	box.size.y.value = ctx.b - ctx.t
	box.size.y.type = .PIXELS
	box.offset = {ctx.l, ctx.t}
	box.calc_size = {box.size.x.value, box.size.y.value}
	box.border = 2
	box.border_color = {1,0,0,0.5}
	ui_push_parent(box)
	return box
}	

ui_push_parent :: proc(box: ^Box) {
	state.ui.box_parent = box
}

ui_pop_parent :: proc() {
	state.ui.box_parent = state.ui.box_parent.parent
}

ui_set_size_x :: proc(type: UI_Size_Type, value: f32) {
	state.ui.ctx.size.x.type = type
	state.ui.ctx.size.x.value = value
}

ui_set_size_y :: proc(type: UI_Size_Type, value: f32) {
	state.ui.ctx.size.y.type = type
	state.ui.ctx.size.y.value = value
}

ui_set_dir :: proc(direction: Direction) {
	state.ui.ctx.direction = direction
}

ui_set_border :: proc(color: v4) {
	state.ui.ctx.border_color = color
}


//______ WDIGETS ______//


ui_row :: proc() -> ^Box {
	state.ui.box_index += 1 // TODO is this a good idea?
	box := ui_create_box(fmt.tprintf("row_%v", state.ui.box_index), state.ui.box_parent, {
		// .DRAWBORDER,
	})
	return box
}

ui_label :: proc(key: string) -> Box_Ops {
	box := ui_create_box(key, state.ui.box_parent, {
		.DRAWTEXT,
	})
	return box.ops
}

ui_button :: proc(key: string) -> Box_Ops {
	box := ui_create_box(key, state.ui.box_parent, {
		.CLICKABLE,
		.HOVERABLE,
		.DRAWTEXT,
		.DRAWBORDER,
		.DRAWBACKGROUND,
		.DRAWGRADIENT,
	})
	return box.ops
}