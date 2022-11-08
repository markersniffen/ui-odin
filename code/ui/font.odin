package ui

when PROFILER do import tracy "../../../odin-tracy"

import stb "vendor:stb/truetype"
import "core:os"
import "core:mem"
import "core:fmt"
import "core:strconv"
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

// DEFAULT FONT //

// default_bold_info := ""
// default_bold_image : [65536]u8

// default_icons_info := ""
// default_icons_image : [65536]u8

Font :: struct {
	name: string,
	path: string,
	label: string,
	texture: u32,
	texture_size: i32,
	texture_unit: u32,
	char_data: map[rune]Char_Data,
	default_info: ^string,
	default_image: ^[65536]u8,
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

	// TODO DEBUG
	state.debug.text = from_string("xxxxx-----")
	state.debug.para = from_string("Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.")
	state.debug.path = from_string("C:/Users/marxn/Desktop/test2.txt")
	state.debug.float = 3.534
	load_doc(&state.debug.lorem, "./assets/temp.txt")
}

ui_load_font :: proc(font: ^Font) -> bool {
	using stb, mem, fmt
	NUM_CHARS :: 96
	
	fmt.println(fmt.tprint("trying to load", font.path))
	data, data_ok := os.read_entire_file(font.path)
	defer delete(data)
	
	if !data_ok {
		fmt.println("failed to load font file:", font.name)
		return false
	} else {
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

		if opengl_load_font_texture(font, image) {
			fmt.println("Font loaded:", font.name)
		}

		// fmt.println("------- FOR PRINTING FONT INFO --------")
		// for char in font.char_data {
		// 	cc, ok := font.char_data[char]
		// 	fmt.print(int(char), cc.offset.x, cc.offset.y, cc.width, cc.height, cc.advance, cc.uv.l, cc.uv.t, cc.uv.r, cc.uv.b, "\n")
		// }

		// fmt.println("--------- FOR PRINTING IMAGE INFO ----------")
		// for i in 0..<int(font.texture_size * font.texture_size) {
		// 	fmt.print(fmt.tprint("%v%v", (cast([^]u8)image)[i], ','))
		// }
	}
	
	if font.label == "regular_texture" {
		letter_data := state.ui.fonts.regular.char_data['W']
		state.ui.font_offset_y = math.round((state.ui.font_size - letter_data.height) * 0.5)
		state.ui.margin = 4
		state.ui.line_space = state.ui.font_size + (state.ui.margin * 2) // state.ui.margin * 2 + state.ui.font_size
	}
	fmt.println("Loaded font file:", font.name)
	return true
}

ui_load_default_font :: proc(font: ^Font) {
	start : int
	item : int
	char : rune
	for char_id, index in font.default_info {
		if rune(char_id) == ' ' || rune(char_id) == '\n' {
			val_string := font.default_info[start:index]
			if item == 0 {
					char_data : Char_Data
					val, vok := strconv.parse_int(val_string)
					char = rune(val)
					font.char_data[char] = char_data
			} else {
				cc, c_ok := &font.char_data[char]
				val, vok := strconv.parse_f32(val_string)
				if vok && c_ok {
					switch item {
						case 1:
						cc.offset.x = val
						case 2:
						cc.offset.y = val
						case 3:
						cc.width = val
						case 4:
						cc.height = val
						case 5:
						cc.advance = val
						case 6:
						cc.uv.l = val
						case 7:
						cc.uv.t = val
						case 8:
						cc.uv.r = val
						case 9:
						cc.uv.b = val
					}
				} else {
				}
			}

			item += 1
			start = index+1
		}
		if rune(char_id) == '\n' {
			item = 0
			start = index + 1
		}
	}
	if font.label == "regular_texture" {
		letter_data := state.ui.fonts.regular.char_data['W']
		state.ui.font_offset_y = math.round((state.ui.font_size - letter_data.height) * 0.5)
		state.ui.margin = 4
		state.ui.line_space = state.ui.font_size + (state.ui.margin * 2) // state.ui.margin * 2 + state.ui.font_size
	}
	if opengl_load_font_texture(font, font.default_image) {
		fmt.println(fmt.tprint("DEFAULT Font loaded:", font.name))
	}	
}

