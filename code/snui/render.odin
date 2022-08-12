package snui

import "core:fmt"
import "core:mem"
import "core:os"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import stb "vendor:stb/truetype"

UI_TEXT_HEIGHT :: 20
UI_HEIGHT :: 20
UI_MARGIN :: 4

RED :: v4 {1,0,0,1}
WHITE :: v4 {1,1,1,1}

Gl :: struct
{
	shader: u32,
	texture: u32,
	char_data: []stb.bakedchar,

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

	gl.GenTextures(1, &state.render.texture)
	gl.BindTexture(gl.TEXTURE_2D, state.render.texture)
	gl.GenerateMipmap(gl.TEXTURE_2D)
}

stb_font_init :: proc()
{
	using stb, mem, fmt
	NUM_CHARS :: 96
	
	data, data_ok := os.read_entire_file("fonts/Roboto-Regular.ttf")
	defer delete(data)
	if !data_ok do fmt.println("failed to load font file")

	image:= alloc(512*512)
	defer free(image)
	char_data, char_data_ok:= make([]bakedchar, NUM_CHARS)
	state.render.char_data = char_data

	BakeFontBitmap(raw_data(data), 0, UI_TEXT_HEIGHT, cast([^]u8)image, 512, 512, 32, NUM_CHARS, raw_data(char_data))

	gl.BindTexture(gl.TEXTURE_2D, state.render.texture)
  	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.ALPHA, 512,512, 0, gl.ALPHA, gl.UNSIGNED_BYTE, image)
  	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
}

