package ui

when PROFILER do import tracy "../../../odin-tracy"

import "core:fmt"
import "core:strconv"

MAX_BOXES :: 16384

Box :: struct {
	key: Key,									// unique ID
	name: String,							// text displayed
	value: any,								// external value that is displayed
	editable_string: ^String,	// pointer to editable string

	panel: ^Panel,

	parent: ^Box,	// parent
	first: ^Box,	// first child
	last: ^Box,		// last child
	next: ^Box,		// next sibling
	prev: ^Box,		// prev sibling
	hash_next: ^Box,
	hash_prev: ^Box,

	last_frame_touched: u64,
	frame_created: u64,
	layer: int,

	flags: bit_set[Box_Flags],
	ops: Box_Ops,

	bg_color: 		HSL,
	border_color: HSL,
	font_color:		HSL,

	border: f32,
	text_align: Text_Align,

	hot_t: f32,
	active_t: f32,

	axis: UI_Axis,
	size: [XY]Box_Size,
	calc_size: v2,
	offset: v2,		// from parent
	scroll: v2,
	expand: v2,

	quad: Quad,
	clip: Quad,
	sum_children: v2,
}

Box_Size_Type :: enum {
	NONE,
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
	DEBUGCLIP,
	ROOT,
	FLOATING,
	MENU,
	PANEL,
	NO_OFFSET,

	CLICKABLE,
	HOVERABLE,
	SELECTABLE,
	DRAGGABLE,
	MIDDLEDRAGGABLE,
	VIEWSCROLL,
	SCROLLBOX,
	EDITTEXT,
 
	DRAWTEXT,
	DRAWPARAGRAPH,
	DISPLAYVALUE,
	EDITVALUE,
	DRAWBORDER,
	DRAWBACKGROUND,
	DRAWGRADIENT,
	CLIP,
	NOCLIP,

	HOTANIMATION,
	ACTIVEANIMATION,
}

Box_Ops :: struct {
  clicked: bool,
  off_clicked: bool,
  ctrl_clicked: bool,
  double_clicked: bool,
  right_clicked: bool,
  middle_clicked: bool,
  middle_dragged: bool,
  pressed: bool,
  released: bool,
  selected: bool,
  dragging: bool,
  hovering: bool,
  editing: bool,
}

gen_key :: proc(name: string, id: string) -> Key {
	text := fmt.tprint(args={name, id, state.ctx.panel.uid}, sep="_") //state.boxes.index,
	key := string_to_key(text)
	return key
}

generate_box :: proc(key: Key) -> ^Box {
	box := cast(^Box)pool_alloc(&state.boxes.pool)
	box.key = key

	assert(!(box.key in state.boxes.all))
	state.boxes.all[box.key] = box
	return box
}

