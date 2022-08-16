package ui

import "core:fmt"

MAX_WIDGETS :: 4096

// ui core

/*
	ui_update -> go through ui code and build buttons, add them to queue
	ui_render -> go through queue and render properly

*/

Widget :: struct {
	uid: Uid,
	parent_uid: Uid,
	first_child: Uid,
	num_children: int,
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

ui_bar :: proc() {

}

ui_text :: proc(name: string, text: string) {

}

ui_button :: proc(name: string, command: string) -> bool {
	return true
}

ui_textbox :: proc(name:string, text: string) {

}

ui_sheet :: proc(name: string, data: string) {

}

