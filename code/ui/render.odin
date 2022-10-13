package ui

import tracy "../../../odin-tracy"

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import lin "core:math/linalg"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

Gl :: struct {
	shader: u32,

	layers: [2]Layer,
	layer_index: int,

	vao: u32,
	vertex_buffer: u32,
	index_buffer: u32,
}

Layer :: struct {
	vertices: []f32,
	v_index: int,
	indices: []u32,
	i_index: int,
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
	gl.GenBuffers(1, &state.render.index_buffer)

	// NOTE create render layers
	for layer, i in state.render.layers {
		state.render.layers[i].vertices = make_slice([]f32, mem.Megabyte * 2)
		state.render.layers[i].indices = make([]u32, mem.Megabyte * 2)
	}

	shader_success : bool
	state.render.shader, shader_success = gl.load_shaders_source(UIMAIN_VS, UIMAIN_FRAG)
	if !shader_success do fmt.println("UI shader did not compile!")
	gl.UseProgram(state.render.shader)

	state.ui.fonts.regular.name = "Roboto-Regular"
	state.ui.fonts.regular.label = "regular_texture"
	state.ui.fonts.regular.texture_size = 512 // size of font bitmap
	state.ui.fonts.regular.texture_unit = 0
	gl.GenTextures(1, &state.ui.fonts.regular.texture)

	state.ui.fonts.bold.name = "Roboto-Bold"
	state.ui.fonts.bold.label = "bold_texture"
	state.ui.fonts.bold.texture_size = 512 // size of font bitmap
	state.ui.fonts.bold.texture_unit = 1
	gl.GenTextures(1, &state.ui.fonts.bold.texture)

	state.ui.fonts.italic.name = "Roboto-Italic"
	state.ui.fonts.italic.label = "italic_texture"
	state.ui.fonts.italic.texture_size = 512 // size of font bitmap
	state.ui.fonts.italic.texture_unit = 2
	gl.GenTextures(1, &state.ui.fonts.italic.texture)

	state.ui.fonts.light.name = "Roboto-Light"
	state.ui.fonts.light.label = "light_texture"
	state.ui.fonts.light.texture_size = 512 // size of font bitmap
	state.ui.fonts.light.texture_unit = 3
	gl.GenTextures(1, &state.ui.fonts.light.texture)

	state.ui.fonts.icons.name = "ui_icons"
	state.ui.fonts.icons.label = "icon_texture"
	state.ui.fonts.icons.texture_size = 512
	state.ui.fonts.icons.texture_unit = 4
	gl.GenTextures(1, &state.ui.fonts.icons.texture)

	fmt.println(state.ui.fonts.regular)
	fmt.println(state.ui.fonts.bold)
	fmt.println(state.ui.fonts.icons)

	gl.GenVertexArrays(1, &state.render.vao)
	gl.BindVertexArray(state.render.vao)
	
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.EnableVertexAttribArray(2)
	gl.EnableVertexAttribArray(3)
	gl.EnableVertexAttribArray(4)
}

opengl_load_texture :: proc(font: ^Font, image: rawptr) -> bool {
	gl.ActiveTexture(gl.TEXTURE0 + font.texture_unit)
	gl.BindTexture(gl.TEXTURE_2D, font.texture)
  	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RED, font.texture_size,font.texture_size, 0, gl.RED, gl.UNSIGNED_BYTE, image)
  	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
  	uni := gl.GetUniformLocation(state.render.shader, strings.clone_to_cstring(font.label))
	gl.Uniform1i(uni, i32(font.texture_unit))
  	if gl.GetError() != 0 do return false
  	return true
}