create_box :: proc(_name: string, flags:bit_set[Box_Flags]={}, value: any=nil) -> ^Box {
	name := _name
	id := fmt.tprint(state.boxes.index)
	// check if "###" exists in string, and use the left half for name, right half for the ID
	for letter, index in _name {
		if letter == '#' {
			if _name[index:min(index+3, len(_name)-1)] == "###" {
				name = _name[:index]
				id = _name[index+3:]
			}
		}
	}

	key := gen_key(name, id)
	box, box_ok := state.boxes.all[key]
	parent := state.ctx.parent
	
	// if box doesn't exist, create it
	if !box_ok {
		box = generate_box(key)
		box.frame_created = state.frame
		if .FLOATING in flags {
			box.offset = state.input.mouse.pos
		}	else if .MENU in flags {
			if state.boxes.active != nil {
				offset := state.boxes.active.offset
				offset.y += state.boxes.active.calc_size.y
				box.offset = offset
			} else {
				box.offset = state.input.mouse.pos
			}
		}
	}

	if box.key.len == 0 && box.key.mem[0] != 0 {
		assert(0 == 1, "key len == 0 and mem is non zero")
	}

	assert(box != nil)
	box.name = from_odin_string(name)
	box.flags = state.ctx.flags + flags
	state.ctx.flags = {}
	box.value = value
	box.size = state.ctx.size
	box.axis = state.ctx.axis
	box.bg_color = state.ctx.bg_color
	box.border_color = state.ctx.border_color
	box.font_color = state.ctx.font_color
	box.border = state.ctx.border
	box.text_align = state.ctx.text_align
	box.panel = state.ctx.panel
	box.layer = state.ctx.layer

	box.first = nil
	// box.last = nil
	box.next = nil
	box.prev = nil
	// box.hash_next = nil

	if .ROOT in flags {
		parent = nil
		box.border = 1
		box.border_color = {1,0,1,1}
	} else {
		box.parent = parent
		// try adding as first child first
		if parent != nil {
			if parent.first == nil || parent.first == box {
				parent.first = box
				// box.prev = nil
			} else {
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
		box.hash_prev = state.ctx.box
		state.ctx.box.hash_next = box
	}
	state.ctx.box = box

	state.boxes.index += 1
	box.last_frame_touched = state.frame
	return(box)
}

process_ops :: proc(box: ^Box) {
	// PROCESS OPS ------------------------------
	box.ops.clicked = false
	box.ops.released = false
	box.ops.off_clicked = false
	
	// if box.panel != state.panels.hot && box.panel != state.panels.floating do return
	
	if state.panels.floating != nil && box.panel != state.panels.floating do return

	if .EDITTEXT in box.flags || .EDITVALUE in box.flags {
		box.ops.editing = (box.key == state.boxes.editing)
	}
	
	mouse_over := mouse_in_quad(box.clip)
	if box.layer == 1 do mouse_over = mouse_in_quad(box.quad)

	if .HOVERABLE in box.flags {
		if mouse_over && !lmb_drag() {
			is_hot := true
			if state.boxes.hot != nil {
				if box.layer < state.boxes.hot.layer do is_hot = false
			}
			box.ops.hovering = is_hot
			if is_hot do state.boxes.hot = box
			if .EDITTEXT in box.flags || .EDITVALUE in box.flags {
				cursor(.TEXT)
			}
		} else {
			box.ops.hovering = false
			if state.boxes.hot == box do state.boxes.hot = nil
		}
	}

	if .CLICKABLE in box.flags {
		if mouse_over {
			if lmb_click() {
				is_pressed := true
				if state.boxes.active != nil {
					if state.boxes.active.layer > box.layer do is_pressed = false
				}
				box.ops.pressed = is_pressed
				box.ops.clicked = is_pressed

				if is_pressed {
					if ctrl() do box.ops.ctrl_clicked = true
					state.boxes.active = box
				}
			} else {
				box.ops.clicked = false
				box.ops.ctrl_clicked = false
			}

			if lmb_release() {
				if box.ops.pressed {
					if .SELECTABLE in box.flags {
						box.ops.selected = !box.ops.selected
					}
					box.ops.released = true
				}
			}
			if lmb_up() {
				box.ops.pressed = false
			}
			
			if mmb_click() {
				box.ops.middle_clicked = true
			} else {
				box.ops.middle_clicked = false
			}
		} else { // !mouse_over
			if lmb_release_up() {
				box.ops.pressed = false
			}

			if lmb_click() || rmb_click() || mmb_click() {
				box.ops.off_clicked = true
			}
		}

	}

	if .DRAGGABLE in box.flags {
		if mouse_over {
			cursor(.HAND)
		}
		if lmb_release_up() {
			box.ops.dragging = false
			state.panels.locked = false
		}
		
		if box.ops.clicked {
			box.ops.dragging = true
			state.panels.locked = true
		}
	}

	if .VIEWSCROLL in box.flags {
		if mouse_over {
			if mmb_click() {
				box.ops.middle_clicked = true
				box.ops.middle_dragged = true
				// TODO really do this?
				state.boxes.active = box
			} else {
				box.ops.middle_clicked = false
			}
			if mmb_release_up() {
				box.ops.middle_dragged = false
			}
		}
	}

	if .MENU in box.flags {
		if !mouse_over && lmb_click() {
			delete_panel(box.panel)
		}
	}

	if box.ops.editing do string_editing(box)
}

string_editing :: proc(box: ^Box) {
	es := box.editable_string
	if es == nil do return
	// MOUSE SELECTION
	quad := box.quad
	quad.r = quad.l
	quad.t = box.panel.quad.t
	quad.b = box.panel.quad.b

	if box.parent.ops.clicked || lmb_drag() {
		for i in 0..=es.len {
			if i < es.len {
				quad.r += state.font.fonts.regular.char_data[rune(es.mem[i])].advance
			} else {
				quad.r = box.quad.r
			}
			if mouse_in_quad(quad) {
				if box.parent.ops.clicked {
					es.start = i
					es.end = i
					break
				} else if lmb_drag() {
					es.end = i
					break
				}
			}
			quad.l += state.font.fonts.regular.char_data[rune(es.mem[i])].advance
		}
	}

	// SCROLL IF CURSOR OUT OF BOUNDS
	end_pos := box.quad.l + text_string_size(X, string(es.mem[:es.end]))
	end_offset := end_pos - box.parent.quad.r
	start_offset := end_offset + box.parent.quad.r - box.parent.quad.l
	if end_offset > -10 do box.scroll.x -= 5
	if start_offset < 10 do box.scroll.x += 5
	
	// TYPE LETTERS
	if state.font.last_char > 0 {
		if es.end-es.start != 0 {
			string_backspace(es)
		}
		if !(es.len+1 > LONG_STRING_LEN) {
			if es.start >= es.len {
				es.mem[es.len] = u8(state.font.last_char)
			} else {
				copy(es.mem[clamp(es.start+1, 0, es.len):], es.mem[es.start:es.len])
				es.mem[es.start] = u8(state.font.last_char)
			}
			es.start +=	1
			es.end = es.start
			es.len += 1
			state.font.last_char = -1
		} else {
			fmt.println("MAX STRING LENGTH REACHED")
		}
	}

	// LEFT
	if read_key(&state.input.keys.left) {
		if shift() {
			if ctrl() {
				es.end = editable_jump_left(es)
			} else {
				es.end = clamp(es.end - 1, 0, es.len)
			}
		} else if ctrl() {
			es.start = editable_jump_left(es)
			es.end = es.start
		} else {
			es.start = clamp(es.start - 1, 0, LONG_STRING_LEN)
			es.end = es.start
		}
	}

	// RIGHT
	if read_key(&state.input.keys.right) {
		if shift() {
			if ctrl() {
				es.end = editable_jump_right(es)
			} else {
				es.end = clamp(es.end + 1, 0, es.len+1)
			}
		} else if ctrl() {
			es.start = editable_jump_right(es)
			es.end = es.start
		} else {
			es.start = clamp(es.start + 1, 0, es.len)
			es.end = es.start
		}
	}

	if es.len > 0 {
 		// BACKSPACE
		if read_key(&state.input.keys.backspace) {
			if ctrl() {
				string_backspace_all(es)
			} else {
				string_backspace(es)
			}
		}
		// DELETE
		if read_key(&state.input.keys.delete) {
			if ctrl() {
				string_delete_all(es)
			} else {
				string_delete(es)
			}
		}

		// SELECT ALL
		if ctrl() && read_key(&state.input.keys.a) do string_select_all(es)

	}
	// HOME
	if read_key(&state.input.keys.home) do string_home(es)
	if read_key(&state.input.keys.end) do string_end(es)

	string_len_assert(es)
}

calc_boxes :: proc(root: ^Box) {
	when PROFILER do tracy.Zone()
	// PIXEL SIZE / TEXT CONTENT SIZE ------------------------------
	for _, box in state.boxes.all {
		// for each axis (x/y) ------------------------------
		for size, axis in box.size {
			calc_size := &box.calc_size[axis]
			if size.type == .PIXELS {
				calc_size^ = box.expand[axis] + size.value
			} else if size.type == .TEXT || size.type == .MAX_SIBLING {
				if axis == X {
					calc_size^ = text_size(X, &box.name) + (state.font.margin*2)
					if .DISPLAYVALUE in box.flags do calc_size^ = text_string_size(X, fmt.tprint(" ", box.value, " "))
					if .EDITTEXT in box.flags do calc_size^ = String_size(X, box.editable_string) + state.font.margin*2
				} else if axis == Y {
					calc_size^ = text_size(Y, &box.name) * size.value
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
			if .VIEWSCROLL in box.flags || size.type == .SUM_CHILDREN {
				if size.type == .SUM_CHILDREN do calc_size^ = 0
				box.sum_children = 0
				for child := box.first; child != nil ; child = child.next {
					if size.type == .SUM_CHILDREN do calc_size^ += child.calc_size[axis]
					box.sum_children[axis] += child.calc_size[axis]
				}
			} else if size.type == .MAX_CHILD {
				calc_size^ = 0
				for child := box.first; child != nil ; child = child.next {
					calc_size^ = max(calc_size^, child.calc_size[axis])
				}
			}
		}
	}


	// CALC OFFSET & QUAD ----------------------
	for box := root; box != nil; box = box.hash_next	{
		if box.parent != nil {
			if .SCROLLBOX in box.parent.flags {
				
				viewport := box.parent
				scrollbox := viewport.parent
				sby := viewport.next
				y_handle := sby.first
				sbx := sby.next
				x_handle := sbx.first

				bar_width :f32= 14
				x := (box.calc_size.x > scrollbox.calc_size.x)
				y := (box.calc_size.y > scrollbox.calc_size.y)

				viewport_width := scrollbox.calc_size.x
				if y do viewport_width -= bar_width

				viewport_height := scrollbox.calc_size.y
				if x do viewport_height -= bar_width
				
				handle_size := ((viewport.calc_size + viewport.expand) / viewport.first.calc_size) * (viewport.calc_size + viewport.expand)
				handle_size.x = max(handle_size.x, 40)
				handle_size.y = max(handle_size.y, 40)
				handle_range := (viewport.calc_size + viewport.expand) - handle_size
				scr_range := viewport.first.calc_size - (viewport.calc_size + viewport.expand)
				scr_value := viewport.first.offset
				mpl := scr_value / scr_range
				handle_value := handle_range * mpl
				
				if y_handle.ops.pressed {
					state.panels.locked = true
					if y_handle.ops.clicked {
						state.input.mouse.delta_temp.y = state.input.mouse.pos.y * (scr_range.y/handle_range.y) + box.offset.y
					}
					box.scroll.y = ((state.input.mouse.pos.y*(scr_range.y/handle_range.y)) - state.input.mouse.delta_temp.y) * -1
				} else {
					state.panels.locked = false
				}

				if x_handle.ops.pressed {
					if x_handle.ops.clicked {
						state.input.mouse.delta_temp.x = state.input.mouse.pos.x * (scr_range.x/handle_range.x) + box.offset.x
					}
					box.scroll.x = ((state.input.mouse.pos.x*(scr_range.x/handle_range.x)) - state.input.mouse.delta_temp.x) * -1
				}

				if viewport.ops.middle_dragged {
					if viewport.ops.middle_clicked {
						state.input.mouse.delta_temp = state.input.mouse.pos - box.offset
					}
					box.scroll = state.input.mouse.pos - state.input.mouse.delta_temp
				}

				viewport.calc_size = {viewport_width, viewport_height}
				sby.calc_size = {bar_width, viewport_height}
				sby.offset.x = viewport_width
				sbx.calc_size = {viewport_width, bar_width}
				sbx.offset.y = viewport_height
				y_handle.calc_size = {sby.calc_size.x, handle_size.y}
				y_handle.offset.y = -handle_value.y
				x_handle.calc_size = {handle_size.x, sbx.calc_size.y}
				x_handle.offset.x = -handle_value.x

			}
		}


		if .DRAGGABLE in box.flags {
			if box.ops.pressed {
				if box.ops.clicked {
					state.input.mouse.delta_temp = state.input.mouse.pos - box.panel.box.offset
				}
				if box.ops.dragging {
					box.panel.box.offset = state.input.mouse.pos - state.input.mouse.delta_temp
				}
			}
		} else if !(.ROOT in box.flags) {
			if box.prev == nil {
				if box.parent != nil {
					if .VIEWSCROLL in box.parent.flags && box.panel == state.panels.hot {
						 if mouse_in_quad(box.parent.parent.quad) {
							box.scroll = box.scroll + (state.input.mouse.scroll*20)

							if box.ops.middle_dragged {
								if box.ops.middle_clicked {
									fmt.println("MIDDLE CLICKED IN THING")
									state.input.mouse.delta_temp = state.input.mouse.pos - box.offset
								}
								box.scroll = state.input.mouse.pos - state.input.mouse.delta_temp
							}
						}
						box.scroll.y = clamp(box.scroll.y, -box.parent.sum_children.y + box.parent.calc_size.y, 0)
						box.scroll.x = clamp(box.scroll.x, box.parent.calc_size.x - box.calc_size.x, 0)
						if box.scroll != box.offset {
							// to_go := (box.scroll - box.offset)/2
							// box.offset = box.offset + to_go
							box.offset = box.scroll
						}
					}
				}
			} else if !(.NO_OFFSET in box.flags) {
				box.offset[box.axis] = box.prev.offset[box.axis] + box.prev.calc_size[box.axis]
			}
		}


		// calc quad
		if box.parent == nil {
			box.quad = {box.offset.x, box.offset.y, box.offset.x + box.calc_size.x, box.offset.y + box.calc_size.y}
		} else {
			box.quad.l = box.parent.quad.l + box.offset.x
			box.quad.t = box.parent.quad.t + box.offset.y
			box.quad.r = box.quad.l + box.calc_size.x
			box.quad.b = box.quad.t + box.calc_size.y
		}
	}

	for box := root; box != nil; box = box.hash_next	{

		if .HOTANIMATION in box.flags {
			if box.ops.hovering && box == state.boxes.hot {
				box.hot_t = clamp(box.hot_t + 0.12, 0, 1)
			} else {
				box.hot_t = clamp(box.hot_t - 0.12, 0, 1)
			}
		}

		if .ACTIVEANIMATION in box.flags {
			if box.ops.pressed && box == state.boxes.active {
				box.active_t = clamp(box.active_t + 0.12, 0, 1)
			} else {
				box.active_t = clamp(box.active_t - 0.12, 0, 1)
			}
		}
	}
}

delete_box :: proc(box: ^Box) {
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
			if box.prev != nil do box.prev.next = nil
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
			
			// TODO duplicate?
			// if box.parent != nil {
			// 	box.parent.first = nil
			// 	box.parent.last = nil
			// }
		} else if box.prev != nil && box.next == nil {
			box.prev.next = nil

			// TODO not needed
			// if box.parent != nil {
			// 	box.parent.last = box.prev
			// }
		} else if box.prev == nil && box. next != nil {
			box.next.prev = nil

			// TODO not needed
			// if box.parent != nil {
			// 	box.parent.first = box.next
			// }
		}
	}
	box.next = nil
	box.prev = nil
	box.first = nil
	box.last = nil
	assert(box != nil)
	delete_key(&state.boxes.all, box.key)
	pool_free(&state.boxes.pool, box)
}