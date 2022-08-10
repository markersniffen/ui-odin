package snui

import "core:fmt"
import "core:mem"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

Gl :: struct
{
	shader: u32,
	program: u32,

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

	state.render.program = gl.CreateProgram()

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

	window_res := gl.GetUniformLocation(state.render.program, "window_res")
	fmt.println(window_res)
	gl.Uniform2i(window_res, state.window_size.x, state.window_size.y)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, state.render.index_buffer)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, state.render.index_index * size_of(u32), &state.render.indices[0], gl.STATIC_DRAW)

	gl.DrawElements(gl.TRIANGLES, i32(state.render.index_index), gl.UNSIGNED_INT, nil)
	glfw.SwapBuffers(state.window)

	state.render.vertex_index = 0
	state.render.index_index = 0
	state.render.quad_index = 0
}

push_quad_2 :: proc(quad:Quad, color:v4, border: f32=0.0, uv:Quad={0,0,0,0})
{
	V :[40]f32 = { 
		quad.l,quad.b,0,	uv.l,uv.b,	color[0],color[1],color[2],color[3],	0,
		quad.l,quad.t,0,	uv.l,uv.t,	color[0],color[1],color[2],color[3],	0,
		quad.r,quad.t,0,	uv.r,uv.t,	color[0],color[1],color[2],color[3],	0,
		quad.r,quad.b,0,	uv.r,uv.b,	color[0],color[1],color[2],color[3],	0,
	}
	copy(state.render.vertices[state.render.vertex_index:state.render.vertex_index+40], V[:])
	state.render.vertex_index += 40

	QI := u32(state.render.quad_index * 4);
	I :[6]u32 = {0+QI, 1+QI, 2+QI, 0+QI, 2+QI, 3+QI};
	copy(state.render.indices[state.render.index_index:state.render.index_index+6], I[:]);
	state.render.index_index += 6
	state.render.quad_index += 1
}

push_quad :: proc(Quad: Quad, UV: [4]f32, Color: v4, Border: f32, ForceDraw:bool = false)
{
	if state.render.vertex_index + 40 < len(state.render.vertices)
	{
		W := f32(state.window_size.x/2)
		H := f32(state.window_size.y/2)
		C := f32(0.0)
		u:f32 = 0
		v:f32 = 1
		uvl:f32 = UV[0]
		uvb:f32 = UV[1]
		uvr:f32 = UV[2]
		uvt:f32 = UV[3]
		
		c1 := f32(Color[0])
		c2 := f32(Color[1])
		c3 := f32(Color[2])
		c4 := f32(Color[3])

		m:f32 = 0
		if UV != {0,0,0,0} // if this is a font
		{
			m = 1
			c4 = 0
		}
		
		// NOTE simple quad
		if Border == 0
		{
			l := (Quad.l - W) / W;
			t := (Quad.t - H) / H;
			r := (Quad.r - W) / W;
			b := (Quad.b - H) / H;

			t = t * -1
			b = b * -1

			V :[40]f32 = { 
				l,b,0,	uvl,uvb,	c1,c2,c3,c4,	m,
				l,t,0,	uvl,uvt,	c1,c2,c3,c4,	m,
				r,t,0,	uvr,uvt,	c1,c2,c3,c4,	m,
				r,b,0,	uvr,uvb,	c1,c2,c3,c4,	m,
			}
			copy(state.render.vertices[state.render.vertex_index:state.render.vertex_index+40], V[:])
			state.render.vertex_index += 40
			
			QI := u32(state.render.quad_index * 4);
			I :[6]u32 = {0+QI, 1+QI, 2+QI, 0+QI, 2+QI, 3+QI};
			copy(state.render.indices[state.render.index_index:state.render.index_index+6], I[:]);
			state.render.index_index += 6
			state.render.quad_index += 1
		}
		else
		// NOTE Quad as border (techincally 4 quads)
		{
			// TODO NEED OT FIX THIS?
			L := (Quad.l - W) / W;
			T := (Quad.r - H) / H;
			R := (Quad.t - W) / W;
			B := (Quad.b - H) / H;

			T = T * -1
			B = B * -1

			TX:= Border / W;
			TY:= Border / H;
			
			L2 := L + TX;
			R2 := R - TX;
			T2 := T - TY;
			B2 := B + TY;
			
			VArrays :[4][40]f32= {
				{ L,T,0, u,v, c1,c2,c3,c4, m,	R,T,0, u,v, c1,c2,c3,c4, m,	R2,T2,0, u,v, c1,c2,c3,c4, m,	L2,T2,0, u,v, c1,c2,c3,c4, m},
				{ R,T,0, u,v, c1,c2,c3,c4, m,	R,B,0, u,v, c1,c2,c3,c4, m,	R2,B2,0, u,v, c1,c2,c3,c4, m,	R2,T2,0, u,v, c1,c2,c3,c4, m},
				{ R,B,0, u,v, c1,c2,c3,c4, m,	L,B,0, u,v, c1,c2,c3,c4, m,	L2,B2,0, u,v, c1,c2,c3,c4, m,	R2,B2,0, u,v, c1,c2,c3,c4, m},
				{ L,B,0, u,v, c1,c2,c3,c4, m,	L,T,0, u,v, c1,c2,c3,c4, m,	L2,T2,0, u,v, c1,c2,c3,c4, m,	L2,B2,0, u,v, c1,c2,c3,c4, m},
			}
			
			for VA in &VArrays
			{
				QI := u32(state.render.quad_index * 4);
				I1 :[6]u32 = {0+QI, 1+QI, 3+QI, 1+QI, 2+QI, 3+QI};
				
				copy(state.render.vertices[state.render.vertex_index:state.render.vertex_index+40], VA[:]);
				state.render.vertex_index += 40;
				
				copy(state.render.indices[state.render.index_index:state.render.index_index+6], I1[:]);
				state.render.index_index += 6;
				state.render.quad_index += 1;
			}
		}
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
float W = window_res.x/2;
float H = window_res.y/2;

out vec4 vertex_color;
out vec2 uv_coords;
out float texture_mix;

void main()
{
	uv_coords = uv;
	vertex_color = color;
	texture_mix = mix_texture;
	gl_Position.xyzw = vec4((position.x-W)/W, (position.y - H)/H, position.z, 1);
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