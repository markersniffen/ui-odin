package snui

import "core:fmt"

MAX_PANELS :: 20

Panel :: struct {
	uid: Uid,
	ctx: Quad,
	size: f32,
	children: [2]Uid,
	type: int,
	direction: Panel_Direction,
	offset: v2,
}

Panel_Direction :: enum {
	HORIZONTAL,
	VERTICAL,
}

ui_init_panels :: proc() {
	p1 := &state.ui.panel_memory[0]
	p2 := &state.ui.panel_memory[1]
	p3 := &state.ui.panel_memory[2]
	p4 := &state.ui.panel_memory[3]
	p5 := &state.ui.panel_memory[4]
	p6 := &state.ui.panel_memory[5]
	p7 := &state.ui.panel_memory[6]

	p1.uid = 1
	p1.ctx = {0, 0, f32(state.window_size.x), f32(state.window_size.y)}
	p1.size = 0.6
	p1.children = {2, 3}
	p1.direction = .HORIZONTAL

	p2.uid = 2
	p2.size = 0.3
	p2.children = {6, 7}
	p2.direction = .HORIZONTAL

	p3.uid = 3
	p3.size = 0.5
	p3.children = {4, 5}
	p3.direction = .VERTICAL

	p4.uid = 4
	p4.size = 0.5
	p4.children = {0, 0}
	p4.direction = .VERTICAL

	p5.uid = 5
	p5.size = 0.5
	p5.children = {0, 0}
	p5.direction = .VERTICAL

	p6.uid = 6
	p6.size = 0.5
	p6.children = {0, 0}
	p6.direction = .HORIZONTAL

	p7.uid = 7
	p7.size = 0.5
	p7.children = {0, 0}
	p7.direction = .VERTICAL

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
	fmt.println("About to cal panel ", uid)
	p, ok := state.ui.panels[uid]
	if ok
	{
		p.ctx = ctx

		CTXa: Quad
		CTXb: Quad

		child_a, cok := state.ui.panels[p.children[0]]
		if cok
		{
			if child_a.direction == .HORIZONTAL
			{
				CTXa	= { p.ctx.l, p.ctx.t, ((p.ctx.r - p.ctx.l) * p.size) + p.ctx.l, p.ctx.b}
				CTXb	= { CTXa.r, CTXa.t, p.ctx.r, p.ctx.b }
			} else {				  // plus key
				CTXa	= { p.ctx.l, p.ctx.t, p.ctx.r, p.ctx.b - ((p.ctx.b - p.ctx.t) * p.size) }
				CTXb	= { CTXa.l, CTXa.b, CTXa.r, p.ctx.b }
			}
			// Show.State.UIPanelCTX = CTXa
			fmt.println("sending into..", p.children[0], CTXa)
			ui_calc_panel(p.children[0], CTXa)
			// Show.State.UIPanelCTX = CTXb
			ui_calc_panel(p.children[1], CTXb)
		} else {
			width := p.ctx.r - p.ctx.l
			height := p.ctx.b - p.ctx.t
			WindowPos : [4]i32 = { i32(p.ctx.l), i32(p.ctx.t), i32(width), i32(height) }
			NewCTX :v4 = {0, 0, width, height}
			push_quad_border(p.ctx, state.ui.col.active, 4)
			draw_text(fmt.tprintf("Panel ID: %v", p.uid), p.ctx)
			// UIPanel(UID)
			// OpenglRenderPanel(WindowPos)

		}
	}
}