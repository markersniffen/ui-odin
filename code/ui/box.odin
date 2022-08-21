package ui

import "core:fmt"

MAX_ELEMENTS :: 4096

Box :: struct {
	key: string,

	parent: ^Box,	// parent
	first: ^Box,	// first child
	last: ^Box,		// last child
	next: ^Box,		// next sibling
	prev: ^Box,		// prev sibling

	hash_next: ^Box,
	hash_prev: ^Box,

	last_frame_touched: u64,

	flags: bit_set[Box_Flags],
	ops: Box_Ops,
}

Box_Flags :: enum {
	MASTER,
	CLICKABLE,
	SELECTABLE,
	VIEWSCROLL,
	DRAWTEXT,
	DRAWBORDER,
	DRAWBACKGROUND,
	CLIP,
	HOTANIMATION,
	ACTIVEANIMATION,
}

Box_Ops :: struct {
  clicked: bool,
  double_clicked: bool,
  right_clicked: bool,
  pressed: bool,
  released: bool,
  dragging: bool,
  hovering: bool,
}

ui_generate_box :: proc(key: string) -> ^Box {
	box := cast(^Box)pool_alloc(&state.ui.box_pool)
	box.key = key
	assert(!(key in state.ui.boxes))
	state.ui.boxes[key] = box
	return box
}

ui_create_box :: proc(key: string, parent: ^Box, flags:bit_set[Box_Flags]={}) -> ^Box {
	box, box_ok := state.ui.boxes[key]
	// if box doesn't exist, create it
	if !box_ok {
		box = ui_generate_box(key)
		box.parent = parent

		// try adding as first child first
		if parent.first == nil {
			parent.first = box
			box.prev = nil
		} else if parent.first != nil {
			parent.last.next = box
			box.prev = parent.last
		}
		parent.last = box
		box.next = nil
	}

	box.flags = flags
	ui_ops(box)

	box.last_frame_touched = state.ui.frame
	return(box)
}

ui_delete_box :: proc(box: ^Box) {
	if box.parent.first == box && box.parent.last == box {
		box.parent.first = nil
		box.parent.last = nil
	}
	else if box.parent.first == box && box.parent.last != box
	{
		box.parent.first = box.next
		box.parent.first.prev = nil
	}
	else if box.parent.first != box && box.parent.last == box
	{
		box.prev.next = nil
		box.parent.last = box.prev
	}
	else if box.parent.first != box && box.parent.last != box
	{
		box.prev.next = box.next
		box.next.prev = box.prev
	}

	delete_key(&state.ui.boxes, box.key)
	pool_free(&state.ui.box_pool, box)
}

ui_ops :: proc(box: ^Box) {
	ops := box.ops
	fmt.println("operating on box:", )

	if ops.clicked {
		fmt.println("Clicked!")
	}

	if ops.double_clicked {
		fmt.println("double clicked!")
	}

	if ops.right_clicked {
		fmt.println("right clicked!")
	}

}

// BUILDER CODE THAT MAKES BOXES
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
	box := ui_create_box(key, state.ui.box_parent, { .CLICKABLE, .DRAWTEXT, .DRAWBACKGROUND, .DRAWBORDER })
	return box.ops
}

ui_push_parent :: proc(box: ^Box) {
	state.ui.box_parent = box
}

ui_pop_parent :: proc() {
	state.ui.box_parent = state.ui.box_parent.parent
}