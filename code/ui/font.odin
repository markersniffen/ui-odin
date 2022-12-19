package ui

when PROFILER do import tracy "../../../odin-tracy"

import stb "vendor:stb/truetype"
import sg "../../../sokol-odin/sokol/gfx"
import "core:os"
import "core:mem"
import "core:fmt"
import "core:strconv"
import "core:math"

import "core:encoding/json"

default_font_pixels :: #load("default_font_pixels.txt")
default_char_data := #load("default_font_char_data.txt", []Char_Data)

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

// DEFAULT FONT //

// default_bold_info := ""
// default_bold_image : [65536]u8

// default_icons_info := ""
// default_icons_image : [65536]u8

Weight :: struct {
	type : Weight_Type,
	path : string,
	char_data: map[rune]Char_Data,
}

Weight_Type :: enum {
	REGULAR,
	BOLD,
	ITALIC,
	ICONS,
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

init_font :: proc(size:f32=18) {
	state.font.size = size
	
	state.font.weight[Weight_Type.REGULAR].path 	= "fontsx/Roboto-Regular.ttf"
	state.font.weight[Weight_Type.BOLD].path 		= "fontsx/Roboto-Bold.ttf"
	state.font.weight[Weight_Type.ITALIC].path 	= "fontsx/Roboto-Italic.ttf"
	state.font.weight[Weight_Type.ICONS].path 	= "fontsx/ui_icons.ttf"

	load_font()
}

load_font :: proc() {
	runes : []rune = {' ','!','"','#','$','%','&','\'','(',')','*','+',',','-','.','/','0','1','2','3','4','5','6','7','8','9',':',';','<','=','>','?','@','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','[','\\',']','^','_','`','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','{','|','}','~'}
	// icon_runes : []rune = {'+','-','a','d','w','s','n','m','b','v','g','f','c','x','o','q','p','r','u','y'}
	num_runes := i32(len(runes))
	first_rune :i32= 32
	
	// check font files
	files_ok := true
	for font in state.font.weight {
		handle, err := os.open(font.path)
		defer os.close(handle)
		if err != 0 do files_ok = false
	}

	fmt.println("FILES LOADED OK?", files_ok)

	ctx : stb.pack_context
	width :i32= 512
	height :i32= 512
	pixels := make([^]byte, width*height)

	if stb.PackBegin(&ctx, pixels, width, height, 0, 1, nil) == 0 {
		fmt.println("FONT PACK INIT FAILED")
		return
	}

	temp_char_data:= make([]Char_Data, len(runes) * 4, context.temp_allocator)
	temp_char_data_index := 0

	// TODO oversampling?
	// stb.PackSetOversampling(&ctx, 2, 2)

	for font, index in &state.font.weight {
		if files_ok {
			font.type = Weight_Type(index)
			char_data, char_data_ok := make([]stb.packedchar, num_runes)
			defer delete(char_data)

			rng : stb.pack_range = {
				font_size = 20,
				first_unicode_codepoint_in_range = first_rune,
				array_of_unicode_codepoints = raw_data(runes),
				num_chars = num_runes,
				chardata_for_range = &char_data[0],
			}

			fontdata, data_ok := os.read_entire_file(font.path)
			defer delete(fontdata)
			if data_ok {
				fmt.println(font.path, "loaded.")
				stb.PackFontRanges(&ctx, raw_data(fontdata), 0, &rng, 1)

				for b, i in char_data
				{
					pixel_divider := 1.0 / f32(512)

					char_data: Char_Data
					
					char_data.offset = {f32(b.xoff), f32(b.yoff + state.font.size)}
					char_data.width = f32(b.x1 - b.x0)
					char_data.height = f32(b.y1 - b.y0)
					char_data.advance = b.xadvance

					char_data.uv.l = f32(b.x0) * pixel_divider
					char_data.uv.t = f32(b.y0) * pixel_divider
					char_data.uv.r = f32(b.x1) * pixel_divider
					char_data.uv.b = f32(b.y1) * pixel_divider

					font.char_data[rune(i + 32)] = char_data
					temp_char_data[temp_char_data_index] = char_data
					temp_char_data_index += 1
				}
			}
		} else {
			// load default char_data
			for i in 0..<len(runes) {
				font.char_data[runes[i]] = default_char_data[i + (index * (len(default_char_data)/4))]
			}
		}
	}

	letter_data := state.font.weight[Weight_Type.REGULAR].char_data['W']
	state.font.offset_y = math.round((state.font.size - letter_data.height) * 0.5)
	state.font.margin = 4
	state.font.line_space = state.font.size + (state.font.margin * 2) // state.font.margin * 2 + state.font.size

	image : Image = {
		width = int(width),
		height = int(height),
		aspect = 0.5,
		path = from_odin_string("gah"),
	}

	// for saving default font files...
	// file, _ := os.open("../code/ui/default_font_pixels.txt", os.O_CREATE)
	// os.write_ptr(file, pixels, int(width*height))
	// os.close(file)

	// file, _ := os.open("../code/ui/default_font_char_data.txt", os.O_CREATE)
	// os.write_ptr(file, raw_data(temp_char_data), len(temp_char_data) * size_of(Char_Data))
	// os.close(file)

	if !files_ok {
		pixels = raw_data(default_font_pixels)
		fmt.println("ttf fonts failed to load, using defaults...")
	}

	tex_image := sg.make_image({
		width = width,
		height = width,
		pixel_format = .R8,
		data = { subimage = { 0 = { 0 = { ptr = pixels, size = u64(width * width) } } } },
	})

	for layer in &state.sokol.layers {
		layer.bind.fs_images[0] = tex_image
	}

	sokol_load_texture(pixels, width, height, 1)
}

set_font :: proc(weight: ^Weight, name, path: string) {
	// weight.name = name
	weight.path = path
	init_font(state.font.size)
}

set_font_regular :: proc(name, path: string) { set_font(&state.font.weight[Weight_Type.REGULAR], name, path) }
set_font_bold :: proc(name, path: string) { set_font(&state.font.weight[Weight_Type.BOLD], name, path) }
set_font_italic :: proc(name, path: string) { set_font(&state.font.weight[Weight_Type.ITALIC], name, path) }
set_font_icons :: proc(name, path: string) { set_font(&state.font.weight[Weight_Type.ICONS], name, path) }

draw_editable_text :: proc(editing: bool, editable: ^String, quad: Quad, align: Text_Align = .LEFT, color: HSL = {1,1,1,1}, clip:Quad) {
	using stb

	text := to_odin_string(editable)

	left_align: f32 = quad.l
	top_align: f32 = quad.t + state.font.margin
	text_height: f32 = state.font.size
	text_width: f32
	cursor : Quad // NOTE special

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
			text_width += state.font.weight[Weight_Type.REGULAR].char_data[rune(text[i])].advance
		}
	}

	if align == .CENTER {
		left_align = (left_align - text_width / 2) + ((quad.r - quad.l) / 2)
	} else if align == .RIGHT {
		left_align -= text_width + state.font.margin
	}

	if align == .LEFT {
		left_align += state.font.margin
		// if cursor.r > quad.r - 20 {
		// 	left_align -= cursor.r - quad.r + 20
		// }
	}

	top_left : v2 = { left_align, top_align }

	cursor.l += left_align
	cursor.r += left_align

	cursor_clamped_quad, c_ok := quad_clamp_or_reject(cursor, clip)
	if c_ok {
		push_quad_solid(cursor, state.col.active, cursor_clamped_quad)
	}

	for letter, i in text
	{
		letter_data : Char_Data = state.font.weight[Weight_Type.REGULAR].char_data[letter]
		if letter != ' '
		{
			char_quad : Quad
			char_quad.l = top_left.x + letter_data.offset.x
			char_quad.t = top_left.y + letter_data.offset.y
			char_quad.r = char_quad.l + letter_data.width
			char_quad.b = char_quad.t + letter_data.height
			clamped_quad, ok := quad_clamp_or_reject(char_quad, clip)

			if ok  {
				push_quad_font(char_quad, color, letter_data.uv, 1, clamped_quad)
			}
		}
		top_left.x += letter_data.advance
	}
}

