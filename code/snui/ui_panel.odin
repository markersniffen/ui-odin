package snui

import "core:fmt"

MAX_PANELS :: 40
PANEL_MARGIN :: 3

Panel :: struct {
	uid: Uid,
	ctx: Quad,
	parent: Uid,
	children: [2]Uid,
	direction: Panel_Direction,
	size: f32,
}

Panel_Direction :: enum {
	HORIZONTAL,
	VERTICAL,
}

ui_init_panels :: proc() {
	pool_init(&state.ui.panel_pool, size_of(Panel), MAX_PANELS)
	
	p1 := cast(^Panel)pool_alloc(&state.ui.panel_pool)
	p2 := cast(^Panel)pool_alloc(&state.ui.panel_pool)
	p3 := cast(^Panel)pool_alloc(&state.ui.panel_pool)
	p4 := cast(^Panel)pool_alloc(&state.ui.panel_pool)
	p5 := cast(^Panel)pool_alloc(&state.ui.panel_pool)
	p6 := cast(^Panel)pool_alloc(&state.ui.panel_pool)
	p7 := cast(^Panel)pool_alloc(&state.ui.panel_pool)

	p1.uid = 1
	p1.ctx = {0, 0, f32(state.window_size.x), f32(state.window_size.y)}
	p1.size = 0.6
	p1.children = {2, 3}
	p1.parent = 0
	p1.direction = .HORIZONTAL

	p2.uid = 2
	p2.size = 0.3
	p2.children = {6, 7}
	p2.parent = 1
	p2.direction = .VERTICAL

	p3.uid = 3
	p3.size = 0.5
	p3.children = {4, 5}
	p3.parent = 1
	p3.direction = .HORIZONTAL

	p4.uid = 4
	p4.size = 0.5
	p4.children = {0, 0}
	p4.parent = 3
	p4.direction = .HORIZONTAL

	p5.uid = 5
	p5.size = 0.5
	p5.children = {0, 0}
	p5.parent = 3
	p5.direction = .HORIZONTAL

	p6.uid = 6
	p6.size = 0.5
	p6.children = {0, 0}
	p6.parent = 2
	p6.direction = .HORIZONTAL

	p7.uid = 7
	p7.size = 0.5
	p7.children = {0, 0}
	p7.parent = 2
	p7.direction = .HORIZONTAL

	state.ui.panels[p1.uid] = p1
	state.ui.panels[p2.uid] = p2
	state.ui.panels[p3.uid] = p3
	state.ui.panels[p4.uid] = p4
	state.ui.panels[p5.uid] = p5
	state.ui.panels[p6.uid] = p6
	state.ui.panels[p7.uid] = p7
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
			if pt_in_quad({f32(state.mouse.pos.x), f32(state.mouse.pos.y)}, bar) {
				if state.mouse.left == .CLICK {
					state.ui.panel_active = panel.uid
				} else if state.mouse.left == .UP {
					state.ui.panel_active = 0
				}

				color = state.ui.col.highlight
				draw_text(fmt.tprintf("BORDER ID: %v", panel.uid), ctx, .LEFT, state.ui.col.highlight)
			}
			if state.ui.panel_active == panel.uid {
				if panel.direction == .HORIZONTAL {
					panel.size = (f32(state.mouse.pos.x)) / f32(state.window_size.x)
				} else {
					panel.size = (f32(state.mouse.pos.y) / f32(state.window_size.y))
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
				draw_text(fmt.tprintf("Panel ID: %v", panel.parent), ctx)
			}
			push_quad_border(ctx, color, 2)

		}
	}
}