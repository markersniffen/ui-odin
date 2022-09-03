package ui

import "core:fmt"
import "core:mem"
import "core:os"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

Gl :: struct {
	shader: u32,
	font_texture: u32,
	font_texture_size: i32,

	vertices: []f32,
	vertex_buffer: u32,
	vertex_index: int,

	vao: u32,

	indices: []u32,
	index_buffer: u32,
	index_index: int,
	quad_index: int,
}

Quad :: struct {
	l: f32,
	t: f32,
	r: f32,
	b: f32,
}

opengl_init :: proc() {
	gl.load_up_to(3, 3, glfw.gl_set_proc_address)
	fmt.println(gl.GetString(gl.VERSION))
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

	gl.GenTextures(1, &state.render.font_texture)
	gl.BindTexture(gl.TEXTURE_2D, state.render.font_texture)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	gl.GenVertexArrays(1, &state.render.vao)
	gl.BindVertexArray(state.render.vao)
	
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.EnableVertexAttribArray(2)
	gl.EnableVertexAttribArray(3)

	state.render.font_texture_size = 512 // size of font bitmap
}

opengl_load_texture :: proc(texture: u32, image: rawptr, size:i32) -> bool {
	gl.BindTexture(gl.TEXTURE_2D, texture)
  	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RED, size,size, 0, gl.RED, gl.UNSIGNED_BYTE, image)
  	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
  	if gl.GetError() != 0 do return false
  	return true
}

opengl_render :: proc() {
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	gl.ClearColor(0, 0, 0, 1)
	gl.Viewport(0, 0, i32(state.framebuffer_res.x), i32(state.framebuffer_res.y))
	gl.Scissor(0, 0, i32(state.framebuffer_res.x), i32(state.framebuffer_res.y))
	gl.Clear(gl.COLOR_BUFFER_BIT)

	gl.UseProgram(state.render.shader)

	gl.BindBuffer(gl.ARRAY_BUFFER, state.render.vertex_buffer)
	gl.BufferData(gl.ARRAY_BUFFER, state.render.vertex_index * size_of(f32), &state.render.vertices[0], gl.STATIC_DRAW)
	
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 10 * size_of(f32), 0 * size_of(f32))
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 10 * size_of(f32), 3 * size_of(f32))
	gl.VertexAttribPointer(2, 4, gl.FLOAT, gl.FALSE, 10 * size_of(f32), 5 * size_of(f32))
	gl.VertexAttribPointer(3, 1, gl.FLOAT, gl.FALSE, 10 * size_of(f32), 9 * size_of(f32))

	framebuffer_res := gl.GetUniformLocation(state.render.shader, "framebuffer_res")
	gl.Uniform2f(framebuffer_res, f32(state.framebuffer_res.x)/2, f32(state.framebuffer_res.y)/2)

	multiplier := gl.GetUniformLocation(state.render.shader, "multiplier")
	gl.Uniform2f(multiplier, f32(state.framebuffer_res.x / state.window_size.x), f32(state.framebuffer_res.y / state.window_size.y))
 	
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, state.render.index_buffer)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, state.render.index_index * size_of(u32), &state.render.indices[0], gl.STATIC_DRAW)

	gl.DrawElements(gl.TRIANGLES, i32(state.render.index_index), gl.UNSIGNED_INT, nil)

	glfw.SwapBuffers(state.window)

	state.render.vertex_index = 0
	state.render.index_index = 0
	state.render.quad_index = 0

}

