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
	state.ui.box_active_building = box
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

ui_set_border_color :: proc(color: v4) {
	state.ui.ctx.border_color = color
}

ui_set_border_thickness :: proc(value: f32) {
	state.ui.ctx.border = value
}

//______ WDIGETS ______//

ui_empty :: proc(direction: Direction) -> ^Box {
	state.ui.box_index += 1 // TODO is this a good idea?
	oldsize := state.ui.ctx.size[X]
	name: string
	if direction == .HORIZONTAL {
		ui_set_dir(.VERTICAL)
		ui_set_size_x(.PERCENT_PARENT, 1)
		ui_set_size_y(.PIXELS, state.ui.line_space)
		name = "row"
	} else if direction == .VERTICAL {
		ui_set_dir(.HORIZONTAL)
		ui_set_size_x(.PERCENT_PARENT, 1)
		ui_set_size_y(.CHILDREN_SUM, 1)
		name = "col"
	}
	box := ui_create_box(fmt.tprintf("%v_%v", name, state.ui.box_index), {.DRAWBORDER})
	ui_push_parent(box)
	ui_set_dir(direction)
	state.ui.ctx.size = oldsize
	return box
}

ui_row :: proc() -> ^Box {
	return ui_empty(.HORIZONTAL)
}

ui_col :: proc() -> ^Box {
	return ui_empty(.VERTICAL)
}

ui_end_row :: proc() do ui_pop_parent()
ui_end_col :: proc() do ui_pop_parent()

ui_label :: proc(key: string) -> Box_Ops {
	box := ui_create_box(key,{
		.DRAWTEXT,
	})
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
	})
	return box.ops
}

ui_spacer_fill :: proc() -> Box_Ops {
	state.ui.box_index += 1 // TODO is this a good idea?
	oldsize := state.ui.ctx.size[X]
	ui_set_size_x(.MIN_SIBLINGS, 1)
	box := ui_create_box(fmt.tprintf("space_%v", state.ui.box_index), {
	})
	ui_set_size_x(oldsize.type, oldsize.value)
	return box.ops
}