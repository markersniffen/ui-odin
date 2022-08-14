package snui

import stb "vendor:stb/truetype"
import "core:mem"
import "core:fmt"
import "core:os"

Ui :: struct {
	char_data: []stb.bakedchar,

	font_size: f32,			// NOTE pixels tall
	font_size_large: f32,
	font_size_small: f32,
	
	margin: f32,

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

	state.ui.margin = 5

	ui_load_font(state.ui.font_size, "Roboto-Regular")
}

ui_load_font :: proc(font_size: f32, name: string)
{
	using stb, mem, fmt
	NUM_CHARS :: 96
	
	data, data_ok := os.read_entire_file(fmt.tprintf("fonts/%v.ttf", name))
	defer delete(data)
	if !data_ok do fmt.println("failed to load font file")

	image:= alloc(int(state.render.font_texture_size * state.render.font_texture_size))
	defer free(image)
	char_data, char_data_ok:= make([]bakedchar, NUM_CHARS)
	state.ui.char_data = char_data

	BakeFontBitmap(raw_data(data), 0, font_size, cast([^]u8)image, state.render.font_texture_size, state.render.font_texture_size, 32, NUM_CHARS, raw_data(char_data))
	opengl_load_texture(state.render.font_texture, image)
}

draw_text :: proc(text: string, pt: v2, offset: v2 = {0,0})
{
	using stb
	
	// NOTE bottom left of text starts at pt.xy
	// TODO is this good???
	x:= pt.x + offset.x
	y:= pt.y + offset.y
	stb_quad: aligned_quad

	for letter in text
	{
		if letter == 10 // if return, move everything down
		{
			x = pt.x
			y += state.ui.font_size
		} else {
			GetBakedQuad(raw_data(state.ui.char_data), state.render.font_texture_size, state.render.font_texture_size, i32(letter) - 32, &x, &y, &stb_quad, true)
			char_quad : Quad = {stb_quad.x0, stb_quad.y0, stb_quad.x1, stb_quad.y1}
			push_quad_font(char_quad, state.ui.col_font, {stb_quad.s0, stb_quad.t1, stb_quad.s1, stb_quad.t0})
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

//			