ui_set_font_size :: proc(size: f32 = 18) {
	state.ui.font_size = size

	if !ui_load_font(&state.ui.fonts.regular) {
		if !ui_set_font_regular("Arial", "C:/Windows/Fonts/ARIAL.ttf") {
			ui_load_default_font(&state.ui.fonts.regular)
		}
	}
	if !ui_load_font(&state.ui.fonts.bold) {
		if !ui_set_font_bold("Arial", "C:/Windows/Fonts/ARIALBD.ttf") {
			ui_load_default_font(&state.ui.fonts.bold)
		}
	}
	if !ui_load_font(&state.ui.fonts.italic) {
		if !ui_set_font_italic("Arial", "C:/Windows/Fonts/ARIALI.ttf") {
			ui_load_default_font(&state.ui.fonts.italic)
		}
	}
	if !ui_load_font(&state.ui.fonts.light) {
		if !ui_set_font_light("Arial", "C:/Windows/Fonts/ARIALN.ttf") {
			ui_load_default_font(&state.ui.fonts.light)
		}
	}
	if !ui_load_font(&state.ui.fonts.icons) {
		ui_load_default_font(&state.ui.fonts.icons)
	}
}

ui_set_font :: proc(font: ^Font, name, path: string) -> bool {
	font.name = name
	font.path = path
	return ui_load_font(font)
}

ui_set_font_regular :: proc(name, path: string) -> bool { return ui_set_font(&state.ui.fonts.regular, name, path) }
ui_set_font_bold :: proc(name, path: string) -> bool { return ui_set_font(&state.ui.fonts.bold, name, path) }
ui_set_font_italic :: proc(name, path: string) -> bool { return ui_set_font(&state.ui.fonts.italic, name, path) }
ui_set_font_light :: proc(name, path: string) -> bool { return ui_set_font(&state.ui.fonts.light, name, path) }
ui_set_font_icons :: proc(name, path: string) -> bool { return ui_set_font(&state.ui.fonts.icons, name, path) }

