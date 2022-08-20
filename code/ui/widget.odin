package ui

import "core:fmt"

MAX_WIDGETS :: 4096

// ui core

/*
	ui_update -> go through ui code and build buttons, add them to queue
	ui_render -> go through queue and render properly

*/

Widget :: struct {
	parent: ^Widget,			// for navigating hierarchy
	first_child: ^Widget,
	next: ^Widget,
	// more
	// ...

	hash_prev: Uid,				// used for quickly going through all persitent widgets
	hash_next: Uid,
	key: string,					// unique identifier
	last_frame_touched: u64,	// if frame is greater than this, prune me

	ctx: Quad,
	ops: bit_set[Widget_Ops],
	state: bit_set[Widget_State],

	// had persisten animation data here?
}

Widget_Ops :: enum {
	CLICK,		// clickable
	SELECT,		// selectable
	DRAG,		// ...
	TEXT,
	EDIT,
}

Widget_State :: enum {
	ACTIVE,
	HOT,	
}

ui_generate_key :: proc(key: string) -> string {
	return key
}

create_widget :: proc(key: string, ops:bit_set[Widget_Ops], master:bool=false) -> ^Widget {
	widget: ^Widget
	fmt.println(">>>>>>>>", key)

	// if widget doesn't exist, create it
	if !(key in state.ui.widgets) {
		fmt.println("creating NEW widget", key)
		widget = cast(^Widget)pool_alloc(&state.ui.widget_pool)
		widget.key = ui_generate_key(key)
		widget.parent = state.ui.parent
		widget.ops = ops
		state.ui.widgets[widget.key] = widget
	} else {
		widget = state.ui.widgets[key]
	}

	if !master {
		fmt.println("Not the master...")
		widget.parent = state.ui.parent
		
		if widget.parent.first_child == nil || widget.parent.first_child == widget {
			widget.parent.first_child = widget
		} else {
			child := widget.parent.first_child
			for {  
				if child.next == nil || child.next == widget {
					break
				}
				child = child.next
			}
			child.next = widget
		}
	}
	fmt.println("END", widget.parent)
	return widget
}

delete_widget :: proc(key: string) {
	widget, widget_ok := state.ui.widgets[key]; if widget_ok {
		pool_free(&state.ui.widget_pool, widget)
		delete_key(&state.ui.widgets, key)
	// if widget doesn't exist create one
	} else {
		fmt.println("no widget to delete...")
	}
}

ui_master_widget :: proc(key: string) -> ^Widget {
	widget := create_widget(key, {}, true)
	return widget
}

ui_row :: proc(name:string) -> ^Widget {
	widget := create_widget(name, {})
	return widget
	// state.ui.ctx
}

ui_button :: proc(key: string) -> bit_set[Widget_State] {
	widget := create_widget(key, {.CLICK})
	return widget.state
}

ui_push_parent :: proc(widget: ^Widget) {
	state.ui.parent = widget
}

ui_pop_parent :: proc() {
	state.ui.parent = state.ui.parent.parent
}

operate_widget :: proc(widget: ^Widget) {

	ops := widget.ops
	// fmt.println("operating on widget:", widget)

	if .CLICK in ops {
		// fmt.println("CLICK")
	}

	if .SELECT in ops {
		// fmt.println("SELECT")
	}

	if .TEXT in ops {
		// fmt.println("TEXT")
	}
}