get_font_from_pattern :: proc(text: string, i: int, current_font: Weight) -> (Weight, bool) {
	if text[i] == '<' {
		if i+2 < len(text) {
			if text[i+2] == '>' {
				switch text[i+1] {
					case 'r':
						return state.font.weight[Weight_Type.REGULAR], true
					case 'b':
						return state.font.weight[Weight_Type.BOLD], true
					case 'i':
						return state.font.weight[Weight_Type.ITALIC], true
					case 'l':
						return state.font.weight[Weight_Type.REGULAR], true
					case '#':
						return state.font.weight[Weight_Type.ICONS], true
				}
			}
		}
	}
	return current_font, false
}

draw_editable_text_WITH_BOLD_ITALICS :: proc(editing: bool, es: ^String, quad: Quad, align: Text_Align = .LEFT, color: HSL = {1,1,1,1} ) {
	using stb
	
	text := to_odin_string(es)

	left_align: f32 = quad.l
	top_align: f32 = quad.t + state.font.margin
	text_height: f32 = state.font.size
	text_width: f32
	cursor : Quad // NOTE special

	if align != .LEFT || editing
	{
		i := 0
		font := state.font.weight[Weight_Type.REGULAR]
		found_start := false
		for i < len(text)+1 {
			if editing {
				if i == es.start || i == es.end {
					if found_start == false {
						cursor = {text_width, quad.t + 6, text_width + 2, quad.b + 2}
						found_start = true
					} else {
						cursor.r = text_width
					}
				}
			}

			if i < len(text) {
				letter := rune(text[i])
				_font, change_font := get_font_from_pattern(text, i, font)
				if change_font {
					font = _font
					i += 2
				} else {
					text_width += font.char_data[letter].advance
				}
			}
			i += 1
		}
	}

	if align == .LEFT {
		left_align += state.font.margin
	} else if align == .CENTER {
		left_align = (left_align - text_width / 2) + ((quad.r - quad.l) / 2)
	} else if align == .RIGHT {
		left_align -= text_width + state.font.margin
	}
	
	top_left : v2 = { left_align, top_align }
	cursor.l += left_align // NOTE Special
	cursor.r += left_align // NOTE Special
	push_quad_solid(cursor, state.col.active, quad) // NOTE Special

	i := 0
	font := state.font.weight[Weight_Type.REGULAR]
	for i < len(text) {
		letter := rune(text[i])
		_font, change_font := get_font_from_pattern(text, i, font)
		if change_font {
			font = _font
			i += 3
		} else {
			if letter != ' '
			{
				char_quad : Quad
				char_quad.l = top_left.x + font.char_data[letter].offset.x
				char_quad.t = top_left.y + font.char_data[letter].offset.y
				char_quad.r = char_quad.l + font.char_data[letter].width
				char_quad.b = char_quad.t + font.char_data[letter].height
				clamped_quad, ok := quad_clamp_or_reject(char_quad, quad)
				if ok  {
					skip :f32= 1
					push_quad_font(quad, color, font.char_data[letter].uv, 1, clamped_quad)
				}
			}
			top_left.x += font.char_data[letter].advance
			i += 1
		}
	}
}

