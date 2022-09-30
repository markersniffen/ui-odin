package ui

import stb "vendor:stb/truetype"
import "core:os"
import "core:mem"
import "core:fmt"
import "core:math"

// + icon-plus
// - icon-minus

// a icon-left-open
// d icon-right-open
// w icon-up-open
// s icon-down-open

// n icon-left-dir
// m icon-right-dir
// b icon-up-dir
// v icon-down-dir

// g icon-folder
// f icon-folder-open

// c icon-ok
// x icon-cancel
// o icon-circle
// q icon-cog
// p icon-th-list

// r icon-forward
// u icon-reply
// y icon-reply-all

//______ FONT/TEXT ______//

Font :: struct {
	name: string,
	label: string,
	texture: u32,
	texture_size: i32,
	texture_unit: u32,
	char_data: map[rune]Char_Data,
}

Char_Data :: struct {
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
	state.ui.col.base 			= {0.1, 0.1, 0.1, 1}

	state.ui.col.bg 			= {0.1, 0.1, 0.1, 1}
	state.ui.col.bg_light 		= {0.1, 0.1, 0.1, 1}

	state.ui.col.border 		= {0.3, 0.3, 0.3, 1}
	state.ui.col.border_light 	= {0.5, 0.5, 0.5, 1}

	state.ui.col.font 			= {  1,   1,   1, 1}
	state.ui.col.font_hot 		= {  1, 0.6, 0.6, 1}

	state.ui.col.hot 			= {0.4, 0.4, 0.3, 1}
	state.ui.col.active 		= {0.8, 0.4, 0.1, 1}
	
	state.ui.col.highlight 		= {0.0, 0.2,   1, 1}
}

ui_load_font :: proc(font: ^Font) {
	using stb, mem, fmt
	NUM_CHARS :: 96
	
	fmt.println(fmt.tprintf("trying to load fonts/%v.ttf", font.name ))
	data, data_ok := os.read_entire_file(fmt.tprintf("fonts/%v.ttf", font.name))
	defer delete(data)
	if !data_ok do fmt.println("failed to load font file:", font.name)

	image:= alloc(int(font.texture_size * font.texture_size))
	defer free(image)

	stb_char_data, char_data_ok:= make([]bakedchar, NUM_CHARS)
	defer delete(stb_char_data)

	BakeFontBitmap(raw_data(data), 0, state.ui.font_size, cast([^]u8)image, font.texture_size, font.texture_size, 32, NUM_CHARS, raw_data(stb_char_data))

	for b, i in stb_char_data
	{
		pixel_divider := 1.0 / f32(font.texture_size)

		char_data: Char_Data
		
		char_data.offset = {f32(b.xoff), f32(b.yoff + state.ui.font_size)}
		char_data.width = f32(b.x1 - b.x0)
		char_data.height = f32(b.y1 - b.y0)
		char_data.advance = b.xadvance

		char_data.uv.l = f32(b.x0) * pixel_divider
		char_data.uv.t = f32(b.y0) * pixel_divider
		char_data.uv.r = f32(b.x1) * pixel_divider
		char_data.uv.b = f32(b.y1) * pixel_divider

		font.char_data[rune(i + 32)] = char_data
	}

	if opengl_load_texture(font, image) {
		fmt.println(fmt.tprintf("Font loaded: %v", font.name))
	}
}

ui_set_font_size :: proc(size: f32 = 18) {
	state.ui.font_size = size

	ui_load_font(&state.ui.font)
	ui_load_font(&state.ui.icons)

	letter_data := state.ui.font.char_data['W']
	state.ui.font_offset_y = math.round((state.ui.font_size - letter_data.height) * 0.5)
	state.ui.margin = 4
	state.ui.line_space = state.ui.font_size + (state.ui.margin * 2) // state.ui.margin * 2 + state.ui.font_size
}

