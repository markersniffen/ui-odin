package ui

import sg "../../../sokol-odin/sokol/gfx"
import sapp "../../../sokol-odin/sokol/app"
import sglue "../../../sokol-odin/sokol/glue"

import demo "../demo"

import "core:runtime"
import "core:mem"
import "core:fmt"
import "core:os"
import "core:strings"
import lin "core:math/linalg"

MAX_VERTICES :: 8 * 2048 * 40
MAX_INDICES :: 6 * 2048 * 40

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

Window :: struct {
	title: string,
	size: v2i,
	framebuffer: v2i,
	quad: Quad,
}

Cursor_Type :: enum {
	NULL,
	ACTIVE,
	ARROW,
	TEXT,
	HAND,
	CROSS,
	X,
	Y,
}

Quad :: struct {
	l: f32,
	t: f32,
	r: f32,
	b: f32,
}

sokol :: proc() {
	sapp.run({
		icon = { sokol_default = true },
		width = state.window.size.x,
		height = state.window.size.y,
		window_title = strings.clone_to_cstring(state.window.title),

		init_cb = sokol_init,
		frame_cb = sokol_frame,
		event_cb = sokol_event,
		cleanup_cb = sokol_cleanup,
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
                ATTR_vs_color = { format = .FLOAT4 },
                ATTR_vs_uv = { format = .FLOAT2 },
                ATTR_vs_tex_id = { format = .FLOAT },
                ATTR_vs_clip_quad = { format = .FLOAT4 },
            },
        },
        cull_mode = .BACK,
        depth = {
        	compare = .LESS_EQUAL,
        	write_enabled = true,
        },
        colors = {
			0 = {
				blend = {
					enabled = true,
					src_factor_rgb = .SRC_ALPHA,
					src_factor_alpha = .SRC_ALPHA,
					dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
					dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
				},
			},
        },
    })

	ui_init_font()

    // default pass action
    state.sokol.pass_action = {
        colors = {
            0 = { action = .CLEAR, value = { 0, 0, 0, 1 }},
        },
    }

	state.init()
}

sokol_frame :: proc "c" () {
	context = runtime.default_context()
	
	cursor(.ARROW)

	state.window.size.x = sapp.width()
	state.window.size.y = sapp.height()
	state.window.quad = {0, 0, f32(sapp.width()), f32(sapp.height())}

	// state.window.framebuffer.x = sapp.width()
	// state.window.framebuffer.y = sapp.height()
	
	ui_update()
	
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

	mouse_buttons: [3]^Button = { &state.input.mouse.left, &state.input.mouse.right, &state.input.mouse.middle }
	for mouse_button, index in mouse_buttons {
		if mouse_button^ == .CLICK do mouse_button^ = .DRAG
		if mouse_button^ == .RELEASE do mouse_button^ = .UP
	}
	state.input.mouse.scroll = {0,0}

	state.sokol.vindex = 0
	state.sokol.iindex = 0
	state.sokol.qindex = 0

	state.ui.last_char = 0

	state.frame()
}