push_quad :: 	proc(quad:Quad,	cA:v4={1,1,1,1}, cB:v4={1,1,1,1}, cC:v4={1,1,1,1}, cD:v4={1,1,1,1},	border: f32=0.0, uv:Quad={0,0,0,0},	mix:f32=0) {
	vertex_arrays: [4][40]f32

	if border == 0
	{
		vertex_arrays[0]  = { 
				quad.l,quad.t,0,	uv.l,uv.t,	cA[0],cA[1],cA[2],cA[3],	mix,
				quad.r,quad.t,0,	uv.r,uv.t,	cB[0],cB[1],cB[2],cB[3],	mix,
				quad.r,quad.b,0,	uv.r,uv.b,	cD[0],cD[1],cD[2],cD[3],	mix,
				quad.l,quad.b,0,	uv.l,uv.b,	cC[0],cC[1],cC[2],cC[3],	mix,
		}
	} else {

		inner: Quad = {quad.l + border,quad.t + border,quad.r - border,quad.b - border,}

		vertex_arrays = {
			{ quad.l,quad.t,0, 0,0, cA[0],cA[1],cA[2],cA[3], 0,	quad.r,quad.t,0, 0,0, cB[0],cB[1],cB[2],cB[3], 0,	inner.r,inner.t,0, 0,0, cB[0],cB[1],cB[2],cB[3], 0,	inner.l,inner.t,0, 0,0, cA[0],cA[1],cA[2],cA[3], mix},
			{ quad.r,quad.t,0, 0,0, cB[0],cB[1],cB[2],cB[3], 0,	quad.r,quad.b,0, 0,0, cD[0],cD[1],cD[2],cD[3], 0,	inner.r,inner.b,0, 0,0, cD[0],cD[1],cD[2],cD[3], 0,	inner.r,inner.t,0, 0,0, cB[0],cB[1],cB[2],cB[3], mix},
			{ quad.r,quad.b,0, 0,0, cD[0],cD[1],cD[2],cD[3], 0,	quad.l,quad.b,0, 0,0, cC[0],cC[1],cC[2],cC[3], 0,	inner.l,inner.b,0, 0,0, cC[0],cC[1],cC[2],cC[3], 0,	inner.r,inner.b,0, 0,0, cD[0],cD[1],cD[2],cD[3], mix},
			{ quad.l,quad.b,0, 0,0, cC[0],cC[1],cC[2],cC[3], 0,	quad.l,quad.t,0, 0,0, cA[0],cA[1],cA[2],cA[3], 0,	inner.l,inner.t,0, 0,0, cA[0],cA[1],cA[2],cA[3], 0,	inner.l,inner.b,0, 0,0, cC[0],cC[1],cC[2],cC[3], mix},
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
	}
}

push_quad_solid :: proc(quad: Quad, color:v4) {
	push_quad(quad,	color, color, color, color, 0, {0,0,0,0}, 0)
}

push_quad_gradient_h :: proc(quad: Quad, color_left:v4, color_right:v4) {
	push_quad(quad,	color_left, color_right, color_left, color_right, 0, {0,0,0,0}, 0)
}

push_quad_gradient_v :: proc(quad: Quad, color_top:v4, color_bottom:v4) {
	push_quad(quad,	color_top, color_top, color_bottom, color_bottom, 0, {0,0,0,0}, 0)
}

push_quad_border :: proc(quad: Quad, color:v4, border: f32=2) {
	push_quad(quad,	color, color, color, color, border, {0,0,0,0}, 0)
}

push_quad_font :: proc(quad: Quad, color:v4, uv:Quad) {
	push_quad(quad,	color, color, color, color, 0, uv, 1)
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

//______ SHADER ______//

UIMAIN_VS ::
`
#version 330 core
layout(location = 0) in vec3 pos;
layout(location = 1) in vec2 uv;
layout(location = 2) in vec4 color;
layout(location = 3) in float mix_texture;

uniform vec2 framebuffer_res;
uniform vec2 multiplier;

out vec4 vertex_color;
out vec2 uv_coords;
out float texture_mix;

void main()
{
	float x = ((pos.x * multiplier.x) - framebuffer_res.x) / framebuffer_res.x;
	float y = ((pos.y * multiplier.y) - framebuffer_res.y) / -framebuffer_res.y;
	uv_coords = uv;
	vertex_color = color;
	texture_mix = mix_texture;
	gl_Position.xyzw = vec4(x, y, pos.z, 1);

	// gl_Position.xyzw = vec4((pos.x-window_res.x)/window_res.x, (pos.y - window_res.y)/(-window_res.y), pos.z, 1);
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
	vec4 Mul = vec4((vertex_color.xyz * vertex_color.rrr), vertex_color.r);

	if (texture_mix == 0)
	{
		FragColor = vertex_color;
	} else {
		vec4 texs = texture(tex, uv_coords);
		FragColor = vec4(vertex_color.rgb, texs.r);
	}
}
`