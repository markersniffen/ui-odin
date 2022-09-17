	package ui

import "core:fmt"

MAX_BOXES :: 4096

Box :: struct {
	key: Key,
	name: Short_String,
	value: any,

	panel: ^Panel,

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

	hot_t: f32,
	active_t: f32,

	size: [XY]Box_Size,
	axis: Axis,
	calc_size: v2,
	offset: v2,		// from parent
	quad: Quad,
	render_layer: int,
}

Value_Type :: enum {
	F32,
	INT,
	STRING,
}

Box_Size_Type :: enum {
  PIXELS,
  TEXT,
  PCT_PARENT,
  SUM_CHILDREN,
  MAX_CHILD,
  MIN_SIBLINGS,
  MAX_SIBLING,
}

Box_Size :: struct {
	type: Box_Size_Type,
	value: f32,
	// strictness: ??
}

Box_Flags :: enum {
	DEBUG,
	ROOT,
	FLOATING,
	MENU,
	PANEL,

	CLICKABLE,
	HOVERABLE,		
	SELECTABLE,
	DRAGGABLE,
	VIEWSCROLL,
 
	DRAWTEXT,
	DISPLAYVALUE,
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
  selected: bool,
  dragging: bool,
  hovering: bool,
}

ui_gen_key :: proc(name: string) -> Key {
	text := fmt.tprintf("%v_%v", name, state.ui.ctx.panel.uid)
	key := string_to_key(text)
	return key
}

ui_generate_box :: proc(key: Key) -> ^Box {
	box := cast(^Box)pool_alloc(&state.ui.boxes.pool)
	box.key = key
	assert(!(box.key in state.ui.boxes.all))
	state.ui.boxes.all[box.key] = box
	return box
}