draw_text :: proc(text: string, quad: Quad, align: Text_Align = .LEFT, color: HSL = {1,1,1,1}, clip:Quad) {
	when PROFILER do tracy.ZoneNC("Draw Text", 0x00aaaa)
	using stb
	
	left_align: f32 = quad.l
	top_align: f32 = quad.t + state.font.margin
	text_height: f32 = state.font.size
	text_width: f32

	quad_height := quad.b - quad.t

	if quad_height > state.font.line_space {
		top_align += (quad_height - state.font.line_space) / 2
	}

	if align != .LEFT
	{
		i := 0
		font := state.font.weight[Weight_Type.REGULAR]
		for i < len(text) {
			letter := rune(text[i])
			_font, change_font := get_font_from_pattern(text, i, font)
			if change_font {
				font = _font
				i += 3
			} else {
				text_width += font.char_data[letter].advance
				i += 1
			}
		}

		if align == .CENTER {
			left_align = (left_align - text_width / 2) + ((quad.r - quad.l) / 2)
		} else if align == .RIGHT {
			left_align = quad.r - text_width - state.font.margin
		}
	} else {
		left_align += state.font.margin
	}
	
	top_left : v2 = { left_align, top_align }

	i := 0
	font := state.font.weight[Weight_Type.REGULAR]
	for i < len(text) {
		letter := rune(text[i])
		_font, change_font := get_font_from_pattern(text, i, font)
		if change_font {
			font = _font
			i += 3
		} else {
			if letter != ' '
			{
				char_quad : Quad
				char_quad.l = top_left.x + font.char_data[letter].offset.x
				char_quad.t = top_left.y + font.char_data[letter].offset.y
				char_quad.r = char_quad.l + font.char_data[letter].width
				char_quad.b = char_quad.t + font.char_data[letter].height
				clamped_quad, ok := quad_clamp_or_reject(char_quad, clip)
				if ok  {
					skip :f32= 1
					push_quad_font(char_quad, color, font.char_data[letter].uv, 1, clamped_quad)
				}
			}
			top_left.x += font.char_data[letter].advance
			i += 1
		}
	}
}