sokol_event :: proc "c" (e: ^sapp.Event) {
	context = runtime.default_context()
	old_mouse := state.input.mouse.pos
	state.input.mouse.pos = {e.mouse_x, e.mouse_y}
	// state.input.mouse.delta = state.input.mouse.pos - old_mouse
	state.input.mouse.delta = {e.mouse_dx, e.mouse_dy}

	if e.type == .KEY_UP || e.type == .KEY_DOWN {
		keystate : bool
		if e.type == .KEY_UP {
			keystate = false
		} else {
			keystate = true
		}

		#partial switch e.key_code {
			case .LEFT:			state.input.keys.left = keystate
			case .RIGHT:		state.input.keys.right = keystate
			case .UP:			state.input.keys.up = keystate
			case .DOWN:			state.input.keys.down = keystate
			case .ESCAPE:		state.input.keys.escape = keystate
			case .TAB:			state.input.keys.tab = keystate
			case .ENTER:		state.input.keys.enter = keystate
			case .SPACE:		state.input.keys.space = keystate
			case .BACKSPACE:	state.input.keys.backspace = keystate
			case .DELETE:		state.input.keys.delete = keystate
			case .HOME:			state.input.keys.home = keystate
			case .END:			state.input.keys.end = keystate
			case .KP_ENTER:		state.input.keys.enter = keystate
			case .KP_SUBTRACT:	state.input.keys.n_minus = keystate
			case .KP_ADD:		state.input.keys.n_plus = keystate
			case .LEFT_ALT:		state.input.keys.alt = keystate
			case .RIGHT_ALT:	state.input.keys.alt = keystate
			case .LEFT_CONTROL:	state.input.keys.ctrl = keystate
			case .RIGHT_CONTROL:state.input.keys.ctrl = keystate
			case .LEFT_SHIFT:	state.input.keys.shift = keystate
			case .RIGHT_SHIFT:	state.input.keys.shift = keystate

			case .A:			state.input.keys.a = keystate
			case .C:			state.input.keys.c = keystate
			case .X:			state.input.keys.x = keystate
			case .V:			state.input.keys.v = keystate
		}
	} else if e.type == .MOUSE_DOWN || e.type == .MOUSE_UP {
		button := &state.input.mouse.left
		#partial switch e.mouse_button {
			case .MIDDLE:
				button = &state.input.mouse.middle
			case .RIGHT:
				button = &state.input.mouse.right
		}

		if e.type == .MOUSE_DOWN {
			button^ = .CLICK
		} else if e.type == .MOUSE_UP {
			button^ = .RELEASE
		}
	} else if e.type == .MOUSE_SCROLL {
		if shift() {
			state.input.mouse.scroll = { e.scroll_y, 0 }
		} else {
			state.input.mouse.scroll = { e.scroll_x, e.scroll_y }
		}
	} else if e.type == .CHAR {
		if !state.input.keys.ctrl && !state.input.keys.alt {
			state.ui.last_char = rune(e.char_code)
		} else {
			state.ui.last_char = -1
		}
	}
}

