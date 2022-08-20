package ui

import "core:fmt"

MAX_ELEMENTS :: 4096

Box :: struct {
	key: string,

	parent: ^Box,
	first: ^Box,
	next: ^Box,
	last: ^Box,

	hash_next: ^Box,
	hash_prev: ^Box,

	last_frame_touched: u64,
}

ui_generate_box :: proc(key: string) -> ^Box {
	box := cast(^Box)pool_alloc(&state.ui.box_pool)
	box.key = key
	assert(!(key in state.ui.boxes))
	state.ui.boxes[key] = box
	return box
}

ui_create_box :: proc(key: string, parent: ^Box) -> ^Box {
	box, box_ok := state.ui.boxes[key]
	// if box doesn't exist, create it
	if !box_ok {
		box = ui_generate_box(key)
		box.parent = parent
		parent.last = box

		if parent.first == nil {
			parent.first = box
			parent.next = nil
		} else if parent.next == nil {
			parent.next = box	
		} else { // if parent.next != nill
			child := parent.next
			for {
				if child.next == nil do break
				child.next = child
			}
			child.next = box
		}
	}


	box.last_frame_touched = state.ui.frame
	return(box)
}

ui_master_box :: proc(key: string) -> ^Box {
	box, box_ok := state.ui.boxes[key]
	if !box_ok {
		box = ui_generate_box(key)
	}
	ui_push_parent(box)
	return box
}

ui_row :: proc() -> ^Box {
	state.ui.box_index += 1
	fmt.println("creating row", state.ui.box_index)
	box := ui_create_box(fmt.tprintf("row_%v", state.ui.box_index), state.ui.box_parent)
	return box
}

ui_button :: proc(key: string) -> ^Box {
	return ui_create_box(key, state.ui.box_parent)
}

ui_push_parent :: proc(box: ^Box) {
	state.ui.box_parent = box
}

ui_pop_parent :: proc() {
	state.ui.box_parent = state.ui.box_parent.parent
}