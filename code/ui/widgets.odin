package ui

import "core:fmt"

//______ BUILDER API ______//

ui_master_box :: proc(key: string) -> ^Box {
	box, box_ok := state.ui.boxes[key]
	if !box_ok {
		box = ui_generate_box(key)
	}
	box.last_frame_touched = state.ui.frame
	box.flags = { .MASTER }
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
	state.ui.stack.size.x.type = type
	state.ui.stack.size.x.value = value
}

ui_set_size_y :: proc(type: UI_Size_Type, value: f32) {
	state.ui.stack.size.y.type = type
	state.ui.stack.size.y.value = value
}


//______ WDIGETS ______//


ui_row :: proc() -> ^Box {
	state.ui.box_index += 1 // TODO is this a good idea?
	box := ui_create_box(fmt.tprintf("row_%v", state.ui.box_index), state.ui.box_parent, {})
	return box
}

ui_text :: proc(key: string) -> Box_Ops {
	box := ui_create_box(key, state.ui.box_parent, { .DRAWTEXT })
	return box.ops
}

ui_button :: proc(key: string) -> Box_Ops {
	box := ui_create_box(key, state.ui.box_parent, {
		.CLICKABLE,
		.DRAWTEXT,
		.DRAWBACKGROUND,
		.DRAWBORDER,
	})
	return box.ops
}