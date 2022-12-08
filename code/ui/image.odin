package ui

import "core:image/png"
import "core:bytes"
import "core:fmt"

Image :: struct {
	width: int,
	height: int,
	aspect: f32,
	path: String,
}

load_image :: proc(path: string, image:^Image) {
	img, iok := png.load(path)
	defer png.destroy(img)
	image.height = img.height
	image.width = img.width
	image.aspect = f32(img.height)/f32(img.width)
	image.path = from_odin_string(path)
	sokol_load_texture(raw_data(bytes.buffer_to_bytes(&img.pixels)), image)
}