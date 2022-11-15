package ui

import sg "../../../sokol-odin/sokol/gfx"
import sapp "../../../sokol-odin/sokol/app"
import sglue "../../../sokol-odin/sokol/glue"

import demo "../demo"

import "core:runtime"
import "core:mem"
import "core:fmt"
import lin "core:math/linalg"

Sokol :: struct {
    pip: sg.Pipeline,
    bind: sg.Bindings,
    pass_action: sg.Pass_Action,
    vertices: [^]f32,
    indices: [^]u32,
    index: int,
}

sokol :: proc() {
	sapp.run({
		init_cb = sinit,
		frame_cb = frame,
		event_cb = event,
		cleanup_cb = cleanup,
		width = WIDTH,
		height = HEIGHT,
		window_title = "ui-odin demo",
		icon = { sokol_default = true }
	})
}

sinit :: proc "c" () {
	context = runtime.default_context()

	sg.setup({ ctx = sglue.ctx() })
	
	// a vertex buffer
	state.sokol.bind.vertex_buffers[0] = sg.make_buffer({
		size = mem.Megabyte * 2,
		usage = .DYNAMIC,
	})

	// an index buffer
	state.sokol.bind.index_buffer = sg.make_buffer({
		type = .INDEXBUFFER,
		size = mem.Megabyte * 2,
		usage = .DYNAMIC,
	})

	// a shader and pipeline object
	state.sokol.pip = sg.make_pipeline({
		shader = sg.make_shader(quad_shader_desc(sg.query_backend())),
		index_type = .UINT32,
		layout = {
		   attrs = {
				ATTR_vs_position = { format = .FLOAT3 },
				ATTR_vs_uv = { format = .FLOAT2 },
				ATTR_vs_color = { format = .FLOAT4 },
				ATTR_vs_texID = { format = .FLOAT },
				ATTR_vs__clip = { format = .FLOAT4 }
		   }
		}
	})

	// default pass action
	state.sokol.pass_action = {
		colors = {
		   0 = { action = .CLEAR, value = { 0, 0.1, 0.1, 1 }}
		}
	}

	//					parent			 	   direction	type			content						size
	ui_create_panel(nil, 					.Y,			.STATIC, 	ui_panel_file_menu, 		0.3)
	ui_create_panel(state.ui.ctx.panel, .Y,			.DYNAMIC, 	ui_panel_colors, 			0.1)
	ui_create_panel(state.ui.ctx.panel, .X,			.DYNAMIC, 	ui_lorem, 					0.5)
	// ui_create_panel(state.ui.ctx.panel, .Y,			.DYNAMIC, 	ui_panel_tab_test, 	0.3)
}

frame :: proc "c" () {
	context = runtime.default_context()
	
	state.window.size.x = sapp.width()
	state.window.size.y = sapp.height()
	state.window.quad = {0, 0, f32(sapp.width()), f32(sapp.height())}

	state.window.framebuffer.x = sapp.width()
	state.window.framebuffer.y = sapp.height()

	update()

	if state.render.layers[0].v_index > 0 && state.render.layers[0].i_index > 0 {
		sg.update_buffer(state.sokol.bind.vertex_buffers[0], { ptr = state.render.layers[0].vertices, size = size_of(f32) * u64(state.render.layers[0].v_index) } )
		sg.update_buffer(state.sokol.bind.index_buffer, { ptr = state.render.layers[0].indices, size = size_of(u32) * u64(state.render.layers[0].i_index) } )
	}

	vs_params : Vs_Params 
	vs_params.framebuffer_res = {f32(state.window.framebuffer.x), f32(state.window.framebuffer.x)}
	x := f32(state.window.framebuffer.x / state.window.size.x)
	y := f32(state.window.framebuffer.y / state.window.size.y)
	vs_params.multiplier = {x,y}

	// fmt.println(state.render.layers[0].vertices[:48])

	sg.begin_default_pass(state.sokol.pass_action, sapp.width(), sapp.height())
	sg.apply_pipeline(state.sokol.pip)
	sg.apply_bindings(state.sokol.bind)
	sg.draw(0, state.render.layers[0].i_index, 1)
	sg.end_pass()
	sg.commit()

	for i in 0..=1 {
		state.render.layers[i].v_index = 0
		state.render.layers[i].i_index = 0
		state.render.layers[i].quad_index = 0
	}
}

