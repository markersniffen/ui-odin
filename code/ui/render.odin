package ui

when PROFILER do import tracy "../../../odin-tracy"

Render :: struct {
	layers: [2]Layer,
	layer_index: int,

	shader: u32,
	vao: u32,
	vertex_buffer: u32,
	index_buffer: u32,
}

Layer :: struct {
	vertices: [^]f32,
	v_index: int,
	indices: [^]u32,
	i_index: int,
	quad_index: int,
}

Quad :: struct {
	l: f32,
	t: f32,
	r: f32,
	b: f32,
}

ui_render_init :: proc() {
	opengl_init()
}

ui_render :: proc() {
	opengl_render()
}

set_render_layer :: proc(layer: int) {
	state.render.layer_index = layer
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
	// opengl_push_quad(quad, cA, cB, cC, cD,border, uv, texture_id,	clip)
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