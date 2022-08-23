package ui

import "core:fmt"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

WIDTH  	:: 1280
HEIGHT 	:: 720
TITLE 	:: "ui-odin"

Uid :: u64

v2 :: [2]f32
v3 :: [3]f32
v4 :: [4]f32

v2i :: [2]i32
v3i :: [3]i32
v4i :: [4]i32

state: ^State

State :: struct {
	uid: Uid,
	window: glfw.WindowHandle,
	quit: bool,
	render: Gl,
	ui: Ui,
	window_size: v2i,
	mouse: Mouse,
	keys: Keys,
	mode: Mode,

	debug: Debug,
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


init :: proc() -> bool
{
	if !bool(glfw.Init())
	{
		fmt.eprintln("GLFW has failed to load.")
		return false
	}
	
	state.window = glfw.CreateWindow(WIDTH, HEIGHT, TITLE, nil, nil)

	if state.window == nil
	{
		fmt.eprintln("GLFW has failed to load the window.")
		return false
	}

	glfw.MakeContextCurrent(state.window)
	glfw.SetKeyCallback(state.window, cast(glfw.KeyProc)keyboard_callback)
	glfw.SetMouseButtonCallback(state.window, cast(glfw.MouseButtonProc)mouse_callback)
	glfw.SetScrollCallback(state.window, cast(glfw.ScrollProc)scroll_callback)
	glfw.SetCharCallback(state.window, cast(glfw.CharProc)typing_callback)
	glfw.SetWindowUserPointer(state.window, state)

	opengl_init()
	ui_init()

	return true
}

update :: proc()
{
	state.quit = bool(glfw.WindowShouldClose(state.window))
	if state.quit do return

	glfw.PollEvents()

	width, height := glfw.GetWindowSize(state.window)
	state.window_size = {width, height}
	
	mouseX, mouseY := glfw.GetCursorPos(state.window)
	old_mouse := state.mouse.pos
	state.mouse.pos = {i32(mouseX), i32(mouseY)}
	state.mouse.delta = state.mouse.pos - old_mouse
}


quit :: proc()
{
	glfw.DestroyWindow(state.window)
	glfw.Terminate()
	free(state)
}

read_key :: proc(key: ^bool) -> bool
{
	if key^ {
		key^ = false
		return true
	} else {
		return false
	}
}

process_keyboard_input :: proc(action: int, key_state: ^bool, repeat: bool)
{
	if action == int(glfw.RELEASE)
	{
		key_state^ = false
	} else {
		if repeat {
			if action == int(glfw.PRESS) || action == int(glfw.REPEAT)
			{
				key_state^ = true
			}
		} else {
			if action == int(glfw.PRESS)
			{
				key_state^ = true
			}
		}
	}
}

keyboard_callback :: proc(Window: glfw.WindowHandle, key: int, scancode: int, action: int, mods: int)
{
	switch key
	{
		case glfw.KEY_LEFT:				process_keyboard_input(action, &state.keys.left, true)
		case glfw.KEY_RIGHT:			process_keyboard_input(action, &state.keys.right, true)
		case glfw.KEY_UP:				process_keyboard_input(action, &state.keys.up, true)
		case glfw.KEY_DOWN:				process_keyboard_input(action, &state.keys.down, true)
		
		case glfw.KEY_ESCAPE:			process_keyboard_input(action, &state.keys.escape, true)
		case glfw.KEY_TAB:				process_keyboard_input(action, &state.keys.tab, false)
		case glfw.KEY_ENTER:		 	process_keyboard_input(action, &state.keys.enter, true)
		case glfw.KEY_SPACE:			process_keyboard_input(action, &state.keys.space, true)
		case glfw.KEY_BACKSPACE:		process_keyboard_input(action, &state.keys.backspace, true)
		case glfw.KEY_DELETE:			process_keyboard_input(action, &state.keys.delete, true)
		
		case glfw.KEY_KP_ENTER:			process_keyboard_input(action, &state.keys.enter, true)
		case glfw.KEY_KP_SUBTRACT:		process_keyboard_input(action, &state.keys.n_minus, false)
		case glfw.KEY_KP_ADD:			process_keyboard_input(action, &state.keys.n_plus, false)
		
		case glfw.KEY_LEFT_ALT:			process_keyboard_input(action, &state.keys.alt, false)
		case glfw.KEY_RIGHT_ALT:		process_keyboard_input(action, &state.keys.alt, false)
		
		case glfw.KEY_LEFT_CONTROL:		process_keyboard_input(action, &state.keys.ctrl, false)
		case glfw.KEY_RIGHT_CONTROL:	process_keyboard_input(action, &state.keys.ctrl, false)
		
		case glfw.KEY_LEFT_SHIFT:		process_keyboard_input(action, &state.keys.shift, false)
		case glfw.KEY_RIGHT_SHIFT:		process_keyboard_input(action, &state.keys.shift, false)
	}
}

typing_callback :: proc(window: glfw.WindowHandle, codepoint: u32)
{
	// fmt.println(rune(codepoint))
	// State.UILastChar = rune(codepoint);
}

scroll_callback :: proc(window: glfw.WindowHandle, x: f64, y: f64)
{
	state.mouse.scroll = f32(y/10)
}

read_mouse :: proc(button: ^Button, reset:bool=false) -> bool
{
	if button^ == .CLICK {
		if reset do button^ = .UP
		return true
	}
	return false
}


mouse_callback :: proc(window: glfw.WindowHandle, button: int, action: int, mods: int)
{
	mouse_buttons: [3]^Button = { &state.mouse.left, &state.mouse.right, &state.mouse.middle }
	for mouse_button, index in mouse_buttons
	{
		if button == index {
			if action == int(glfw.PRESS) do mouse_button^ = .CLICK
			if action == int(glfw.RELEASE) do mouse_button^ = .UP
		}
	}
}
