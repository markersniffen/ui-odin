package ui

import "core:fmt"
import "core:mem"


//______ BUILDER API ______//

ui_begin :: proc() -> ^Panel {
	state.ui.ctx.render_layer = 0
	state.ui.ctx.box = nil
	state.ui.ctx.parent = nil
	quad := state.ui.ctx.panel.quad
	ui_size(.PIXELS, quad.r - quad.l, .PIXELS, quad.b - quad.t)
	box := ui_create_box("root", { .ROOT, .CLIP })
	box.offset = {quad.l, quad.t}
	state.ui.ctx.panel.box = box
	ui_push_parent(box)
	ui_size(.PCT_PARENT, 1, .PCT_PARENT, 1)
	return state.ui.ctx.panel
}

ui_begin_floating :: proc() -> ^Panel {
	state.ui.ctx.render_layer = 1
	state.ui.ctx.box = nil
	state.ui.ctx.parent = nil
	ui_size(.MAX_CHILD, 1, .SUM_CHILDREN, 1)
	box := ui_create_box("root_floating", { .ROOT, .DRAWBACKGROUND, .FLOATING })
	// box.offset = {state.ui.ctx.panel.quad.l, state.ui.ctx.panel.quad.t}
	// box.offset = v2_f32(state.mouse.pos)
	state.ui.ctx.panel.box = box
	ui_push_parent(box)
	// dragbar := ui_dragbar()
	// ui_push_parent(dragbar)
	return state.ui.ctx.panel
}

ui_end :: proc() {
	state.ui.boxes.index = 0
}

ui_push_parent :: proc(box: ^Box) {	state.ui.ctx.parent = box }

ui_pop_parent :: proc() { state.ui.ctx.parent = state.ui.ctx.parent.parent }

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

ui_axis 				:: proc(axis: Axis) 	{ state.ui.ctx.axis = axis }

ui_set_render_layer 	:: proc(layer: int) 	{ state.ui.ctx.render_layer = layer }

ui_set_border_color 	:: proc(color: v4) 		{ state.ui.ctx.border_color = color }

ui_set_border_thickness :: proc(value: f32)		{ state.ui.ctx.border = value }

ui_dragbar :: proc(label:string="") -> ^Box {
	box: ^Box
	if label == "" {
		box = ui_create_box("dragbar", {
			.CLICKABLE,
			.SELECTABLE,
			.HOVERABLE,
			.DRAGGABLE,
			.DRAWBACKGROUND,
		})
	} else {
		box = ui_create_box(label, {
			.CLICKABLE,
			.SELECTABLE,
			.HOVERABLE,
			.DRAGGABLE,
			.DRAWBACKGROUND,
			.DRAWTEXT,
		})
	}
	return box
}

//______ WIDGETS ______//

ui_empty :: proc(_name:string="") -> ^Box {
	name := "empty"
	if _name != "" do name = _name
	box := ui_create_box(name, { })
	ui_push_parent(box)
	return box
}

ui_scrollbox :: proc() -> ^Box {
	empty := ui_create_box("scrollbox", { .DRAWBORDER })
	ui_push_parent(empty)
	ui_axis(.X)
	ui_size(.MIN_SIBLINGS, 1, .PCT_PARENT, 1)
	viewport := ui_create_box("viewport", { .VIEWSCROLL, .CLIP })
	ui_push_parent(viewport)
	ui_axis(.Y)
	return viewport
}

ui_scrollbar :: proc() -> ^Box {

	viewport := state.ui.ctx.parent.first
	dragbar_height := ((viewport.calc_size.y + viewport.expand.y) / viewport.sum_children.y) * (viewport.calc_size.y + viewport.expand.y)

	if viewport.calc_size.y > dragbar_height {
		ui_size(.PIXELS, 12, .PCT_PARENT, 1)
	} else {
		ui_size(.PIXELS, 0, .PCT_PARENT, 1)
	}
	
	dragbar := ui_create_box("scrollbar", { .DRAWBORDER, .CLIP } )
	ui_push_parent(dragbar)
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .PIXELS, min(dragbar_height, viewport.calc_size.y))
	handle := ui_create_box("handle", { .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .CLICKABLE } )

	dragbar_range := (viewport.calc_size.y + viewport.expand.y) - dragbar_height
	scroll_range := viewport.sum_children.y - (viewport.calc_size.y + viewport.expand.y)
	scroll_value := viewport.first.offset.y
	multiplier := scroll_value / scroll_range
	dragbar_value := dragbar_range * multiplier
	handle.offset.y = -dragbar_value

	handle.bg_color = state.ui.col.highlight
	if handle.ops.pressed {
		if handle.ops.clicked {
			state.mouse.delta_temp.y = (f32(state.mouse.pos.y) * (scroll_range/dragbar_range)) + viewport.first.offset.y
		}
		viewport.first.scroll.y = ((f32(state.mouse.pos.y)*(scroll_range/dragbar_range)) - state.mouse.delta_temp.y) * -1
	}
	return dragbar
}

ui_sizebar_y :: proc() -> ^Box {
	ui_axis(.Y)
	ui_size(.PCT_PARENT, 1, .PIXELS, 4)
	box := ui_create_box("sizebar_y", { .DRAWBACKGROUND, .HOVERABLE, .HOTANIMATION, .CLICKABLE })
	if box.ops.pressed {
		box.parent.expand.y += f32(state.mouse.delta.y)
	}
	return box
}

ui_label :: proc(key: string) -> Box_Ops {
	box := ui_create_box(key, { .DRAWTEXT, })
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
	// state.ui.index += 1 // TODO is this a good idea?
	oldsize := state.ui.ctx.size[X]
	ui_size_x(.MIN_SIBLINGS, 1)
	box := ui_create_box("spacer_fill", {
	})
	ui_size_x(oldsize.type, oldsize.value)
	return box.ops
}

ui_spacer_pixels :: proc(pixels: f32) -> Box_Ops {
	// state.ui.index += 1 // TODO is this a good idea?
	oldsize := state.ui.ctx.size.x
	ui_size_x(.PIXELS, pixels)
	box := ui_create_box("spacer_pixels", {
	})
	ui_size_x(oldsize.type, oldsize.value)
	return box.ops
}