event :: proc "c" (e: ^sapp.Event) {
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

sokol_push_quadx :: proc(quad:Quad,
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
	vertices := [?]f32 {
        // positions         // colors
        -0.5,  0.5, 0.5,     1.0, 0.0, 0.0, 1.0,
         0.5,  0.5, 0.5,     0.0, 1.0, 0.0, 1.0,
         0.5, -0.5, 0.5,     0.0, 0.0, 1.0, 1.0,
        -0.5, -0.5, 0.5,     1.0, 1.0, 0.0, 1.0,
    }

	indices := [?]u32 { 0, 1, 2,  0, 2, 3 }

	copy(state.sokol.vertices[:len(vertices)], vertices[:])
	copy(state.sokol.indices[:6], indices[:])

	state.sokol.index = len(indices)

}

sokol_push_quad :: 	proc(
							quad:Quad,
							_cA:			HSL,
							_cB:			HSL,
							_cC:			HSL,
							_cD:			HSL,
							border: 		f32, 
							uv:			Quad,
							texture_id:	f32,
							clip:			Quad,
							)
{

	vertex_arrays: [4][56]f32

	cA : v4 = v4(lin.vector4_hsl_to_rgb(_cA.h, _cA.s, _cA.l, _cA.a))
	cB : v4 = v4(lin.vector4_hsl_to_rgb(_cB.h, _cB.s, _cB.l, _cB.a))
	cC : v4 = v4(lin.vector4_hsl_to_rgb(_cC.h, _cC.s, _cC.l, _cC.a))
	cD : v4 = v4(lin.vector4_hsl_to_rgb(_cD.h, _cD.s, _cD.l, _cD.a))

	if border == 0
	{
		vertex_arrays[0]  = { 
				quad.l,quad.t,0,	uv.l,uv.t,	cA[0],cA[1],cA[2],cA[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
				quad.r,quad.t,0,	uv.r,uv.t,	cB[0],cB[1],cB[2],cB[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
				quad.r,quad.b,0,	uv.r,uv.b,	cD[0],cD[1],cD[2],cD[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
				quad.l,quad.b,0,	uv.l,uv.b,	cC[0],cC[1],cC[2],cC[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
		}
	} else {

		inner: Quad = {quad.l + border,quad.t + border,quad.r - border,quad.b - border,}

		vertex_arrays = {
			{ 
				quad.l,quad.t,0, 		0,0, cA[0],cA[1],cA[2],cA[3], texture_id, clip.l,clip.t,clip.r,clip.b,
				quad.r,quad.t,0, 		0,0, cB[0],cB[1],cB[2],cB[3], texture_id, clip.l,clip.t,clip.r,clip.b,
				inner.r,inner.t,0, 	0,0, cB[0],cB[1],cB[2],cB[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
				inner.l,inner.t,0, 	0,0, cA[0],cA[1],cA[2],cA[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
			},
			{ 
				quad.r,quad.t,0, 		0,0, cB[0],cB[1],cB[2],cB[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
				quad.r,quad.b,0, 		0,0, cD[0],cD[1],cD[2],cD[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
				inner.r,inner.b,0, 	0,0, cD[0],cD[1],cD[2],cD[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
				inner.r,inner.t,0, 	0,0, cB[0],cB[1],cB[2],cB[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
			},
			{ 
				quad.r,quad.b,0, 		0,0, cD[0],cD[1],cD[2],cD[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
				quad.l,quad.b,0, 		0,0, cC[0],cC[1],cC[2],cC[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
				inner.l,inner.b,0, 	0,0, cC[0],cC[1],cC[2],cC[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
				inner.r,inner.b,0, 	0,0, cD[0],cD[1],cD[2],cD[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
			},
			{ 
				quad.l,quad.b,0, 		0,0, cC[0],cC[1],cC[2],cC[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
				quad.l,quad.t,0, 		0,0, cA[0],cA[1],cA[2],cA[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
				inner.l,inner.t,0, 	0,0, cA[0],cA[1],cA[2],cA[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
				inner.l,inner.b,0, 	0,0, cC[0],cC[1],cC[2],cC[3],	texture_id, clip.l,clip.t,clip.r,clip.b,
			},
		}
	}
		
	for vertex_array, i in &vertex_arrays
	{
		if border == 0 && i > 0 do break
	   layer := &state.render.layers[state.render.layer_index]

		quad_index := u32(layer.quad_index * 4)
		indices :[6]u32 = {0+quad_index, 1+quad_index, 3+quad_index, 1+quad_index, 2+quad_index, 3+quad_index}
		
		copy(layer.vertices[layer.v_index:layer.v_index+56], vertex_array[:])
		layer.v_index += 56
		
		copy(layer.indices[layer.i_index:layer.i_index+6], indices[:])
		layer.i_index += 6
		layer.quad_index += 1
	}

	fmt.println("UPDATING", state.render.layers[state.render.layer_index].quad_index)
}