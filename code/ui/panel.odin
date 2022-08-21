package ui

import "core:fmt"

MAX_PANELS :: 40
PANEL_MARGIN :: 2

Panel :: struct {
	uid: Uid,
	ctx: Quad,
	parent: Uid,
	children: [2]Uid,
	direction: Direction,
	size: f32,
	type: Panel_Type,

	box: ^Box,
}

Direction :: enum {
	HORIZONTAL,
	VERTICAL,
}

ui_create_panel :: proc(active_panel_uid: Uid, direction:Direction=.HORIZONTAL, type: Panel_Type=.TEMP, size:f32=0.5) -> Uid
{
	active_panel, active_panel_ok := state.ui.panels[active_panel_uid]
	if active_panel_ok {
		new_parent := cast(^Panel)pool_alloc(&state.ui.panel_pool)
		new_parent.uid = new_uid()
		new_parent.size = size
		new_parent.children[0] = active_panel.uid
		new_parent.parent = active_panel.parent
		new_parent.direction = direction
		state.ui.panels[new_parent.uid] = new_parent

		active_panel.parent = new_parent.uid
		active_panel.children = {0,0}
		active_panel.size = 0.5 

		panel := cast(^Panel)pool_alloc(&state.ui.panel_pool)
		panel.uid = new_uid()
		panel.size = 0.5
		panel.parent = new_parent.uid
		panel.direction = direction
		panel.type = type
		state.ui.panels[panel.uid] = panel

		new_parent.children[1] = panel.uid

		if active_panel_uid == state.ui.panel_master {
			state.ui.panel_master = new_parent.uid
		}

		grandpa, grandpa_ok:= state.ui.panels[new_parent.parent]
		if grandpa_ok {
			if grandpa.children[0] == active_panel_uid {
				grandpa.children[0] = new_parent.uid
			} else {
				grandpa.children[1] = new_parent.uid
			}
		}

		return panel.uid
	} else {
		if active_panel_uid == 0 {
			panel := cast(^Panel)pool_alloc(&state.ui.panel_pool)
			panel.uid = new_uid()
			panel.size = 0.5
			panel.parent = 0
			panel.direction = direction
			state.ui.panels[panel.uid] = panel
			return panel.uid
		}
	}
	return 0
}

ui_delete_panel :: proc(panel_uid: Uid)
{
	fmt.println("trying to delete ", panel_uid)
	panel, ok := state.ui.panels[panel_uid]
	if ok
	{
		parent, parent_ok := state.ui.panels[panel.parent]
		if parent_ok
		{
			grandpa, grandpa_ok := state.ui.panels[parent.parent]
			if grandpa_ok
			{
				sibling_uid: Uid
				if parent.children[0] == panel_uid
				{
					sibling_uid = parent.children[1]
				} else {
					sibling_uid = parent.children[0]
				}
				sibling, sibling_ok := state.ui.panels[sibling_uid]
				if sibling_ok
				{
					sibling.parent = parent.parent
					for child, c in grandpa.children
					{
						if child == panel.parent do grandpa.children[c] = sibling_uid
					}
					delete_key(&state.ui.panels, parent.uid)
					delete_key(&state.ui.panels, panel_uid)
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

ui_calc_panel :: proc(uid: Uid, ctx: Quad)
{
	panel, ok := state.ui.panels[uid]
	if ok
	{
		panel.ctx = ctx
		child_a, cok := state.ui.panels[panel.children[0]]
		if cok
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
			if pt_in_quad({f32(state.mouse.pos.x), f32(state.mouse.pos.y)}, bar) {
				if state.mouse.left == .CLICK do state.ui.panel_active = panel.uid
				color = state.ui.col.highlight
			}
			if state.mouse.left == .UP do state.ui.panel_active = 0
			if state.ui.panel_active == panel.uid {
				if panel.direction == .HORIZONTAL {
					panel.size = (f32(state.mouse.pos.x) - ctx.l) * (1 / (ctx.r - ctx.l))
				} else {
					panel.size = (f32(state.mouse.pos.y) - ctx.t) * (1 / (ctx.b - ctx.t))
				}
			}
			push_quad_solid(bar, color)
			//////////////////////////////

			ui_calc_panel(panel.children[0], a)
			ui_calc_panel(panel.children[1], b)
		} else {
			quad: Quad
			parent, parent_ok := state.ui.panels[panel.parent]

			// TEMP CODE /////////////////
			// color :v4= {0.5,0.5,0.5,1}
			// if pt_in_quad({f32(state.mouse.pos.x), f32(state.mouse.pos.y)}, ctx)
			// {
			// 	color = state.ui.col.hot
			// 	draw_text(fmt.tprintf("Panel ID: %v", panel.uid), ctx)
			// }
			// push_quad_border(ctx, color, 2)
			//////////////////////////////

			ui_draw_panel(panel.uid)
		}
	}
}

ui_draw_panel :: proc(panel_uid: Uid)
{
	#partial switch state.ui.panels[panel_uid].type {
		case .DEBUG: ui_panel_debug(panel_uid)
		case .TEMP: ui_panel_temp(panel_uid)
	}
}

