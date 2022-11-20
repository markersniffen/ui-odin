package ui

import sg "../../../sokol-odin/sokol/gfx"
import sapp "../../../sokol-odin/sokol/app"
import sglue "../../../sokol-odin/sokol/glue"

import demo "../demo"

import "core:runtime"
import "core:mem"
import "core:fmt"
import lin "core:math/linalg"

MAX_VERTICES :: 8 * 2048
MAX_INDICES :: 6 * 2048

Sokol :: struct {
    pass_action: sg.Pass_Action,
    pip: sg.Pipeline,
    bind: sg.Bindings,
	vertices: []f32,
	indices: []u32,
	vindex: u32,
	iindex: u32,
	qindex: u32,
	vs_params: Vs_Params,
}

sokol :: proc() {
	sapp.run({
		init_cb = sokol_init,
		frame_cb = frame,
		event_cb = sokol_event,
		cleanup_cb = cleanup,
		width = WIDTH,
		height = HEIGHT,
		window_title = "ui-odin demo",
		icon = { sokol_default = true }
	})
}

sokol_init :: proc "c" () {
	context = runtime.default_context()

	state.sokol.vertices = make([]f32, MAX_VERTICES)
	state.sokol.indices = make([]u32, MAX_INDICES)
	
	sg.setup({ ctx = sglue.ctx() })

	state.sokol.bind.vertex_buffers[0] = sg.make_buffer({
		size = size_of(f32) * MAX_VERTICES,
		usage = .DYNAMIC,
    })
    state.sokol.bind.index_buffer = sg.make_buffer({
        type = .INDEXBUFFER,
    	size = size_of(u32) * MAX_INDICES,
        usage = .DYNAMIC,
    })

    state.sokol.pip = sg.make_pipeline({
        shader = sg.make_shader(quad_shader_desc(sg.query_backend())),
        index_type = .UINT32,
        layout = {
            attrs = {
                ATTR_vs_position = { format = .FLOAT2 },
            }
        }
    })

    // default pass action
    state.sokol.pass_action = {
        colors = {
            0 = { action = .CLEAR, value = { 0, 0.1, 0.1, 1 }}
        }
    }

	//					parent			direction	type		content						size
	ui_create_panel(nil, 				.Y,			.STATIC, 	ui_panel_file_menu, 		0.3)
	ui_create_panel(state.ui.ctx.panel, .Y,			.DYNAMIC, 	ui_panel_colors, 			0.1)
	ui_create_panel(state.ui.ctx.panel, .X,			.DYNAMIC, 	ui_lorem, 					0.5)
	// ui_create_panel(state.ui.ctx.panel, .Y,			.DYNAMIC, 	ui_panel_tab_test, 			0.3)
}

frame :: proc "c" () {
	context = runtime.default_context()
	
	state.window.size.x = sapp.width()
	state.window.size.y = sapp.height()
	state.window.quad = {0, 0, f32(sapp.width()), f32(sapp.height())}

	state.window.framebuffer.x = sapp.width()
	state.window.framebuffer.y = sapp.height()

	ui_update()
	// draw_some_quads()
	
	state.sokol.vs_params.framebuffer = {f32(state.window.size.x/2), f32(state.window.size.y/2)}

	sg.update_buffer(state.sokol.bind.vertex_buffers[0], {
		ptr = raw_data(state.sokol.vertices),
		size = size_of(f32) * u64(state.sokol.vindex),
	})

	sg.update_buffer(state.sokol.bind.index_buffer, {
		ptr = raw_data(state.sokol.indices),
		size = size_of(u32) * u64(state.sokol.iindex),
	})
	

	// RENDER HERE
    sg.begin_default_pass(state.sokol.pass_action, sapp.width(), sapp.height())
    sg.apply_pipeline(state.sokol.pip)
    sg.apply_bindings(state.sokol.bind)
    sg.apply_uniforms(.VS, SLOT_vs_params, { ptr = &state.sokol.vs_params, size = size_of(state.sokol.vs_params) })
    sg.draw(0, state.sokol.iindex, 1)
    sg.end_pass()
    sg.commit()

	state.sokol.vindex = 0
	state.sokol.iindex = 0
	state.sokol.qindex = 0
}

sokol_event :: proc "c" (e: ^sapp.Event) {
	context = runtime.default_context()
	old_mouse := state.input.mouse.pos
	state.input.mouse.pos = {e.mouse_x, e.mouse_y}
	state.input.mouse.delta = state.input.mouse.pos - old_mouse
}

cleanup :: proc "c" () {
    context = runtime.default_context()
    sg.shutdown()
}

cursor :: proc(type: Cursor_Type) {
	using sapp
	#partial switch type {
		case .NULL:
		set_mouse_cursor(.DEFAULT)
		case .ARROW:
		set_mouse_cursor(.ARROW)
		case .TEXT:
		set_mouse_cursor(.IBEAM)
		case .CROSS:
		set_mouse_cursor(.CROSSHAIR)
		case .HAND:
		set_mouse_cursor(.POINTING_HAND)
		case .X:
		set_mouse_cursor(.RESIZE_EW)
		case .Y:
		set_mouse_cursor(.RESIZE_NS)
	}
}

sokol_push_quad :: proc(quad:Quad,
						cA:			HSL=	{1,1,1,1},
						cB:			HSL=	{1,1,1,1},
						cC:			HSL=	{1,1,1,1},
						cD:			HSL=	{1,1,1,1},
						border: 		f32=	0.0, 
						uv:			Quad=	{0,0,0,0},
						texture_id:	f32=	0.0,
						clip:			Quad= {0,0,0,0},
					) 
{
	if border == 0 {

		q := quad
		vertices := [8]f32{ q.l, q.t,	q.r, q.t,	q.r, q.b,	q.l, q.b }
		copy(state.sokol.vertices[ state.sokol.vindex : state.sokol.vindex+8 ], vertices[:])
		state.sokol.vindex += 8

		qi := state.sokol.qindex * 4
		// qi = 0
		indices := [6]u32{0+qi, 1+qi, 3+qi, 1+qi, 2+qi, 3+qi}
		copy(state.sokol.indices[ state.sokol.iindex : state.sokol.iindex+6 ], indices[:])
		state.sokol.iindex += 6
		state.sokol.qindex += 1
	}
}


draw_some_quads :: proc() {
	qx : Quad = {state.input.mouse.pos.x, state.input.mouse.pos.y, state.input.mouse.pos.x + 50, state.input.mouse.pos.y + 50}
	q : Quad
	
	fb : v2 = { f32(state.window.size.x)/2, f32(state.window.size.y)/2 }

	q.l = (qx.l - fb.x) / fb.x
	q.t = (qx.t - fb.y) / -fb.y
	q.r = (qx.r - fb.x) / fb.x
	q.b = (qx.b - fb.y) / -fb.y


	sokol_push_quad({0,0,60,60})
	sokol_push_quad(qx)
}