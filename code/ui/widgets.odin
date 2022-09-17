package ui

import "core:fmt"
import "core:mem"


//______ BUILDER API ______//

ui_begin :: proc() -> ^Panel {
	state.ui.ctx.box = nil
	state.ui.ctx.parent = nil
	quad := state.ui.ctx.panel.quad
	ui_size(.PIXELS, quad.r - quad.l, .PIXELS, quad.b - quad.t)
	box := ui_create_box("root", { .ROOT })
	box.offset = {quad.l, quad.t}
	state.ui.ctx.panel.box = box
	ui_push_parent(box)
	ui_size(.PCT_PARENT, 1, .PCT_PARENT, 1)
	return state.ui.ctx.panel
}

ui_begin_floating :: proc() -> ^Panel {
	state.ui.ctx.box = nil
	state.ui.ctx.parent = nil
	ui_size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
	box := ui_create_box("root_floating", { .ROOT, .FLOATING })
	// box.offset = {state.ui.ctx.panel.quad.l, state.ui.ctx.panel.quad.t}
	// box.offset = v2_f32(state.mouse.pos)
	state.ui.ctx.panel.box = box
	ui_push_parent(box)
	dragbar := ui_dragbar()
	ui_push_parent(dragbar)
	return state.ui.ctx.panel
}

ui_end :: proc() {
}

ui_push_parent :: proc(box: ^Box) {
	state.ui.ctx.parent = box
}

ui_pop_parent :: proc() {
	state.ui.ctx.parent = state.ui.ctx.parent.parent
}

ui_pop :: proc() { ui_pop_parent() }

ui_size :: proc (x_type: Box_Size_Type, x_value: f32, y_type: Box_Size_Type, y_value: f32) {
	ui_size_x(x_type, x_value)
	ui_size_y(y_type, y_value)
}

ui_size_x :: proc(type: Box_Size_Type, value: f32) {
	state.ui.ctx.size.x.type = type
	state.ui.ctx.size.x.value = value
}

ui_size_y :: proc(type: Box_Size_Type, value: f32) {
	state.ui.ctx.size.y.type = type
	state.ui.ctx.size.y.value = value
}

ui_axis :: proc(axis: Axis) {
	state.ui.ctx.axis = axis
}

ui_set_render_layer :: proc(layer: int) {
	state.ui.ctx.render_layer = layer
}

ui_set_border_color :: proc(color: v4) {
	state.ui.ctx.border_color = color
}

ui_set_border_thickness :: proc(value: f32) {
	state.ui.ctx.border = value
}

ui_panel :: proc(key: string, axis: Axis) -> (Box_Ops, Box_Ops) {
	ui_axis(axis)
	if axis == .X {
		ui_size(.PCT_PARENT, .5, .PCT_PARENT, 1)
	} else {
		ui_size(.PCT_PARENT, 1, .PCT_PARENT, .5)
	}
	a := ui_create_box("A", {
		.PANEL,
		.DRAWBORDER,
		.DRAWBACKGROUND,
	})
	b := ui_create_box("B", {
		.PANEL,
		.DRAWBORDER,
		.DRAWBACKGROUND,
	})
	return a.ops, b.ops
}

// //______ WIDGETS ______//

ui_empty :: proc() -> ^Box {
	state.ui.index += 1
	box := ui_create_box(fmt.tprintf("empty_%v", state.ui.index), { })
	ui_push_parent(box)
	return box
}

ui_dragbar :: proc() -> ^Box {
	state.ui.index += 1
	box := ui_create_box(fmt.tprintf("dragbar_%v", state.ui.index), {
		.CLICKABLE,
		.SELECTABLE,
		.HOVERABLE,
		.DRAGGABLE,
		.DRAWBACKGROUND,
		.DEBUG,
	})
	return box
}

ui_label :: proc(key: string) -> Box_Ops {
	box := ui_create_box(key,{
		.DRAWTEXT,
	})
	return box.ops
}

ui_value :: proc(key: string, value: any) -> Box_Ops {
	box := ui_create_box(key,{ .DISPLAYVALUE }, value)
	return box.ops	
}

ui_button :: proc(key: string) -> Box_Ops {
	box := ui_create_box(key, {
		.CLICKABLE,
		.HOVERABLE,
		.DRAWTEXT,
		.DRAWBORDER,
		.DRAWBACKGROUND,
		.DRAWGRADIENT,
		.HOTANIMATION,
		.ACTIVEANIMATION,
	})
	box.text_align = .CENTER
	return box.ops
}

ui_spacer_fill :: proc() -> Box_Ops {
	state.ui.index += 1 // TODO is this a good idea?
	oldsize := state.ui.ctx.size[X]
	ui_size_x(.MIN_SIBLINGS, 1)
	box := ui_create_box(fmt.tprintf("space_%v", state.ui.index), {
	})
	ui_size_x(oldsize.type, oldsize.value)
	return box.ops
}

ui_spacer_pixels :: proc(pixels: f32) -> Box_Ops {
	state.ui.index += 1 // TODO is this a good idea?
	oldsize := state.ui.ctx.size.x
	ui_size_x(.PIXELS, pixels)
	box := ui_create_box(fmt.tprintf("space_%v", state.ui.index), {
	})
	ui_size_x(oldsize.type, oldsize.value)
	return box.ops
}