opengl_render :: proc() {
	tracy.Zone()
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	bd := v4(lin.vector4_hsl_to_rgb(state.ui.col.backdrop.h, state.ui.col.backdrop.s, state.ui.col.backdrop.l, state.ui.col.backdrop.a))
	gl.ClearColor(bd.r, bd.g, bd.b, bd.a)
	gl.Viewport(0, 0, i32(state.window.framebuffer.x), i32(state.window.framebuffer.y))
	gl.Scissor(0, 0, i32(state.window.framebuffer.x), i32(state.window.framebuffer.y))
	gl.Clear(gl.COLOR_BUFFER_BIT)

	gl.UseProgram(state.render.shader)

 	for index in 0..=1 {
 		layer := &state.render.layers[index]

		gl.BindBuffer(gl.ARRAY_BUFFER, state.render.vertex_buffer)
		gl.BufferData(gl.ARRAY_BUFFER, layer.v_index * size_of(f32), &layer.vertices[0], gl.STATIC_DRAW)
								  // idx		size	type			norm		 total size			  offset
		gl.VertexAttribPointer(0, 		3, 	gl.FLOAT, 	gl.FALSE, 14 * size_of(f32), 0 * size_of(f32))
		gl.VertexAttribPointer(1, 		2, 	gl.FLOAT, 	gl.FALSE, 14 * size_of(f32), 3 * size_of(f32))
		gl.VertexAttribPointer(2, 		4, 	gl.FLOAT, 	gl.FALSE, 14 * size_of(f32), 5 * size_of(f32))
		gl.VertexAttribPointer(3, 		1, 	gl.FLOAT, 	gl.FALSE, 14 * size_of(f32), 9 * size_of(f32))
		gl.VertexAttribPointer(4, 		4, 	gl.FLOAT, 	gl.FALSE, 14 * size_of(f32), 10 * size_of(f32))

		framebuffer_res := gl.GetUniformLocation(state.render.shader, "framebuffer_res")
		gl.Uniform2f(framebuffer_res, f32(state.window.framebuffer.x)/2, f32(state.window.framebuffer.y)/2)

		multiplier := gl.GetUniformLocation(state.render.shader, "multiplier")
		gl.Uniform2f(multiplier, f32(state.window.framebuffer.x / state.window.size.x), f32(state.window.framebuffer.y / state.window.size.y))
 	
		gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, state.render.index_buffer)
		gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, layer.i_index * size_of(u32), &layer.indices[0], gl.STATIC_DRAW)
		gl.DrawElements(gl.TRIANGLES, i32(layer.i_index), gl.UNSIGNED_INT, nil)
 	}

	glfw.SwapBuffers(state.window.handle)

	for i in 0..=1 {
		state.render.layers[i].v_index = 0
		state.render.layers[i].i_index = 0
		state.render.layers[i].quad_index = 0
	}
}

set_render_layer :: proc(layer: int) {
	state.render.layer_index = layer
}

push_quad :: 	proc(
							quad:Quad,
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

OLD_quad_clamp_or_reject :: proc (quad_a, quad_b: Quad) -> (Quad, bool) {
	quad : Quad = quad_a
	ok := false
	a := pt_in_quad({quad_a.l,quad_a.t}, quad_b)
	b := pt_in_quad({quad_a.r, quad_a.b}, quad_b)

	if a && b {
		ok = true
	} else if !a && !b {
		ok = false
	} else {
		ok = true
		quad = quad_clamp_to_quad(quad_a, quad_b)
	}

	return quad, ok
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

//______ SHADER ______//

UIMAIN_VS ::
`
#version 420 core
layout(location = 0) in vec3 pos;
layout(location = 1) in vec2 uv;
layout(location = 2) in vec4 color;
layout(location = 3) in float _texture_id;
layout(location = 4) in vec4 _clip;

uniform vec2 framebuffer_res;
uniform vec2 multiplier;

out vec4 vertex_color;
out vec2 uv_coords;
out float texture_id;
out vec4 clip;
out vec2 fb_res;

void main()
{
	fb_res = framebuffer_res;
	clip = _clip;
	float x = ((pos.x * multiplier.x) - framebuffer_res.x) / framebuffer_res.x;
	float y = ((pos.y * multiplier.y) - framebuffer_res.y) / -framebuffer_res.y;
	uv_coords = uv;
	vertex_color = color;
	texture_id = _texture_id;
	gl_Position.xyzw = vec4(x, y, pos.z, 1);
}
`

UIMAIN_FRAG ::
`
#version 420 core
in vec4 vertex_color;
in vec2 uv_coords;
in float texture_id;
in vec4 clip;

in vec2 fb_res;
// in vec4 gl_FragCoord;
layout(origin_upper_left) in vec4 gl_FragCoord;


out vec4 FragColor;

uniform sampler2D regular_texture;
uniform sampler2D bold_texture;
uniform sampler2D italic_texture;
uniform sampler2D light_texture;
uniform sampler2D icon_texture;

void main()
{
	vec4 Mul = vec4((vertex_color.xyz * vertex_color.rrr), vertex_color.r);

	if (((gl_FragCoord.y > clip.y) && (gl_FragCoord.y < clip.w)) && ((gl_FragCoord.x > clip.x) && (gl_FragCoord.x < clip.z))) { 
		if (texture_id == 0)
		{
			FragColor = vertex_color;
		} else if (texture_id == 1) {
			FragColor = vec4(vertex_color.rgb, texture(regular_texture, uv_coords).r);
		} else if (texture_id == 2) {
			FragColor = vec4(vertex_color.rgb, texture(bold_texture, uv_coords).r);
		} else if (texture_id == 3) {
			FragColor = vec4(vertex_color.rgb, texture(italic_texture, uv_coords).r);
		} else if (texture_id == 4) {
			FragColor = vec4(vertex_color.rgb, texture(light_texture, uv_coords).r);
		} else if (texture_id == 5) {
			FragColor = vec4(vertex_color.rgb, texture(icon_texture, uv_coords).r);
		}
	}

	
}
`
