package ui

import tracy "../../../odin-tracy"

import "core:fmt"

MAX_PANELS :: 40
PANEL_MARGIN :: 1

Panel :: struct {
	uid: Uid,

	parent: ^Panel,
	child_a: ^Panel,
	child_b: ^Panel,

	next: ^Panel,
	prev: ^Panel,

	axis: Axis,
	size: f32,
	type: Panel_Type,
	quad: Quad,
	bar: Quad,

	content: Panel_Content,
	box: ^Box,
}

Panel_Type :: enum {
	NULL,
	STATIC,
	DYNAMIC,
	FLOATING,
}

ui_queue_panel :: proc(current:^Panel=nil, axis:Axis=.X, type: Panel_Type, content:Panel_Content=.DEBUG, size:f32, quad:Quad={0,0,0,0})
{
	state.ui.panels.queued.axis = axis
	state.ui.panels.queued.type = type
	state.ui.panels.queued.content = content
	state.ui.panels.queued.size = size
	state.ui.panels.queued.quad = quad
	state.ui.panels.queued_parent = current
}

ui_create_panel :: proc(current:^Panel=nil, axis:Axis=.X, type: Panel_Type, content:Panel_Content=.DEBUG, size:f32, quad:Quad={0,0,0,0}) -> ^Panel
{
	// current := state.ui.ctx.panel
	panel := cast(^Panel)pool_alloc(&state.ui.panels.pool)
	panel.uid = new_uid()
		
	state.ui.panels.all[panel.uid] = panel

	panel.axis = axis
	panel.size = size
	panel.type = type
	panel.quad = quad
	panel.parent = current
	panel.content = content

	if current == nil {
		state.ui.panels.root = panel
	} else {
		if type == .FLOATING {
			assert(current.child_a == nil && current.child_b == nil)
			if state.ui.panels.floating != nil {
				if state.ui.panels.floating.content == content {
					panel.quad = state.ui.panels.floating.quad
				}
				// note needed?
				// ui_delete_panel(state.ui.panels.floating)
			}
			panel.parent = current
			state.ui.panels.floating = panel
		} else {
			// create parent
			new_parent := cast(^Panel)pool_alloc(&state.ui.panels.pool)
			new_parent.uid = new_uid()
			state.ui.panels.all[new_parent.uid] = new_parent

			new_parent.child_a = current
			new_parent.child_b = panel
			new_parent.parent = current.parent
			new_parent.axis = axis
			new_parent.size = size
			new_parent.type = .NULL

			panel.parent = new_parent

			if current == state.ui.panels.root do state.ui.panels.root = new_parent

			grandpa := current.parent
			if grandpa != nil {
				if grandpa.child_a == current {
					grandpa.child_a = new_parent
				} else {
					grandpa.child_b = new_parent
				}
			}
			current.parent = new_parent
		}
	}
	state.ui.ctx.panel = panel
	return panel
}

ui_calc_panel :: proc(panel: ^Panel, quad: Quad) {
	tracy.Zone()
	if panel != nil
	{
		panel.quad = quad
		child_a := panel.child_a
		// if there is a child
		// calculate the children size
		if child_a != nil
		{
			a: Quad
			b: Quad
			bar: Quad
			size_w: f32 = (quad.r - quad.l) * panel.size
			size_h: f32 = (quad.b - quad.t) * panel.size
			if panel.axis == .X
			{
				a = { quad.l, quad.t, quad.l + size_w - PANEL_MARGIN, quad.b }
				b = { quad.l + size_w + PANEL_MARGIN, a.t, quad.r, quad.b }
				bar = {quad.l + size_w - PANEL_MARGIN, quad.t, quad.l + size_w + PANEL_MARGIN, quad.b}
			} else if panel.axis == .Y {
				a	= { quad.l, quad.t, quad.r, quad.t + size_h - PANEL_MARGIN }
				b	= { quad.l, quad.t + size_h + PANEL_MARGIN, quad.r, quad.b }
				bar = { quad.l, quad.t + size_h - PANEL_MARGIN, quad.r, quad.t + size_h + PANEL_MARGIN}
			}
			panel.bar = bar

			//NOTE - CODE FOR SIZING PANELS
			if panel.child_a.type != .STATIC  {
				if state.ui.panels.active == panel {
					cb := panel.child_b
					if panel.axis == .X {
						panel.size = (f32(state.mouse.pos.x) - quad.l) * (1 / (quad.r - quad.l))
						if panel.axis == cb.axis {
							old_child_bar_center := cb.bar.l + ((cb.bar.r - cb.bar.l) / 2)
							panel.child_b.size = (old_child_bar_center - b.l) * (1 / (b.r - b.l))
						}
					} else {
						panel.size = (f32(state.mouse.pos.y) - quad.t) * (1 / (quad.b - quad.t))
						if panel.axis == cb.axis {
							old_child_bar_center := cb.bar.t + ((cb.bar.b - cb.bar.t) / 2)
							panel.child_b.size = (old_child_bar_center - b.t) * (1 / (b.b - b.t))
						}
					}
				}
			} else if panel.child_a.type == .STATIC {
				panel.size = state.ui.line_space * (1 / f32(state.window.size[panel.axis]))			
			}
			ui_calc_panel(panel.child_a, a)
			ui_calc_panel(panel.child_b, b)
		} else if panel.type == .FLOATING {
			if panel.box != nil do panel.quad = panel.box.quad
		}

		mouse_over : bool = mouse_in_quad(panel.quad)
		if panel.type == .NULL {
			mouse_over = mouse_in_quad(panel.bar)
			if mouse_over {
				cursor_size(panel.axis)				
			}
		}
		if mouse_over {
			state.ui.panels.hot = panel

			if lmb_click() {
				state.ui.panels.active = panel
			}
		} else {
			if state.ui.panels.hot == panel {
				state.ui.panels.hot = nil
			}
		}
		if lmb_release_up() && state.ui.panels.active == panel {
			state.ui.panels.active = nil
		}
	}
}

ui_delete_panel :: proc(panel: ^Panel) {
	if panel != nil
	{
		parent := panel.parent
		
		if panel.type == .FLOATING {
			delete_key(&state.ui.panels.all, panel.uid)
			assert(pool_free(&state.ui.panels.pool, panel) == true)
			state.ui.panels.floating = nil
		} else {
			if parent != nil
			{
				grandpa := parent.parent
				if grandpa != nil
				{
					sibling: ^Panel
					if parent.child_a == panel
					{
						sibling = parent.child_b
					} else {
						sibling = parent.child_a
					}
					if sibling != nil
					{
						sibling.parent = parent.parent
						if grandpa.child_a == panel.parent do grandpa.child_a = sibling
						if grandpa.child_b == panel.parent do grandpa.child_b = sibling

						delete_key(&state.ui.panels.all, parent.uid)
						delete_key(&state.ui.panels.all, panel.uid)
						assert(pool_free(&state.ui.boxes.pool, panel))
						assert(pool_free(&state.ui.boxes.pool, parent))
					} else {
						fmt.println("failed to find sibling")
					}
				} else {
					fmt.println("failed to find grandparent of", panel)
				}
			} else {
				fmt.println("failed to find Parent of", panel)
			}
		}
	} else {
		fmt.println("failed to find panel:", panel)
	}
}