draw_editable_text :: proc(editing: bool, editable: ^Editable_String, quad: Quad, align: Text_Align = .LEFT, color: v4 = {1,1,1,1}) {
	using stb

	text := editable_to_string(editable)

	left_align: f32 = quad.l
	top_align: f32 = quad.t + state.ui.margin
	text_height: f32 = state.ui.font_size
	text_width: f32
	cursor : Quad

	found_start := false
	for i in 0..=editable.len + 1 {
		if editing {
			if i == editable.start || i == editable.end {
				if found_start == false {
					cursor = {text_width, quad.t + 6, text_width + 2, quad.b + 2}
					found_start = true
				} else {
					cursor.r = text_width
				}
			}
		}
		if i < len(text) {
			text_width += state.ui.font.char_data[rune(text[i])].advance
		}
	}

	if align == .CENTER {
		left_align = (left_align - text_width / 2) + ((quad.r - quad.l) / 2)
	} else if align == .RIGHT {
		left_align -= text_width + state.ui.margin
	}

	if align == .LEFT {
		left_align += state.ui.margin
	}

	top_left : v2 = { left_align, top_align }

	cursor.l += left_align
	cursor.r += left_align

	push_quad_solid(cursor, state.ui.col.active)

	for letter, i in text
	{
		letter_data : Char_Data = state.ui.font.char_data[letter]
		if letter != ' '
		{
			char_quad : Quad
			char_quad.l = top_left.x + letter_data.offset.x
			char_quad.t = top_left.y + letter_data.offset.y
			char_quad.r = char_quad.l + letter_data.width
			char_quad.b = char_quad.t + letter_data.height
			clamped_quad, ok := quad_clamp_or_reject(char_quad, quad)

			if ok  {
				push_quad_font(clamped_quad, color, letter_data.uv, 1)
			}
		}
		top_left.x += letter_data.advance
	}
}

draw_text :: proc(text: string, quad: Quad, align: Text_Align = .LEFT, color: v4 = {1,1,1,1} ) {
	using stb

	left_align: f32 = quad.l
	top_align: f32 = quad.t + state.ui.margin
	text_height: f32 = state.ui.font_size
	text_width: f32

	if align != .LEFT
	{
		skip: int = 0
		for letter, i in text {
			if letter == '#' {
				if (len(text) - i) > 3 {
					if text[i:i+3] == "###" {
						skip = 4
					}
				}
			}
			if skip == 0 {
				text_width += state.ui.font.char_data[letter].advance
			} else if skip == 1 {
				text_width += state.ui.icons.char_data[letter].advance
			}
			skip = clamp(skip - 1, 0, 4)
		}

		if align == .CENTER {
			left_align = (left_align - text_width / 2) + ((quad.r - quad.l) / 2)
		} else if align == .RIGHT {
			left_align -= text_width + state.ui.margin
		}
	} else {
		left_align += state.ui.margin
	}

	top_left : v2 = { left_align, top_align }

	skip: int = 1
	for letter, i in text
	{
		if letter == '#' {
			if (len(text) - i) > 3 {
				if text[i:i+3] == "###" {
					skip = 5
				}
			}
		}
		letter_data : Char_Data = state.ui.font.char_data[letter]
		if skip == 2 do letter_data = state.ui.icons.char_data[letter]
		if skip > 2 {
		} else {
			if letter != ' '
			{
				char_quad : Quad
				char_quad.l = top_left.x + letter_data.offset.x
				char_quad.t = top_left.y + letter_data.offset.y
				char_quad.r = char_quad.l + letter_data.width
				char_quad.b = char_quad.t + letter_data.height
				clamped_quad, ok := quad_clamp_or_reject(char_quad, quad)

				// if pt_in_quad({char_quad.r, char_quad.b}, quad) {
				if ok  {
					push_quad_font(clamped_quad, color, letter_data.uv, f32(skip))
				}
			}
			top_left.x += letter_data.advance
		}
		skip = clamp(skip - 1, 1, 5)
	}
}

draw_text_multiline :: proc(text:string, quad:Quad, align:Text_Align=.LEFT, kerning:f32=-2) {
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

ui_text_size :: proc(axis: int, text: ^Short_String) -> f32 {
	size: f32
	if axis == X {
		for letter in short_to_string(text) {
			size += state.ui.font.char_data[letter].advance
		}
	} else if axis == Y {
		lines: f32 = 1
		for letter in short_to_string(text) {
			if letter == '\n' do lines += 1
		}
		size = lines * state.ui.line_space
	}
	return size
}

ui_text_string_size :: proc(axis: int, text: string) -> f32 {
	size: f32
	if axis == X {
		for letter in text {
			size += state.ui.font.char_data[letter].advance
		}
	} else if axis == Y {
		lines: f32 = 1
		for letter in text {
			if letter == '\n' do lines += 1
		}
		size = lines * state.ui.line_space
	}
	return size
}

ui_editable_string_size :: proc(axis: int, editable: ^Editable_String) -> f32 {
	size: f32
	text := editable_to_string(editable)
	if axis == X {
		for letter in text {
			size += state.ui.font.char_data[letter].advance
		}
	} else if axis == Y {
		lines: f32 = 1
		for letter in text {
			if letter == '\n' do lines += 1
		}
		size = lines * state.ui.line_space
	}
	return size
}