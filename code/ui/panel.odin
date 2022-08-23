package ui

import "core:fmt"

MAX_PANELS :: 40
PANEL_MARGIN :: 2

Panel :: struct {
	uid: Uid,

	parent: ^Panel,
	child_a: ^Panel,
	child_b: ^Panel,

	direction: Direction,
	size: f32,
	scaleable: bool,
	type: Panel_Type,
	ctx: Quad,
	box: ^Box,
}

Panel_Type :: enum {
	NULL,
	DEBUG,
	PANEL_LIST,
	TEMP,
	FILE_MENU,
}

ui_create_panel :: proc(active_panel:^Panel, direction:Direction=.HORIZONTAL, type: Panel_Type=.TEMP, size:f32=0.5) -> ^Panel
{
	if active_panel != nil {
		new_parent := cast(^Panel)pool_alloc(&state.ui.panel_pool)
		new_parent.uid = new_uid()
		new_parent.size = size
		new_parent.child_a = active_panel
		new_parent.parent = active_panel.parent
		new_parent.scaleable = active_panel.scaleable
		new_parent.direction = direction
		state.ui.panels[new_parent.uid] = new_parent

		active_panel.parent = new_parent
		active_panel.child_a = nil
		active_panel.child_b = nil
		active_panel.size = 0.5 

		panel := cast(^Panel)pool_alloc(&state.ui.panel_pool)
		panel.uid = new_uid()
		panel.size = 0.5
		panel.parent = new_parent
		panel.direction = direction
		panel.type = type

		if panel.type == .FILE_MENU {
			panel.scaleable = false
		} else {
			panel.scaleable = true
		}

		state.ui.panels[panel.uid] = panel

		new_parent.child_b = panel

		if active_panel == state.ui.panel_master {
			state.ui.panel_master = new_parent
		}

		grandpa := new_parent.parent
		if grandpa != nil {
			if grandpa.child_a == active_panel {
				grandpa.child_a = new_parent
			} else {
				grandpa.child_b = new_parent
			}
		}
		return panel
	} else {
		panel := cast(^Panel)pool_alloc(&state.ui.panel_pool)
		panel.uid = new_uid()
		panel.size = 0.5
		panel.parent = nil
		panel.direction = direction
		panel.type = type
		if panel.type == .FILE_MENU {
			panel.scaleable = false
		} else {
			panel.scaleable = true
		}
		state.ui.panels[panel.uid] = panel
		return panel
	}
	return nil
}

ui_delete_panel :: proc(panel: ^Panel)
{
	fmt.println("trying to delete ", panel.uid)
	if panel != nil
	{
		parent := panel.parent
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

					delete_key(&state.ui.panels, parent.uid)
					delete_key(&state.ui.panels, panel.uid)
				} else {
					fmt.println("failed to find sibling")
				}
			} else {
				fmt.println("failed to find grandparent of", panel)
			}
		} else {
			fmt.println("failed to find Parent of", panel)
		}
	} else {
		fmt.println("failed to find panel:", panel)
	}
}

ui_calc_panel :: proc(panel: ^Panel, ctx: Quad)
{
	if panel != nil
	{
		panel.ctx = ctx
		child_a := panel.child_a
		if child_a != nil
		{
			a: Quad
			b: Quad
			bar: Quad
			size_w: f32 = (ctx.r - ctx.l) * panel.size
			size_h: f32 = (ctx.b - ctx.t) * panel.size
			if panel.direction == .HORIZONTAL
			{
				a = { ctx.l, ctx.t, ctx.l + size_w - PANEL_MARGIN, ctx.b }
				b = { ctx.l + size_w + PANEL_MARGIN, a.t, ctx.r, ctx.b }
				bar = {ctx.l + size_w - PANEL_MARGIN, ctx.t, ctx.l + size_w + PANEL_MARGIN, ctx.b}
			} else {				  // plus key
				a	= { ctx.l, ctx.t, ctx.r, ctx.t + size_h - PANEL_MARGIN }
				b	= { ctx.l, ctx.t + size_h + PANEL_MARGIN, ctx.r, ctx.b }
				bar = { ctx.l, ctx.t + size_h - PANEL_MARGIN, ctx.r, ctx.t + size_h + PANEL_MARGIN}
			}
			color := state.ui.col.base

			// NOTE - TEMP? - CODE FOR SIZING PANELS //
			if panel.scaleable {
				if pt_in_quad({f32(state.mouse.pos.x), f32(state.mouse.pos.y)}, bar) {
					if read_mouse(&state.mouse.left, .DRAG) do state.ui.panel_active = panel
					color = state.ui.col.highlight
				}
				if state.mouse.left == .UP do state.ui.panel_active = nil
				if state.ui.panel_active == panel {
					if panel.direction == .HORIZONTAL {
						panel.size = (f32(state.mouse.pos.x) - ctx.l) * (1 / (ctx.r - ctx.l))
					} else {
						panel.size = (f32(state.mouse.pos.y) - ctx.t) * (1 / (ctx.b - ctx.t))
					}
				}
			} else {
				panel.size = state.ui.line_space * (1 / f32(state.window_size.y))
			}
			push_quad_solid(bar, color)
			//////////////////////////////

			ui_calc_panel(panel.child_a, a)
			ui_calc_panel(panel.child_b, b)
		} else {
			if mouse_in_quad(ctx) {
				state.ui.panel_active = panel
				push_quad_border(ctx, {1,0,0,1}, 2)
			}
		}
	}
}