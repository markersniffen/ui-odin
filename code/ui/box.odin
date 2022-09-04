	package ui

import "core:fmt"

MAX_BOXES :: 4096

Box :: struct {
	key: string,
	name: string,
	value: any,
	// value_type: Value_Type,

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

	size: [XY]UI_Size,
	// direction: Direction,
	axis: Axis,
	calc_size: v2,
	offset: v2,		// from parent
	ctx: Quad,
	render_layer: int,
}

Value_Type :: enum {
	F32,
	INT,
	STRING,
}

Box_Flags :: enum {
	ROOT,
	MENU,

	CLICKABLE,
	HOVERABLE,		
	SELECTABLE,
	MENUSELECT,
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

ui_split_key :: proc(key: string) -> string {
	a, b: string
	for letter, index in key {
		if letter == '#' {
			a = key[:index]
			b = key[index:]
			break
		}
	}
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

ui_create_box :: proc(_key: string, flags:bit_set[Box_Flags]={}, value: any=0) -> ^Box {
	key := ui_gen_key(_key)
	box, box_ok := state.ui.boxes[key]
	parent := state.ui.ctx.box_parent

	// if box doesn't exist, create it
	if !box_ok {
		box = ui_generate_box(_key)
		box.parent = parent
		box.value = value
		box.size = state.ui.ctx.size
		box.axis = state.ui.ctx.axis
		box.bg_color = state.ui.ctx.bg_color
		box.border_color = state.ui.ctx.border_color
		box.border = state.ui.ctx.border
		box.text_align = state.ui.ctx.text_align
		box.render_layer = state.ui.ctx.render_layer
	}
	// try adding as first child first
	if state.ui.ctx.box == parent { //parent.first == nil {
		parent.first = box
		box.prev = nil
	} else if parent.first != nil {
		assert(parent.last != nil)
		parent.last.next = box
		box.prev = parent.last
	}
	parent.last = box
	box.next = nil

	// ADD BOX TO LINKED LIST ------------------------------
	box.hash_prev = state.ui.ctx.box
	state.ui.ctx.box.hash_next = box
	state.ui.ctx.box = box
	box.flags = flags

	// PROCESS OPS ------------------------------
	// hovering
	mouse_over := mouse_in_quad(box.ctx)
	click := (state.mouse.left == .CLICK)
	drag := (state.mouse.left == .DRAG)
	released := (state.mouse.left == .RELEASE)
	up := (state.mouse.left == .UP)

	box.ops.clicked = false

	// TODO this is for special buttons for menus
	// TODO drawing the layer 2 boxes is separate
	if .MENUSELECT in box.flags {
		if state.ui.ctx.box_active == nil {
			if mouse_over && released {
				box.ops.selected = true
				state.ui.ctx.box_active = box
			}
		} else {
			if mouse_over {
				if state.ui.ctx.box_active == box && released {
					state.ui.ctx.box_active = nil
					box.ops.selected = false
				} else {
					state.ui.ctx.box_active.ops.selected = false
					state.ui.ctx.box_active = box
					box.ops.selected = true
				}
			}
		}
	}

	if .HOVERABLE in box.flags {
		if mouse_over && !drag {
			box.ops.hovering = true
			state.ui.ctx.box_hot = box
		} else {
			box.ops.hovering = false
			if state.ui.ctx.box_hot == box do state.ui.ctx.box_hot = nil
		}
	}

	if .CLICKABLE in box.flags {
		if mouse_over {
			if click {
				box.ops.pressed = true
			}
			if released {
				if box.ops.pressed {
					if .SELECTABLE in box.flags {
						box.ops.selected = !box.ops.selected
					}
					state.ui.ctx.box_active = box
					box.ops.clicked = true
				}
				box.ops.pressed = false
			}
			// if up {
			// 	if state.ui.menu_box != nil {
			// 		box.ops.pressed = true
			// 		state.ui.menu_box.ops.selected = false
			// 		box.ops.selected = true
			// 	}
			// }
		} else {
			// if not mouseover
		}
	}

	box.last_frame_touched = state.ui.frame
	return(box)
}

ui_calc_boxes :: proc() {
	// PIXEL SIZE / TEXT CONTENT SIZE ------------------------------
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
					if .DISPLAYVALUE in box.flags do calc_size^ += ui_text_size(X, fmt.tprintf("%v", box.value))
				} else if index == Y {
					calc_size^ = ui_text_size(Y, box.name)
				}
			}
		}
	}	

	// PARENT SIZE ------------------------------
	for _, panel in state.ui.panels {
		if panel.child_a == nil && panel.box != nil {

		last: ^Box = nil

		  	for box := panel.box; box != nil; box = box.hash_next {
					if box.hash_next == nil do last = box

					for size, index in box.size {
						calc_size := &box.calc_size[index]
						if size.type == .PERCENT_PARENT {
							psize := box.parent.calc_size[index]
							calc_size^ = psize * size.value
						}
					}
		  	}
				
			assert(last != nil)
			// RELATIVE TO SIBLINGS ------------------------------
			for box := panel.box; box != nil; box = box.hash_next {
			  	for size, index in box.size
			  	{
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
				}
			}

			for box := last; box != nil; box = box.hash_prev {
			  	for size, index in box.size {
					calc_size := &box.calc_size[index]

					if size.type == .CHILDREN_SUM
					{
						calc_size^ = 0
						numchildren := 0
						for child := box.first; child != nil ; child = child.next {
							numchildren += 1
							if child.axis == box.axis {
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
			for box := panel.box; box != nil; box = box.hash_next
			{
				#partial switch box.axis
				{
					case .X:
					  if .MENU in box.flags {
							box.offset[X] = box.parent.calc_size[X]
				  	} else {
							if box.prev == nil {
								box.offset[0] = 0
							} else {
								box.offset.x = box.prev.offset.x + box.prev.calc_size[X]
							}
							if box.parent != nil do box.offset.y = 0 //box.parent.ctx.t
				  	}
					case .Y:
						if .MENU in box.flags {
							box.offset.y = box.parent.calc_size[Y]
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

			// for _, box in state.ui.boxes {
			for box := panel.box; box != nil; box = box.hash_next {
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
	delete_key(&state.ui.boxes, box.key)
	pool_free(&state.ui.box_pool, box)
}