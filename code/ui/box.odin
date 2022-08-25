package ui

import "core:fmt"

MAX_BOXES :: 4096

Box :: struct {
	key: string,
	name: string,

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
	text_align: Text_Align,

	size: [XY]UI_Size,
	// direction: Direction,
	axis: Axis,
	calc_size: v2,
	offset: v2,		// from parent
	ctx: Quad,
}

Box_Flags :: enum {
	ROOT,

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

ui_split_key :: proc(key: string) -> string {
	a, b: string
	for letter, index in key {
		if letter == '#' {
			a = key[:index]
			b = key[index:]
			break
		}
	}
	fmt.println("KEYGEN", a, b)
	return a
}

ui_gen_key :: proc(key: string="") -> string {
	if key != "" {
		return fmt.tprintf("%v_%v", key, state.ui.ctx.panel.uid)
	} else {
		return fmt.tprintf("Box%v_Panel%v", key, state.ui.ctx.panel.uid)
	}
}

ui_generate_box :: proc(key: string) -> ^Box {
	box := cast(^Box)pool_alloc(&state.ui.box_pool)
	box.key = ui_gen_key(key)
	box.name = key
	assert(!(box.key in state.ui.boxes))
	state.ui.boxes[box.key] = box
	return box
}

ui_create_box :: proc(_key: string, flags:bit_set[Box_Flags]={}) -> ^Box {
	key := ui_gen_key(_key)
	box, box_ok := state.ui.boxes[key]
	parent := state.ui.ctx.box_parent
	
	// if box doesn't exist, create it
	if !box_ok {
		box = ui_generate_box(_key)
		box.parent = parent

		box.size = state.ui.ctx.size
		// box.direction = state.ui.ctx.direction
		box.axis = state.ui.ctx.axis
		box.bg_color = state.ui.ctx.bg_color
		box.border_color = state.ui.ctx.border_color
		box.border = state.ui.ctx.border
		box.text_align = state.ui.ctx.text_align

		// try adding as first child first
		if parent.first == nil {
			parent.first = box
			box.prev = nil
		} else if parent.first != nil {
			assert(parent.last != nil)
			parent.last.next = box
			box.prev = parent.last
		}
		parent.last = box
		box.next = nil
	}

	// ADD BOX TO LINKED LIST ------------------------------
	box.hash_prev = state.ui.ctx.box
	state.ui.ctx.box.hash_next = box
	state.ui.ctx.box = box
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
					calc_size^ = ui_text_size(X, box.name) + (state.ui.margin*2)
				} else if index == Y {
					calc_size^ = ui_text_size(Y, box.name)
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
	// RELATIVE TO SIBLINGS ------------------------------
	for _, box in state.ui.boxes {
		// for each axis (x/y) ------------------------------
		for size, index in box.size {
			calc_size := &box.calc_size[index]

			if size.type == .MIN_SIBLINGS
			{
				calc_size^ = 0
				for prev:= box.prev; prev != nil; prev = prev.prev {
					calc_size^ += prev.calc_size[index]
				}

				for next:= box.next; next != nil; next = next.next {
					calc_size^ += next.calc_size[index]
				}
				calc_size^ = box.parent.calc_size[index] - calc_size^
			}
			else if size.type == .CHILDREN_SUM
			{
				calc_size^ = 0
				for child := box.first; child != nil ; child = child.next {
					if child.axis == state.ui.ctx.axis {
						calc_size^ = child.calc_size[index]
						break
					} else {
						calc_size^ += child.calc_size[index]
					}
				}
			}
		}
	}
	// RELATIVE POSITION & QUAD ----------------------
	for _, box in state.ui.boxes {
		#partial switch box.axis {
			case .X:
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
			case .Y:
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
	// TODO figure out how to delete all the boxes at once?
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
			if box.prev != nil do box.prev.next = box.next
			if box.next != nil do box.next.prev = box.prev
		}
	} else {
		if box.prev != nil && box.next != nil {
			box.prev.next = box.next
			box.next.prev = box.prev
			
			if box.parent != nil {
				box.parent.first = nil
				box.parent.last = nil
			}
		} else if box.prev != nil && box.next == nil {
			box.prev.next = nil

			if box.parent != nil {
				box.parent.last = box.prev
			}
		} else if box.prev == nil && box. next != nil {
			box.next.prev = nil

			if box.parent != nil {
				box.parent.first = box.next
			}
		}
	}
	delete_key(&state.ui.boxes, box.key)
	pool_free(&state.ui.box_pool, box)
}