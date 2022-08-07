package snui

import gl "vendor:OpenGL"
import glfw "vendor:glfw"

uid :: u64

v2 :: [2]f32
v3 :: [3]f32
v4 :: [4]f32

v2i :: [2]i32
v3i :: [3]i32
v4i :: [4]i32

state: ^State

State :: struct {
	window: glfw.WindowHandle,
	render: Gl,
	window_size: v2i,
	mouse: Mouse,
	keys: Keys,
	mode: Mode,
}

Mode :: enum {
	EDIT,
	TYPE,
}

Mouse :: struct {
	pos: v2i,
	delta: v2i,
	left: Button,
	right: Button,
	middle: Button,
	scroll: f32,
}

Button :: enum { 
	UP,
	CLICK,
	DRAG,
	LOCKED,
}

Keys :: struct
{
	left: bool,
	right: bool,
	up: bool,
	down: bool,

	escape: bool,
	tab: bool,
	enter: bool,
	space: bool,
	backspace: bool,
	delete: bool,

	n_enter: bool,
	n_plus: bool,
	n_minus: bool,

	ctrl: bool,
	alt: bool,
	shift: bool,
}