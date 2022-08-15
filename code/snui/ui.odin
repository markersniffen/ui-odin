package snui

import stb "vendor:stb/truetype"
import "core:mem"
import "core:fmt"
import "core:os"
import "core:math"

Ui :: struct {
	panels: map[Uid]^Panel,
	panel_pool: Pool,

	panel_active: Uid,

	col: Ui_Colors,

	// FONT INFO
	char_data: map[rune]Char_Data,
	font_size: f32,			// NOTE pixels tall
	font_size_large: f32,   // TODO not implemented yet
 	font_size_small: f32,	//
	font_v_center_offset: f32,
	margin: f32,
	line_space: f32,
}

Ui_Colors :: struct {
	bg: v4,
	font: v4,
	highlight: v4,
	base: v4,
	hot: v4,
	active: v4,	
}

ui_init :: proc()
{
	ui_init_font()
	ui_init_panels()
}

// FONT|TEXT //

Char_Data :: struct
{
	offset: v2,
	width: f32,
	height: f32,
	advance: f32,
	uv: Quad,
}

Text_Align :: enum {
	LEFT,
	CENTER,
	RIGHT,
}

ui_init_font :: proc() {
	ui_set_font_size()
	fmt.println("set font size...")
	
	state.ui.col.bg = {0.1, 0.1, 0.1, 1}
	state.ui.col.font = {1,1,1,1}
	state.ui.col.base = {0.1, 0.1, 0.1, 1}
	state.ui.col.highlight = {0.0, 0.2, 1, 1}
	state.ui.col.hot = {1.0,0.5,0.2,1}
	state.ui.col.active = {0.8,0.3,0.2,1}
}

ui_set_font_size :: proc(size:f32=20)
{
	state.ui.font_size = size
	state.ui.font_size_small = state.ui.font_size * .75
	state.ui.font_size_large = state.ui.font_size * 1.25
	
	ui_load_font("Roboto-Regular", state.ui.font_size, state.render.font_texture)

	letter_data := state.ui.char_data['W']
	state.ui.font_v_center_offset = math.round((state.ui.font_size - letter_data.height) * 0.5)
	state.ui.margin = 4
	state.ui.line_space = state.ui.font_size + (state.ui.margin * 2) // state.ui.margin * 2 + state.ui.font_size
}

ui_load_font :: proc(name: string, font_size: f32, texture: u32)
{
	using stb, mem, fmt
	NUM_CHARS :: 96
	
	data, data_ok := os.read_entire_file(fmt.tprintf("fonts/%v.ttf", name))
	defer delete(data)
	if !data_ok do fmt.println("failed to load font file")

	image:= alloc(int(state.render.font_texture_size * state.render.font_texture_size))
	defer free(image)

	stb_char_data, char_data_ok:= make([]bakedchar, NUM_CHARS)
	defer delete(stb_char_data)

	BakeFontBitmap(raw_data(data), 0, font_size, cast([^]u8)image, state.render.font_texture_size, state.render.font_texture_size, 32, NUM_CHARS, raw_data(stb_char_data))

	for b, i in stb_char_data
	{
		pixel_divider := 1.0 / f32(state.render.font_texture_size)

		char_data: Char_Data
		
		char_data.offset = {f32(b.xoff), f32(b.yoff + state.ui.font_size)}
		char_data.width = f32(b.x1 - b.x0)
		char_data.height = f32(b.y1 - b.y0)
		char_data.advance = b.xadvance

		char_data.uv.l = f32(b.x0) * pixel_divider
		char_data.uv.t = f32(b.y0) * pixel_divider
		char_data.uv.r = f32(b.x1) * pixel_divider
		char_data.uv.b = f32(b.y1) * pixel_divider

		state.ui.char_data[rune(i + 32)] = char_data
	}

	if opengl_load_texture(texture, image, state.render.font_texture_size) do fmt.println(fmt.tprintf("Font loaded: %v", name))
}

draw_text_multiline :: proc(text:string, quad:Quad, align:Text_Align=.LEFT, kerning:f32=-2)
{
	max := (quad.b - quad.t) / state.ui.line_space
	start, end: int 
	letter_index: int
	line_index: int
	for letter_index < len(text)
	{
		if f32(line_index) > max do break
		jump := f32(line_index) * (state.ui.line_space - (state.ui.margin*2) + kerning) 
		letter := text[letter_index]
		if letter == '\n' || letter_index == len(text)-1 {
			end = letter_index
			if letter != '\n' do end += 1
			draw_text(text[start:end], {quad.l, quad.t + jump, quad.r, quad.t + jump + state.ui.line_space}, align, state.ui.col.font)
			start = end
			line_index += 1
		}
		letter_index += 1
	}
}

draw_text :: proc(text: string, quad: Quad, align: Text_Align = .LEFT, color: v4 = {1,1,1,1} )
{
	using stb

	left_align: f32 = quad.l
	top_align: f32 = quad.t - state.ui.font_v_center_offset + state.ui.margin
	text_height: f32 = state.ui.font_size
	text_width: f32

	if align != .LEFT
	{
		for letter in text do text_width += state.ui.char_data[letter].advance

		if align == .CENTER {
			left_align -= text_width / 2
		} else if align == .RIGHT {
			left_align -= text_width + state.ui.font_v_center_offset + state.ui.margin
		}
	} else {
		left_align += state.ui.font_v_center_offset + state.ui.margin
	}

	top_left : v2 = { left_align, top_align }

	for letter, i in text
	{
		letter_data : Char_Data = state.ui.char_data[letter]
		if letter != ' '
		{
			char_quad : Quad
			char_quad.l = top_left.x + letter_data.offset.x
			char_quad.t = top_left.y + letter_data.offset.y
			char_quad.r = char_quad.l + letter_data.width
			char_quad.b = char_quad.t + letter_data.height
			push_quad_font(char_quad, color, state.ui.char_data[letter].uv)
		}
		top_left.x += letter_data.advance
	}
}