sokol_cleanup :: proc "c" () {
    context = runtime.default_context()
    sg.shutdown()
    free(state)
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

cursor_size :: proc(axis: Axis) {
	if axis == .X {
		cursor(.X)
	} else {
		cursor(.Y)
	}
}

sokol_push_quad :: proc(quad:Quad,
						_cA:			HSL=	{1,1,1,1},
						_cB:			HSL=	{1,1,1,1},
						_cC:			HSL=	{1,1,1,1},
						_cD:			HSL=	{1,1,1,1},
						border: 		f32=	0.0, 
						uv:			Quad=	{0,0,0,0},
						texture_id:	f32=	0.0,
						clip:			Quad= {0,0,0,0},
					) 
{
	NUM_ELEMENTS :: 52
	if state.sokol.vindex < MAX_VERTICES-NUM_ELEMENTS {
		vertex_arrays: [4][NUM_ELEMENTS]f32

		cA : v4 = v4(lin.vector4_hsl_to_rgb(_cA.h, _cA.s, _cA.l, _cA.a))
		cB : v4 = v4(lin.vector4_hsl_to_rgb(_cB.h, _cB.s, _cB.l, _cB.a))
		cC : v4 = v4(lin.vector4_hsl_to_rgb(_cC.h, _cC.s, _cC.l, _cC.a))
		cD : v4 = v4(lin.vector4_hsl_to_rgb(_cD.h, _cD.s, _cD.l, _cD.a))
		
		if border == 0 {
			vertex_arrays[0]  = { 
				quad.l, quad.t,	cA[0], cA[1], cA[2], cA[3], uv.l, uv.t, texture_id, clip.l, clip.t, clip.r, clip.b,
				quad.r, quad.t,	cB[0], cB[1], cB[2], cB[3], uv.r, uv.t, texture_id, clip.l, clip.t, clip.r, clip.b,
				quad.r, quad.b,	cC[0], cC[1], cC[2], cC[3], uv.r, uv.b, texture_id, clip.l, clip.t, clip.r, clip.b,
				quad.l, quad.b,	cD[0], cD[1], cD[2], cD[3], uv.l, uv.b, texture_id, clip.l, clip.t, clip.r, clip.b,
			}
		} else {
			inner: Quad = {quad.l + border,quad.t + border,quad.r - border,quad.b - border,}
			vertex_arrays = {
				{
					quad.l,		quad.t,		cA[0], cA[1], cA[2], cA[3], 0,0, texture_id, clip.l, clip.t, clip.r, clip.b,
					quad.r,		quad.t,		cB[0], cB[1], cB[2], cB[3], 0,0, texture_id, clip.l, clip.t, clip.r, clip.b,
					inner.r,	inner.t,	cB[0], cB[1], cB[2], cB[3], 0,0, texture_id, clip.l, clip.t, clip.r, clip.b,
					inner.l,	inner.t,	cA[0], cA[1], cA[2], cA[3], 0,0, texture_id, clip.l, clip.t, clip.r, clip.b,
				},
				{
					quad.r,		quad.t,		cB[0], cB[1], cB[2], cB[3], 0,0, texture_id, clip.l, clip.t, clip.r, clip.b,
					quad.r,		quad.b,		cD[0], cD[1], cD[2], cD[3], 0,0, texture_id, clip.l, clip.t, clip.r, clip.b,
					inner.r,	inner.b,	cD[0], cD[1], cD[2], cD[3], 0,0, texture_id, clip.l, clip.t, clip.r, clip.b,
					inner.r,	inner.t,	cB[0], cB[1], cB[2], cB[3], 0,0, texture_id, clip.l, clip.t, clip.r, clip.b,
				},
				{
					quad.r,		quad.b,		cD[0], cD[1], cD[2], cD[3], 0,0, texture_id, clip.l, clip.t, clip.r, clip.b,
					quad.l,		quad.b,		cC[0], cC[1], cC[2], cC[3], 0,0, texture_id, clip.l, clip.t, clip.r, clip.b,
					inner.l,	inner.b,	cC[0], cC[1], cC[2], cC[3], 0,0, texture_id, clip.l, clip.t, clip.r, clip.b,
					inner.r,	inner.b,	cD[0], cD[1], cD[2], cD[3], 0,0, texture_id, clip.l, clip.t, clip.r, clip.b,
				},
				{
					quad.l,		quad.b,		cC[0], cC[1], cC[2], cC[3], 0,0, texture_id, clip.l, clip.t, clip.r, clip.b,
					quad.l,		quad.t,		cA[0], cA[1], cA[2], cA[3], 0,0, texture_id, clip.l, clip.t, clip.r, clip.b,
					inner.l,	inner.t,	cA[0], cA[1], cA[2], cA[3], 0,0, texture_id, clip.l, clip.t, clip.r, clip.b,
					inner.l,	inner.b,	cC[0], cC[1], cC[2], cC[3], 0,0, texture_id, clip.l, clip.t, clip.r, clip.b,
				},
			}
		}

		for vertex_array, i in &vertex_arrays {
			if border == 0 && i >= 1 do break

			copy(state.sokol.vertices[ state.sokol.vindex : state.sokol.vindex+NUM_ELEMENTS ], vertex_array[:])
			state.sokol.vindex += NUM_ELEMENTS

			qi := state.sokol.qindex * 4
			indices := [6]u32{0+qi, 1+qi, 3+qi, 1+qi, 2+qi, 3+qi}
			copy(state.sokol.indices[ state.sokol.iindex : state.sokol.iindex+6 ], indices[:])
			state.sokol.iindex += 6
			state.sokol.qindex += 1
		}
	}
}

sokol_load_font_texture :: proc(font: ^Font, image: rawptr) -> bool {
	state.sokol.bind.fs_images[font.texture_unit] = sg.make_image({
	    width = font.texture_size,
	    height = font.texture_size,
	    pixel_format = .R8,
	    data = { subimage = { 0 = { 0 = { ptr = image, size = u64(font.texture_size * font.texture_size) } } } },
	})
	return true
}

push_quad :: proc(quad:Quad,
						cA:			HSL=	{1,1,1,1},
						cB:			HSL=	{1,1,1,1},
						cC:			HSL=	{1,1,1,1},
						cD:			HSL=	{1,1,1,1},
						border: 		f32=	0.0, 
						uv:			Quad=	{0,0,0,0},
						texture_id:	f32=	0.0,
						clip:			Quad= {0,0,0,0},
					) {
	sokol_push_quad(quad, cA, cB, cC, cD,border, uv, texture_id,	clip)
}

push_quad_solid :: proc(quad: Quad, color:HSL, clip: Quad) {
	push_quad(quad,	color, color, color, color, 0, {0,0,0,0}, 0, clip)
}

push_quad_gradient_h :: proc(quad: Quad, color_left:HSL, color_right:HSL, clip: Quad) {
	push_quad(quad,	color_left, color_right, color_left, color_right, 0, {0,0,0,0}, 0, clip)
}

push_quad_gradient_v :: proc(quad: Quad, color_top:HSL, color_bottom:HSL, clip:Quad) {
	push_quad(quad,	color_top, color_top, color_bottom, color_bottom, 0, {0,0,0,0}, 0, clip)
}

push_quad_border :: proc(quad: Quad, color:HSL, border: f32=2, clip: Quad) {
	push_quad(quad,	color, color, color, color, border, {0,0,0,0}, 0, clip)
}

push_quad_font :: proc(quad: Quad, color:HSL, uv:Quad, font_icon:f32, clip: Quad) {
	when PROFILER do tracy.ZoneNC("quad font", 0x0000ff)
	push_quad(quad,	color, color, color, color, 0, uv, font_icon, clip)
}

pt_in_quad 	:: proc(pt: v2, quad: Quad) -> bool {
	result := false;
	if pt.x >= quad.l && pt.y >= quad.t && pt.x <= quad.r && pt.y <= quad.b do result = true;
	return result;
}

quad_in_quad	:: proc(quad_a, quad_b: Quad) -> bool {
	result := false
	if pt_in_quad({quad_a.l,quad_a.t}, quad_b) || pt_in_quad({quad_a.r, quad_a.b}, quad_b) do result = true
	return result
}

quad_full_in_quad	:: proc(quad_a, quad_b: Quad) -> bool {
	result := false
	if pt_in_quad({quad_a.l, quad_a.t}, quad_b) && pt_in_quad({quad_a.r, quad_a.b}, quad_b) do result = true
	return result
}

quad_clamp_or_reject :: proc (quad_a, quad_b: Quad) -> (Quad, bool) {
	clamped := quad_clamp_to_quad(quad_a, quad_b)

	if (clamped.l == clamped.r) || (clamped.t == clamped.b) {
		return clamped, false
	}
	return clamped, true
}

quad_clamp_to_quad :: proc (quad, quad_b: Quad) -> Quad {
	result: Quad = quad
	result.l = clamp(quad.l, quad_b.l, quad_b.r)
	result.t = clamp(quad.t, quad_b.t, quad_b.b)
	result.r = clamp(quad.r, quad_b.l, quad_b.r)
	result.b = clamp(quad.b, quad_b.t, quad_b.b)
	return result
}

pt_offset_quad :: proc(pt: v2, quad: Quad) -> Quad {
	return {quad.l + pt.x, quad.t + pt.y, quad.r + pt.x, quad.b + pt.y}
}