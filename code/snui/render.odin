package snui

import "core:fmt"
import "core:mem"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

Gl :: struct
{
	shader: u32,

	vertices: []f32,
	vertex_buffer: u32,
	vertex_index: int,

	indices: []u32,
	index_buffer: u32,
	index_index: int,
	quad_index: int,
}

Quad :: struct
{
	l: f32,
	t: f32,
	r: f32,
	b: f32,
}

opengl_init :: proc()
{
	gl.load_up_to(3, 3, glfw.gl_set_proc_address)
	gl.Enable(gl.BLEND)
	gl.Enable(gl.SCISSOR_TEST)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	gl.GenBuffers(1, &state.render.vertex_buffer)
	state.render.vertices = make_slice([]f32, mem.Megabyte * 2)
	gl.GenBuffers(1, &state.render.index_buffer)
	state.render.indices = make([]u32, mem.Megabyte * 2)

	shader_success : bool
	state.render.shader, shader_success = gl.load_shaders_source(UIMAIN_VS, UIMAIN_FRAG)
	if !shader_success do fmt.println("UI shader did not compile!")
}

render :: proc()
{
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	gl.ClearColor(0, 0, 0.2, 1)
	gl.Viewport(0, 0, i32(state.window_size.x), i32(state.window_size.y))
	gl.Scissor(0, 0, i32(state.window_size.x), i32(state.window_size.y))
	gl.Clear(gl.COLOR_BUFFER_BIT)

	gl.UseProgram(state.render.shader)
	// gl.BindTexture(gl.TEXTURE_2D, state.Show.State.glState.STBTexture)

	gl.BindBuffer(gl.ARRAY_BUFFER, state.render.vertex_buffer)
	gl.BufferData(gl.ARRAY_BUFFER, state.render.vertex_index * size_of(f32), &state.render.vertices[0], gl.STATIC_DRAW)
	
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 10 * size_of(f32), 0 * size_of(f32))
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 10 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(2, 4, gl.FLOAT, gl.FALSE, 10 * size_of(f32), 5 * size_of(f32))
	gl.EnableVertexAttribArray(2)
	gl.VertexAttribPointer(3, 1, gl.FLOAT, gl.FALSE, 10 * size_of(f32), 9 * size_of(f32))
	gl.EnableVertexAttribArray(3)

	window_res := gl.GetUniformLocation(state.render.shader, "window_res")
	gl.Uniform2f(window_res, f32(state.window_size.x)/2, f32(state.window_size.y)/2)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, state.render.index_buffer)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, state.render.index_index * size_of(u32), &state.render.indices[0], gl.STATIC_DRAW)

	gl.DrawElements(gl.TRIANGLES, i32(state.render.index_index), gl.UNSIGNED_INT, nil)
	glfw.SwapBuffers(state.window)

	state.render.vertex_index = 0
	state.render.index_index = 0
	state.render.quad_index = 0
}

push_quad :: proc(quad:Quad, c:v4, border: f32=0.0, uv:Quad={0,0,0,0})
{
	vertex_arrays: [4][40]f32
	if border == 0
	{
		vertex_arrays[0]  = { 
				quad.l,quad.b,0,	uv.l,uv.b,	c[0],c[1],c[2],c[3],	0,
				quad.l,quad.t,0,	uv.l,uv.t,	c[0],c[1],c[2],c[3],	0,
				quad.r,quad.t,0,	uv.r,uv.t,	c[0],c[1],c[2],c[3],	0,
				quad.r,quad.b,0,	uv.r,uv.b,	c[0],c[1],c[2],c[3],	0,
		}
	} else {

		inner: Quad = {quad.l + border,quad.t + border,quad.r - border,quad.b - border,}

		vertex_arrays = {
			{ quad.l,quad.t,0, 0,0, c[0],c[1],c[2],c[3], 0,	quad.r,quad.t,0, 0,0, c[0],c[1],c[2],c[3], 0,	inner.r,inner.t,0, 0,0, c[0],c[1],c[2],c[3], 0,	inner.l,inner.t,0, 0,0, c[0],c[1],c[2],c[3], 0},
			{ quad.r,quad.t,0, 0,0, c[0],c[1],c[2],c[3], 0,	quad.r,quad.b,0, 0,0, c[0],c[1],c[2],c[3], 0,	inner.r,inner.b,0, 0,0, c[0],c[1],c[2],c[3], 0,	inner.r,inner.t,0, 0,0, c[0],c[1],c[2],c[3], 0},
			{ quad.r,quad.b,0, 0,0, c[0],c[1],c[2],c[3], 0,	quad.l,quad.b,0, 0,0, c[0],c[1],c[2],c[3], 0,	inner.l,inner.b,0, 0,0, c[0],c[1],c[2],c[3], 0,	inner.r,inner.b,0, 0,0, c[0],c[1],c[2],c[3], 0},
			{ quad.l,quad.b,0, 0,0, c[0],c[1],c[2],c[3], 0,	quad.l,quad.t,0, 0,0, c[0],c[1],c[2],c[3], 0,	inner.l,inner.t,0, 0,0, c[0],c[1],c[2],c[3], 0,	inner.l,inner.b,0, 0,0, c[0],c[1],c[2],c[3], 0},
		}
	}
		
	for vertex_array, i in &vertex_arrays
	{
		if border == 0 && i > 0 do break

		quad_index := u32(state.render.quad_index * 4)
		indices :[6]u32 = {0+quad_index, 1+quad_index, 3+quad_index, 1+quad_index, 2+quad_index, 3+quad_index}
		
		copy(state.render.vertices[state.render.vertex_index:state.render.vertex_index+40], vertex_array[:])
		state.render.vertex_index += 40
		
		copy(state.render.indices[state.render.index_index:state.render.index_index+6], indices[:])
		state.render.index_index += 6
		state.render.quad_index += 1
		fmt.println("Vertex", i)
	}
}

// SHADER

UIMAIN_VS ::
`
#version 330 core
layout(location = 0) in vec3 position;
layout(location = 1) in vec2 uv;
layout(location = 2) in vec4 color;
layout(location = 3) in float mix_texture;

uniform vec2 window_res;

out vec4 vertex_color;
out vec2 uv_coords;
out float texture_mix;

void main()
{
	uv_coords = uv;
	vertex_color = color;
	texture_mix = mix_texture;
	// gl_Position.xyzw = vec4(position.x, position.y, 0, 1);
	gl_Position.xyzw = vec4((position.x-window_res.x)/window_res.x, (position.y - window_res.y)/(-window_res.y), position.z, 1);
}
`

UIMAIN_FRAG ::
`
#version 330 core
in vec4 vertex_color;
in vec2 uv_coords;
in float texture_mix;

out vec4 FragColor;

uniform sampler2D tex;

void main()
{
	vec4 Mul = vec4((vertex_color.xyz * vertex_color.aaa), vertex_color.a);

	if (texture_mix == 0)
	{
		FragColor = vertex_color;
	} else {
		vec4 texs = texture(tex, uv_coords);
		FragColor = vec4(vertex_color.rgb, texs.a);
	}
}
`