render :: proc()
{
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	gl.ClearColor(0, 0, 0, 1)
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

draw_text :: proc(text: string, pt: v2, offset: v2 = {0,0})
{
	using stb

	x:= pt.x + offset.x
	y:= pt.y + offset.y
	stb_quad: aligned_quad

	for letter in text
	{
		if letter == 10
		{
			x = pt.x
			y += UI_HEIGHT
		} else {
			GetBakedQuad(raw_data(state.render.char_data), 512, 512, i32(letter) - 32, &x, &y, &stb_quad, true)
			char_quad : Quad = {stb_quad.x0, stb_quad.y0, stb_quad.x1, stb_quad.y1}
			push_quad_font(char_quad, WHITE, {stb_quad.s0, stb_quad.t1, stb_quad.s1, stb_quad.t0})
		}
	}
}

// junk :: proc(Text: string, quad: Quad, Justified: int, Editing:= false)
// {
// 	using stb, fmt
// 	LeftMargin := f32(quad.l + 2)
// 	Baseline := f32(quad.b - 5)

// 	x:= LeftMargin
// 	y:= Baseline
// 	q: aligned_quad

// 	QuadHeight:f32
// 	HalfWidth :f32
// 	LastPlace :f32

// 	TextQuad := quad
// 	Lines: f32 = 0
// 	for Letter in Text do if Letter == 10 do Lines += 1
// 	TextQuad.b += UI_HEIGHT * Lines

// 	if Editing do push_quad(TextQuad, {0.5, 0, 0, 0.5}, 2)

// 	// NOTE calculate offset for center justified text
// 	if Justified == 1
// 	{
// 		QuadWidth = f32((quad.r - quad.l)/2)
// 		QuadHeight = f32((quad.b - quad.t)/2)
// 		for Letter, i in Text
// 		{
// 			GetBakedQuad(raw_data(state.render.char_data), 512, 512, i32(Letter) - 32, &x, &y, &q, true)
// 			if i == 0 do LastPlace = q.x0
// 			if x > f32(quad.r - 10) do break
// 			HalfWidth += (q.x1 - LastPlace)/2
// 			LastPlace = q.x1
// 		}
// 		x = LeftMargin - 2
// 		y = Baseline
// 	}

// 	Cursor:v4

// 	// NOTE draw text
// 	for Letter, LetterIndex in Text
// 	{
// 		CharQuad: Quad
// 		if Letter == 10
// 		{
// 			x = LeftMargin
// 			y += UI_HEIGHT
// 			CharQuad = {f32(x), f32(y) - UI_HEIGHT, f32(x) + UI_MARGIN, f32(y)}
// 		} else {
// 			GetBakedQuad(raw_data(state.render.char_data), 512, 512, i32(Letter) - 32, &x, &y, &q, true)
// 			if x > f32(quad.r - 10) // stop drawing text that goes out of bounds
// 			{
// 				GetBakedQuad(raw_data(state.render.char_data), 512, 512, i32('.') - 32, &x, &y, &q, true)
// 				push_quad({q.x0 - HalfWidth + QuadWidth, q.y0, q.x1 - HalfWidth + QuadWidth, q.y1}, WHITE, 0, {q.s0, q.t1, q.s1, q.t0})
// 				break
// 			}
// 			if Letter == 32 // if keystroke is spacebar, manually calculate a wide enough quad for cursor
// 			{
// 				CharQuad= {q.x0 - HalfWidth + QuadWidth, q.y0, q.x0 + UI_MARGIN - HalfWidth + QuadWidth, q.y1}
// 			} else {
// 				CharQuad= {q.x0 - HalfWidth + QuadWidth, q.y0, q.x1 - HalfWidth + QuadWidth, q.y1}
// 			}
// 			push_quad(CharQuad, {1,1,1,1}, 0, {q.s0, q.t1, q.s1, q.t0})
// 			TextQuad.b = max(TextQuad.b, f32(y))
// 		}

// 		if Editing
// 		{
// 			// if LetterIndex+1 == Show.State.UICharIndex do Cursor = {CharQuad.r, f32(y - UI_HEIGHT + 5), CharQuad.r + UI_MARGIN, f32(y + 2)}
// 		}
// 	}
// 	if Editing // draw cursor
// 	{
// 		// if Show.State.UICharIndex == 0 do Cursor = QuadTo64({LeftMargin, f32(quad.b - UI_HEIGHT), LeftMargin + UI_MARGIN, f32(Quad[3])})
// 		// PushQuad(Cursor, {0,0,0,0}, RED, 2)
// 	}


// }

// ! filled solid color rect
// ! filled gradient rect
// ! border
// rounded?

//					 quad       color           border-thick     uv coords          

push_quad :: 	proc(quad:Quad,	cA:v4={1,1,1,1}, cB:v4={1,1,1,1}, cC:v4={1,1,1,1}, cD:v4={1,1,1,1},	border: f32=0.0, uv:Quad={0,0,0,0},	mix:f32=0)
{
	vertex_arrays: [4][40]f32

	if border == 0
	{
		vertex_arrays[0]  = { 
				quad.l,quad.b,0,	uv.l,uv.t,	cC[0],cC[1],cC[2],cC[3],	mix,
				quad.l,quad.t,0,	uv.l,uv.b,	cA[0],cA[1],cA[2],cA[3],	mix,
				quad.r,quad.t,0,	uv.r,uv.b,	cB[0],cB[1],cB[2],cB[3],	mix,
				quad.r,quad.b,0,	uv.r,uv.t,	cD[0],cD[1],cD[2],cD[3],	mix,
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

push_quad_solid :: proc(quad: Quad, color:v4)
{
	push_quad(quad,	color, color, color, color, 0, {0,0,0,0}, 0)
}

push_quad_gradient_h :: proc(quad: Quad, color_left:v4, color_right:v4)
{
	push_quad(quad,	color_left, color_right, color_left, color_right, 0, {0,0,0,0}, 0)
}

push_quad_gradient_v :: proc(quad: Quad, color_top:v4, color_bottom:v4)
{
	push_quad(quad,	color_top, color_top, color_bottom, color_bottom, 0, {0,0,0,0}, 0)
}

push_quad_font :: proc(quad: Quad, color:v4, uv:Quad)
{
	push_quad(quad,	color, color, color, color, 0, uv, 1)
}

pt_in_quad 	:: proc(pt: v2, quad: Quad) -> bool
{
	result := false;
	if pt.x > quad.l && pt.y > quad.t && pt.x < quad.r && pt.y < quad.b do result = true;
	return result;
}

quad_in_quad	:: proc(quad_a, quad_b: Quad) -> bool
{
	result := false
	if pt_in_quad({quad_a.l,quad_a.t}, quad_b) || pt_in_quad({quad_a.r, quad_a.b}, quad_b) do result = true
	return result
}

quad_full_in_quad	:: proc(quad_a, quad_b: Quad) -> bool
{
	result := false
	if pt_in_quad({quad_a.l, quad_a.t}, quad_b) && pt_in_quad({quad_a.r, quad_a.b}, quad_b) do result = true
	return result
}

quad_clamp_to_quad :: proc (quad, quad_b: Quad) -> Quad
{
	result: Quad = quad
	result.l = clamp(quad.l, quad_b.l, quad_b.r)
	result.t = clamp(quad.t, quad_b.t, quad_b.b)
	result.r = clamp(quad.r, quad_b.l, quad_b.r)
	result.b = clamp(quad.b, quad_b.t, quad_b.b)
	return result
}

// SHADER

UIMAIN_VS ::
`
#version 330 core
layout(location = 0) in vec3 pos;
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
	gl_Position.xyzw = vec4((pos.x-window_res.x)/window_res.x, (pos.y - window_res.y)/(-window_res.y), pos.z, 1);
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

	// vec4 texs = texture(tex, uv_coords);
	// FragColor = vec4((vertex_color.rgb * texture_mix) + texs.rgb, texs.a);

	if (texture_mix == 0)
	{
		FragColor = vertex_color;
	} else {
		vec4 texs = texture(tex, uv_coords);
		FragColor = vec4(vertex_color.rgb, texs.a);
	}
}
`