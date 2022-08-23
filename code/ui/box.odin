package ui

import "core:fmt"

MAX_BOXES :: 4096

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

	bg_color: v4,
	border_color: v4,
	border: f32,
	size: [XY]UI_Size,
	direction: Direction,
	calc_size: v2,
	offset: v2,		// from parent
	ctx: Quad,
}

Box_Flags :: enum {
	MASTER,

	CLICKABLE,
	HOVERABLE,
	SELECTABLE,
	VIEWSCROLL,

	DRAWTEXT,
	DRAWBORDER,
	DRAWBACKGROUND,
	DRAWGRADIENT,
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

		box.size = state.ui.ctx.size
		box.direction = state.ui.ctx.direction
		box.bg_color = state.ui.ctx.bg_color
		box.border_color = state.ui.ctx.border_color
		box.border = state.ui.ctx.border

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

	// PROCESS OPS ------------------------------
	if mouse_in_quad(box.ctx) {
		if .CLICKABLE in box.flags {
			box.ops.clicked = read_mouse(&state.mouse.left, .RELEASE)
		}

		if .HOVERABLE in box.flags && !box.ops.clicked {
			box.ops.hovering = true
		}
	} else {
		box.ops.hovering = false
	}

	box.last_frame_touched = state.ui.frame
	return(box)
}

ui_calc_boxes :: proc() {
	// PIXEL SIZE ------------------------------
	for _, box in state.ui.boxes {
		// for each axis (x/y) ------------------------------
		for size, index in box.size {
			calc_size := &box.calc_size[index]
			#partial switch size.type {
				case .PIXELS:
				calc_size^ = size.value
				case .TEXT_CONTENT:
				if index == X {
					calc_size^ = ui_text_size(X, box.key) + (state.ui.margin*2)
				} else if index == Y {
					calc_size^ = ui_text_size(Y, box.key)
				}
			}
		}
	}	
	// PARENT SIZE ------------------------------
	for _, box in state.ui.boxes {
		// for each axis (x/y) ------------------------------
		for size, index in box.size {
			calc_size := &box.calc_size[index]
			
			if size.type == .PERCENT_PARENT {
				psize := box.parent.calc_size[index]
				calc_size^ = psize * size.value
			}
		}
	}
	// RELATIVE POSITION & QUAD ----------------------
	for _, box in state.ui.boxes {
		switch box.direction {
			case .HORIZONTAL:
				if box.prev == nil {
					box.offset.x = 0
				} else {
					new_calc_size : f32
					for prev := box.prev; prev != nil; prev = prev.prev {
						new_calc_size += prev.calc_size.x
					} 
					box.offset.x = new_calc_size
				}
				if box.parent != nil do box.offset.y = 0 //box.parent.ctx.t
			case .VERTICAL:
				if box.parent != nil do box.offset.x = 0 //box.parent.ctx.l
				if box.prev == nil {
					box.offset.y = 0
				} else {
					new_calc_size: f32
					for prev := box.prev; prev != nil; prev = prev.prev {
						new_calc_size += prev.calc_size.y
					}
					box.offset.y = new_calc_size
				}
		}
	}
}

ui_delete_box :: proc(box: ^Box) {
	if box.parent != nil {
		if box.parent.first == box && box.parent.last == box {
			box.parent.first = nil
			box.parent.last = nil
		}
		else if box.parent.first == box && box.parent.last != box
		{
			if box.next != nil do box.parent.first = box.next
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
	} else {
		if box.prev != nil && box.next != nil {
			box.prev.next = box.next
			box.next.prev = box.prev
		} else if box.prev != nil && box.next == nil {
			box.prev.next = nil
		} else if box.prev == nil && box. next != nil {
			box.next.prev = nil
		}
	}

	delete_key(&state.ui.boxes, box.key)
	pool_free(&state.ui.box_pool, box)
}

