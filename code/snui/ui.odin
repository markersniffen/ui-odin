package snui

import stb "vendor:stb/truetype"
import "core:mem"
import "core:fmt"
import "core:os"
import "core:math"

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

Ui :: struct {
	char_data: map[rune]Char_Data,

	font_size: f32,			// NOTE pixels tall
	font_size_large: f32,
	font_size_small: f32,
	
	margin: f32,
	line_space: f32,

	col_bg: v4,
	col_font: v4,
	col_highlight: v4,
	col_base: v4,
	col_hot: v4,
	col_active: v4,
}

ui_init :: proc()
{
	ui_set_font_size()
	fmt.println("set font size...")
	
	state.ui.col_bg = {0.1, 0.1, 0.1, 1}
	state.ui.col_font = {1,1,1,1}
	state.ui.col_base = {0.1, 0.1, 0.1, 1}
	state.ui.col_highlight = {0.0, 0.2, 1, 1}
	state.ui.col_hot = {1.0,0.5,0.2,1}
	state.ui.col_active = {0.8,0.3,0.2,1}
}

ui_set_font_size :: proc(size:f32=20)
{
	state.ui.font_size = size
	state.ui.font_size_small = state.ui.font_size * .75
	state.ui.font_size_large = state.ui.font_size * 1.25
	
	ui_load_font("Roboto-Regular", state.ui.font_size, state.render.font_texture)

	letter_data := state.ui.char_data['W']
	state.ui.margin = math.round((state.ui.font_size - letter_data.height) * 0.5)
	state.ui.line_space = state.ui.font_size // state.ui.margin * 2 + state.ui.font_size
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

draw_text :: proc(text: string, quad: Quad, align: Text_Align = .LEFT )
{
	using stb

	push_quad_border(quad, {0,1,0,1}, 1)

	text_width: f32
	temp_width: f32
	text_height: f32 = state.ui.font_size
	for letter in text {
		if letter == '\n' {
			text_width = max(text_width, temp_width)
			temp_width = 0
			text_height += state.ui.font_size
		} else {
			temp_width += state.ui.char_data[letter].advance
		}
		text_width = max(text_width, temp_width)
	}

	left_align: f32 = quad.l + state.ui.margin
	top_align: f32 = quad.t - state.ui.margin

	if align == .CENTER do left_align -= text_width / 2

	cursor : v2 = { left_align, top_align }

	for letter, i in text
	{
		char_quad : Quad = { cursor.x, cursor.y, cursor.x, cursor.y }
		if letter == 10 // if return, move everything down
		{
			cursor.x = left_align
			cursor.y += state.ui.line_space
		} else {
			letter_data : Char_Data = state.ui.char_data[letter]
			char_quad.l += letter_data.offset.x
			char_quad.t += letter_data.offset.y
			char_quad.r = char_quad.l + letter_data.width
			char_quad.b = char_quad.t + letter_data.height
	
			push_quad_font(char_quad, state.ui.col_font, state.ui.char_data[letter].uv)
		}
		if letter != 10 do cursor.x += state.ui.char_data[letter].advance
	}
}