draw_editable_text :: proc(editing: bool, editable: ^String, quad: Quad, align: Text_Align = .LEFT, color: HSL = {1,1,1,1}, clip:Quad) {
	using stb

	text := to_string(editable)

	left_align: f32 = quad.l
	top_align: f32 = quad.t + state.ui.margin
	text_height: f32 = state.ui.font_size
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
			text_width += state.ui.fonts.regular.char_data[rune(text[i])].advance
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

	cursor_clamped_quad, c_ok := quad_clamp_or_reject(cursor, clip)
	if c_ok {
		push_quad_solid(cursor, state.ui.col.active, cursor_clamped_quad)
	}

	for letter, i in text
	{
		letter_data : Char_Data = state.ui.fonts.regular.char_data[letter]
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

get_font_from_pattern :: proc(text: string, i: int, current_font: Font) -> (Font, bool) {
	if text[i] == '<' {
		if i+2 < len(text) {
			if text[i+2] == '>' {
				switch text[i+1] {
					case 'r':
					return state.ui.fonts.regular, true
					case 'b':
					return state.ui.fonts.bold, true
					case 'i':
					return state.ui.fonts.italic, true
					case 'l':
					return state.ui.fonts.light, true
					case '#':
					return state.ui.fonts.icons, true
				}
			}
		}
	}
	return current_font, false
}

draw_editable_text_WITH_BOLD_ITALICS :: proc(editing: bool, es: ^String, quad: Quad, align: Text_Align = .LEFT, color: HSL = {1,1,1,1} ) {
	using stb
	
	text := to_string(es)

	left_align: f32 = quad.l
	top_align: f32 = quad.t + state.ui.margin
	text_height: f32 = state.ui.font_size
	text_width: f32
	cursor : Quad // NOTE special

	if align != .LEFT || editing
	{
		i := 0
		font := state.ui.fonts.regular
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
		left_align += state.ui.margin
	} else if align == .CENTER {
		left_align = (left_align - text_width / 2) + ((quad.r - quad.l) / 2)
	} else if align == .RIGHT {
		left_align -= text_width + state.ui.margin
	}
	
	top_left : v2 = { left_align, top_align }
	cursor.l += left_align // NOTE Special
	cursor.r += left_align // NOTE Special
	push_quad_solid(cursor, state.ui.col.active, quad) // NOTE Special

	i := 0
	font := state.ui.fonts.regular
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
					push_quad_font(quad, color, font.char_data[letter].uv, f32(font.texture_unit+1), clamped_quad)

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
	top_align: f32 = quad.t + state.ui.margin
	text_height: f32 = state.ui.font_size
	text_width: f32

	if align != .LEFT
	{
		i := 0
		font := state.ui.fonts.regular
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
			left_align = quad.r - text_width - state.ui.margin
		}
	} else {
		left_align += state.ui.margin
	}
	
	top_left : v2 = { left_align, top_align }

	i := 0
	font := state.ui.fonts.regular
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
					push_quad_font(char_quad, color, font.char_data[letter].uv, f32(font.texture_unit+1), clamped_quad)

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
				text_width += state.ui.fonts.regular.char_data[letter].advance
			} else if skip == 1 {
				text_width += state.ui.fonts.icons.char_data[letter].advance
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
		letter_data : Char_Data = state.ui.fonts.regular.char_data[letter]
		if skip == 2 do letter_data = state.ui.fonts.icons.char_data[letter]
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
draw_text_multiline :: proc(value:any, quad:Quad, align:Text_Align=.LEFT, kerning:f32=-2, clip: Quad) {
	when PROFILER do tracy.ZoneNC("Draw multiline text", 0xff0000)
	assert(value.id == Document)	
	text : string = "FAILED TO LOAD TEXT"
	val : Document
	
	if value.id == Document {
		val = (cast(^Document)value.data)^
		text = string(val.mem)
	}

	lines := 0
	last_space := 0
	start := 0
	width : f32 = 0
	i : int = 0
	for i < len(val.mem) {
		char := val.mem[i]
		if char == ' ' do last_space = i
		return_break := (char == '\n')
		width_break := (width >= val.width-30)
		last_char := (i == len(val.mem)-1)

		if return_break || width_break || last_char {
			jump := f32(lines) * (state.ui.line_space-4)
			if width_break {
				if last_space > start do i = last_space+1
			}
			text_slice := text[start:i]
			if last_char do text_slice = text[start:]
			if lines >= val.current_line-5 && lines <= val.last_line+5 {
				draw_text(text_slice, {quad.l, quad.t + jump, quad.r, quad.t + jump + state.ui.line_space}, align, state.ui.col.font, clip)
			} else if lines > val.last_line+5 {
				return
			}
			if val.mem[i] == ' ' do i += 1
			start = i
			width = 0
			lines += 1
		} else {
			width += state.ui.fonts.regular.char_data[rune(char)].advance
		}
		i += 1

	}
}

ui_text_size :: proc(axis: int, text: ^String) -> f32 {
	size: f32
	if axis == X {
		for letter in to_string(text) {
			size += state.ui.fonts.regular.char_data[letter].advance
		}
	} else if axis == Y {
		lines: f32 = 1
		for letter in to_string(text) {
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
			size += state.ui.fonts.regular.char_data[letter].advance
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

ui_String_size :: proc(axis: int, editable: ^String) -> f32 {
	size: f32
	text := to_string(editable)
	if axis == X {
		for letter in text {
			size += state.ui.fonts.regular.char_data[letter].advance
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