draw_text_OLD :: proc(text: string, quad: Quad, align: Text_Align = .LEFT, color: HSL = {1,1,1,1} ) {
	using stb

	left_align: f32 = quad.l
	top_align: f32 = quad.t + state.font.margin
	text_height: f32 = state.font.size
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
				text_width += state.font.weight[Weight_Type.REGULAR].char_data[letter].advance
			} else if skip == 1 {
				text_width += state.font.weight[Weight_Type.ICONS].char_data[letter].advance
			}
			skip = clamp(skip - 1, 0, 4)
		}

		if align == .CENTER {
			left_align = (left_align - text_width / 2) + ((quad.r - quad.l) / 2)
		} else if align == .RIGHT {
			left_align -= text_width + state.font.margin
		}
	} else {
		left_align += state.font.margin
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
		letter_data : Char_Data = state.font.weight[Weight_Type.REGULAR].char_data[letter]
		if skip == 2 do letter_data = state.font.weight[Weight_Type.ICONS].char_data[letter]
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
					push_quad_font(quad, color, letter_data.uv, f32(skip), clamped_quad)
				}
			}
			top_left.x += letter_data.advance
		}
		skip = clamp(skip - 1, 1, 5)
	}
}

// TODO Redo this whole thing, based of of []u8
draw_text_multiline :: proc(value:^String, quad:Quad, align:Text_Align=.LEFT, kerning:f32=-2, clip: Quad) {
	when PROFILER do tracy.ZoneNC("Draw multiline text", 0xff0000)
	// assert(value.id == Document)	
	// text : string = "FAILED TO LOAD TEXT"
	// val : Document
	
	// if value.id == Document {
	// 	val = (cast(^Document)value.data)^
	// 	text = string(val.mem)
	// }

	text := value.mem

	lines := 0
	last_space := 0
	start := 0
	width : f32 = 0
	i : int = 0
	for i < len(text) {
		char := text[i]
		if char == ' ' do last_space = i
		return_break := (char == '\n')
		width_break := (width >= value.width-30)
		last_char := (i == len(text)-1)

		if return_break || width_break || last_char {
			jump := f32(lines) * (state.font.line_space-4)
			if width_break {
				if last_space > start do i = last_space+1
			}
			text_slice := value.mem[start:i]
			if last_char do text_slice = value.mem[start:]
			if lines >= value.current_line-5 && lines <= value.last_line+5 {
				draw_text(string(text_slice), {quad.l, quad.t + jump, quad.r, quad.t + jump + state.font.line_space}, align, state.col.font, clip)
			} else if lines > value.last_line+5 {
				return
			}
			if text[i] == ' ' do i += 1
			start = i
			width = 0
			lines += 1
		} else {
			width += state.font.weight[Weight_Type.REGULAR].char_data[rune(char)].advance
		}
		i += 1

	}
}

text_size :: proc(axis: Axis, text: ^String) -> f32 {
	size: f32
	if axis == .X {
		for letter in to_odin_string(text) {
			size += state.font.weight[Weight_Type.REGULAR].char_data[letter].advance
		}
	} else if axis == .Y {
		lines: f32 = 1
		for letter in to_odin_string(text) {
			if letter == '\n' do lines += 1
		}
		size = lines * state.font.line_space
	}
	return size
}

text_string_size :: proc(axis: Axis, text: string) -> f32 {
	size: f32
	if axis == .X {
		for letter in text {
			size += state.font.weight[Weight_Type.REGULAR].char_data[letter].advance
		}
	} else if axis == .Y {
		lines: f32 = 1
		for letter in text {
			if letter == '\n' do lines += 1
		}
		size = lines * state.font.line_space
	}
	return size
}

String_size :: proc(axis: Axis, editable: ^String) -> f32 {
	size: f32
	text := to_odin_string(editable)
	if axis == .X {
		for letter in text {
			size += state.font.weight[Weight_Type.REGULAR].char_data[letter].advance
		}
	} else if axis == .Y {
		lines: f32 = 1
		for letter in text {
			if letter == '\n' do lines += 1
		}
		size = lines * state.font.line_space
	}
	return size
}