ui_create_box :: proc(name: string, flags:bit_set[Box_Flags]={}, value: any=0) -> ^Box {
	key := ui_gen_key(name)
	box, box_ok := state.ui.boxes.all[key]
	parent := state.ui.ctx.parent

	// if box doesn't exist, create it
	if !box_ok {
		box = ui_generate_box(key)
		if .FLOATING in flags do box.offset = v2_f32(state.mouse.pos)
		fmt.println("generating box", name, string(key.mem[:key.len]), " | ", flags)
	}

	assert(box != nil)

	box.name = string_to_short(name)
	box.flags = flags
	box.value = value
	box.size = state.ui.ctx.size
	box.axis = state.ui.ctx.axis
	box.bg_color = state.ui.ctx.bg_color
	box.border_color = state.ui.ctx.border_color
	box.border = state.ui.ctx.border
	box.text_align = state.ui.ctx.text_align
	box.render_layer = state.ui.ctx.render_layer

	if .ROOT in flags {
		parent = nil
		box.panel = state.ui.ctx.panel
		box.border = 1
		box.border_color = {1,0,1,1}
	} else {
		box.parent = parent

		// try adding as first child first
		if parent != nil {
			if state.ui.ctx.box == parent {
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
	}

	// ADD BOX TO LINKED LIST ------------------------------
	if !(.ROOT in box.flags) {
		box.hash_prev = state.ui.ctx.box
		state.ui.ctx.box.hash_next = box
	}
	state.ui.ctx.box = box

	// PROCESS OPS ------------------------------
	mouse_over := mouse_in_quad(box.quad)
	box.ops.clicked = false

	if .HOVERABLE in box.flags {
		if mouse_over && !lmb_drag() {
			box.ops.hovering = true
			state.ui.boxes.hot = box
		} else {
			box.ops.hovering = false
			if state.ui.boxes.hot == box do state.ui.boxes.hot = nil
		}
	}

	if .CLICKABLE in box.flags {
		if mouse_over {
			if lmb_click() || lmb_drag() {
				box.ops.pressed = true
			}
			if lmb_release() {
				if box.ops.pressed {
					if .SELECTABLE in box.flags {
						box.ops.selected = !box.ops.selected
					}
					state.ui.boxes.active = box
					box.ops.clicked = true
				}
			}
			if lmb_release_up() {
				box.ops.pressed = false
			}
		} else {
			// if not mouseover
		}
	}

	if .DRAGGABLE in box.flags {
		box.ops.dragging = box.ops.pressed
	}

	box.last_frame_touched = state.ui.frame
	return(box)
}

ui_calc_boxes :: proc(root: ^Box) {
	// PIXEL SIZE / TEXT CONTENT SIZE ------------------------------
	for _, box in state.ui.boxes.all {
		// for each axis (x/y) ------------------------------
		for size, axis in box.size {
			calc_size := &box.calc_size[axis]
			if size.type == .PIXELS {
				calc_size^ = size.value
			} else if size.type == .TEXT || size.type == .MAX_SIBLING {
				if axis == X {
					calc_size^ = ui_text_size(X, &box.name) + (state.ui.margin*2)
					if .DISPLAYVALUE in box.flags do calc_size^ += ui_text_string_size(X, fmt.tprintf("%v", box.value))
				} else if axis == Y {
					calc_size^ = ui_text_size(Y, &box.name)
				}
			}
		}
	}	

	last: ^Box = nil
	// RELATIVE TO SIBLINGS ------------------------------
	for box := root; box != nil; box = box.hash_next	{
		if box.hash_next == nil do last = box
  	for size, axis in box.size {
			calc_size := &box.calc_size[axis]
			if size.type == .MIN_SIBLINGS	{
				calc_size^ = 0
				for prev:= box.prev; prev != nil; prev = prev.prev {
					calc_size^ += prev.calc_size[axis]
				}
				for next:= box.next; next != nil; next = next.next {
					calc_size^ += next.calc_size[axis]
				}
				calc_size^ = box.parent.calc_size[axis] - calc_size^
			} else if size.type == .MAX_SIBLING	{
				calc_size^ = 0
				for next:= box.parent.first; next != nil; next = next.next {
					calc_size^ = max(calc_size^, next.calc_size[axis])
				}
			}
		}
	}

	assert(last != nil)

	// PARENT SIZE ------------------------------
	for box := root; box != nil; box = box.hash_next {
		for size, axis in box.size {
			calc_size := &box.calc_size[axis]
			if size.type == .PCT_PARENT {
				psize := box.parent.calc_size[axis]
				calc_size^ = psize * size.value
			}
		}
	}
				
	// SUM CHILDREN / MAX CHILD ------------------------------
	for box := last; box != nil; box = box.hash_prev	{
  	for size, axis in box.size {
			calc_size := &box.calc_size[axis]
			if size.type == .SUM_CHILDREN {
				calc_size^ = 0
				for child := box.first; child != nil ; child = child.next {
					if child.axis == box.axis {
						calc_size^ = max(calc_size^, child.calc_size[axis])
					} else {
						calc_size^ += child.calc_size[axis]
					}
				}
			} else if size.type == .MAX_CHILD {
				calc_size^ = 0
				for child := box.first; child != nil ; child = child.next {
					calc_size^ = max(calc_size^, child.calc_size[axis])
				}
			}
		}
	}

	// RELATIVE POSITION & QUAD ----------------------
	for box := root; box != nil; box = box.hash_next	{
		if .DRAGGABLE in box.flags {
			if box.ops.dragging {
				box.parent.offset += v2_f32(state.mouse.delta)
				fmt.println(box.parent.offset, state.mouse.delta)
			}
		} else {
			#partial switch box.axis {
			case .X:
				 if .ROOT in box.flags {
					// box.offset.x = box.panel.quad.l
				} else {
					if box.prev == nil {
						box.offset.x = 0
					} else {
						box.offset.x = box.prev.offset.x + box.prev.calc_size[X]
					}
				}
				if box.parent != nil do box.offset.y = 0
			case .Y:
				if .ROOT in box.flags {
					// box.offset.y = box.panel.quad.t
				} else {
					if box.prev == nil {
						box.offset.y = 0
					} else {
						box.offset.y = box.prev.offset.y + box.prev.calc_size[Y]
					}
					if box.parent != nil do box.offset.x = 0 //box.parent.ctx.l
				}
			}
		}
		box.quad = {box.offset.x, box.offset.y, box.offset.x + box.calc_size.x, box.offset.y + box.calc_size.y}
	}

	for box := root; box != nil; box = box.hash_next	{
		if .HOTANIMATION in box.flags {
			if box.ops.hovering {
				box.hot_t = clamp(box.hot_t + 0.12, 0, 1)
			} else {
				box.hot_t = clamp(box.hot_t - 0.12, 0, 1)
			}
		}

		if .ACTIVEANIMATION in box.flags {
			if box.ops.pressed {
				box.active_t = clamp(box.active_t + 0.12, 0, 1)
			} else {
				box.active_t = clamp(box.active_t - 0.12, 0, 1)
			}
		}
	}
}

ui_delete_box :: proc(box: ^Box) {
	//  figure out how to delete all the boxes at once?
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
	assert(box != nil)
	delete_key(&state.ui.boxes.all, box.key)
	pool_free(&state.ui.boxes.pool, box)
}