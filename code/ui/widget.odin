package ui

import "core:fmt"

MAX_WIDGETS :: 4096

// ui core

/*
	ui_update -> go through ui code and build buttons, add them to queue
	ui_render -> go through queue and render properly

*/

Widget :: struct {
	id: string,
	parent_uid: Uid,
	first_child: Uid,
	next: uid,

	ctx: Quad,
	ops: bit_set[Widget_Ops],
	state: bit_set[Widget_State],
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

push_parent :: proc() {
	parent, parent_ok := state.ui.panels[state.ui.parent]
	if parent_ok {
		state.ui.parent = parent.next
	}
}

pop_parent :: proc() {
	parent, parent_ok := state.ui.panels[state.ui.parent]
	if parent_ok {
		state.ui.parent = parent.parent
	}
}

create_widget :: proc(ctx: Quad, ops:bit_set[Widget_Ops], w_state:bit_set[Widget_State]) {
	widget := cast(^Widget)pool_alloc(&state.ui.widget_pool)
	widget.uid = "temp"
	widget.parent_uid = 0
	widget.ctx = ctx
	widget.ops = ops
	widget.state = w_state
}

operate_widget :: proc(widget: ^Widget) {

	ops := widget.ops
	fmt.println("operating on widget:", widget)

	if .CLICK in ops {
		fmt.println("CLICK")
	}

	if .SELECT in ops {
		fmt.println("SELECT")
	}

	if .TEXT in ops {
		fmt.println("TEXT")
	}

}

ui_button :: proc(name: string, command: string) -> bool {
	
	// create_widget()

	return true


}

