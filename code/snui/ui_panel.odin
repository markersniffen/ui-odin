package snui

import "core:fmt"

MAX_PANELS :: 40
PANEL_MARGIN :: 2

Panel :: struct {
	uid: Uid,
	ctx: Quad,
	parent: Uid,
	children: [2]Uid,
	direction: Panel_Direction,
	size: f32,
	type: Panel_Type,
}

Panel_Direction :: enum {
	HORIZONTAL,
	VERTICAL,
}

Panel_Type :: enum {
	DEBUG,
	TEMP,
}

ui_create_panel :: proc(active_panel_uid: Uid, direction:Panel_Direction=.HORIZONTAL) -> Uid
{
	active_panel, active_panel_ok := state.ui.panels[active_panel_uid]
	if active_panel_ok {
		new_parent := cast(^Panel)pool_alloc(&state.ui.panel_pool)
		new_parent.uid = new_uid()
		new_parent.size = active_panel.size
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

ui_calc_panel :: proc(uid: Uid, ctx: Quad)
{
	panel, ok := state.ui.panels[uid]
	if ok
	{
		fmt.println("Calcing ", uid, panel)
		panel.ctx = ctx

		child_a, cok := state.ui.panels[panel.children[0]]
		fmt.println(cok)
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
			if pt_in_quad({f32(state.mouse.pos.x), f32(state.mouse.pos.y)}, bar) {
				if state.mouse.left == .CLICK {
					state.ui.panel_active = panel.uid
				}

				color = state.ui.col.highlight
				draw_text(fmt.tprintf("BORDER ID: %v", panel.uid), ctx, .LEFT, state.ui.col.highlight)
			}
			if state.mouse.left == .UP {
				state.ui.panel_active = 0
			}
			if state.ui.panel_active == panel.uid {
				if panel.direction == .HORIZONTAL {
					panel.size = (f32(state.mouse.pos.x) - ctx.l) * (1 / (ctx.r - ctx.l))
				} else {
					panel.size = (f32(state.mouse.pos.y) - ctx.t) * (1 / (ctx.b - ctx.t))
				}
			}
			push_quad_solid(bar, color)
			ui_calc_panel(panel.children[0], a)
			ui_calc_panel(panel.children[1], b)
		} else {
			quad: Quad

			parent, parent_ok := state.ui.panels[panel.parent]

			color :v4= {0.5,0.5,0.5,1}
			if pt_in_quad({f32(state.mouse.pos.x), f32(state.mouse.pos.y)}, ctx)
			{
				color = state.ui.col.hot
				draw_text(fmt.tprintf("Panel ID: %v", panel.uid), ctx)
			}
			push_quad_border(ctx, color, 2)

			ui_draw_panel(panel.uid, ctx)
		}
	}
}

ui_draw_panel :: proc(panel_uid: Uid, ctx: Quad)
{
	if state.ui.panels[panel_uid].type == .DEBUG do ui_panel_debug(ctx)
}

ui_panel_debug :: proc(ctx: Quad)
{
	// NOTE DEBUG
	debug_quad:= ctx
	draw_text("DEBUG:", debug_quad)
	debug_quad.t += state.ui.line_space
	debug_quad.b += state.ui.line_space
	draw_text(fmt.tprintf("Mouse Pos: %v", state.mouse.pos), debug_quad)
	debug_quad.t += state.ui.line_space
	debug_quad.b += state.ui.line_space
	for p in state.ui.panels {
		draw_text(fmt.tprintf("%v", state.ui.panels[p]), debug_quad)
		debug_quad.t += state.ui.line_space
		debug_quad.b += state.ui.line_space
	}
	draw_text(fmt.tprintf("%v", state.ui.panel_master), debug_quad)
	debug_quad.t += state.ui.line_space
	debug_quad.b += state.ui.line_space
}