package ui

import "core:fmt"
import "core:time"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

when ODIN_OS == .Windows {
	import win "core:sys/windows"
}

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
	window: Window,
	quit: bool,

	start_time: time.Time,
	prev_time: time.Time,
	delta_time: f64,

	render: Gl,
	ui: Ui,
	// window_size: v2i,
	// window_quad: Quad,
	// framebuffer_res: v2i,
	mouse: Mouse,
	keys: Keys,
	mode: Mode,

	debug: Debug,
}

Window :: struct {
	handle: glfw.WindowHandle,
	size: v2i,
	framebuffer: v2i,
	quad: Quad,
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
	scroll: v2,
}

Button :: enum { 
	UP,
	CLICK,
	RELEASE,
	DRAG,
}

Keys :: struct {
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

init :: proc() -> bool {
	if !bool(glfw.Init())
	{
		fmt.eprintln("GLFW has failed to load.")
		return false
	}
	
	if ODIN_OS == .Darwin {
		glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
		glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 1)
		glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
		glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, i32(1))
	}

	state.window.handle = glfw.CreateWindow(WIDTH, HEIGHT, TITLE, nil, nil)

	if state.window.handle == nil
	{
		fmt.eprintln("GLFW has failed to load the window.")
		return false
	}

	glfw.SetWindowPos(state.window.handle, 500,200)
	glfw.MakeContextCurrent(state.window.handle)
	glfw.SetKeyCallback(state.window.handle, cast(glfw.KeyProc)keyboard_callback)
	glfw.SetMouseButtonCallback(state.window.handle, cast(glfw.MouseButtonProc)mouse_callback)
	glfw.SetScrollCallback(state.window.handle, cast(glfw.ScrollProc)scroll_callback)
	glfw.SetCharCallback(state.window.handle, cast(glfw.CharProc)typing_callback)
	glfw.SetWindowUserPointer(state.window.handle, state)

	when ODIN_OS == .Windows do win.timeBeginPeriod(1)
	
	opengl_init()
	ui_init()

	return true
}

update :: proc() {
	state.start_time = time.now()
	state.delta_time = time.duration_milliseconds(time.diff(state.prev_time, state.start_time))

	state.quit = bool(glfw.WindowShouldClose(state.window.handle))
	if state.quit do return

	glfw.PollEvents()

	width, height := glfw.GetWindowSize(state.window.handle)
	state.window.size = {width, height}
	state.window.quad = {0, 0, f32(width), f32(height)}
	
	framebuffer_width, framebuffer_height := glfw.GetFramebufferSize(state.window.handle)
	state.window.framebuffer = {framebuffer_width, framebuffer_height}
	
	mouseX, mouseY := glfw.GetCursorPos(state.window.handle)
	old_mouse := state.mouse.pos
	state.mouse.pos = {i32(mouseX), i32(mouseY)}
	state.mouse.delta = (state.mouse.pos - old_mouse) / 2

	ui_update()
	opengl_render()

	frame_goal : time.Duration = 33330000
	time_so_far := time.diff(state.start_time, time.now())
	sleep_for:= frame_goal - time_so_far

	time.accurate_sleep(sleep_for)

	mouse_buttons: [3]^Button = { &state.mouse.left, &state.mouse.right, &state.mouse.middle }
	for mouse_button, index in mouse_buttons {
		if mouse_button^ == .CLICK do mouse_button^ = .DRAG
		if mouse_button^ == .RELEASE do mouse_button^ = .UP
	}
	state.mouse.scroll = {0,0}
	state.prev_time = state.start_time
}

quit :: proc() {
	glfw.DestroyWindow(state.window.handle)
	glfw.Terminate()
	free(state)
}

read_key :: proc(key: ^bool) -> bool {
	if key^ {
		key^ = false
		return true
	} else {
		return false
	}
}

process_keyboard_input :: proc(action: int, key_state: ^bool, repeat: bool) {
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

keyboard_callback :: proc(Window: glfw.WindowHandle, key: int, scancode: int, action: int, mods: int) {
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

typing_callback :: proc(window: glfw.WindowHandle, codepoint: u32) {
	// fmt.println(rune(codepoint))
	// State.UILastChar = rune(codepoint);
}

scroll_callback :: proc(window: glfw.WindowHandle, x: f64, y: f64) {
	state.mouse.scroll = {f32(x),f32(y)}
}

mouse_button :: proc(button: Button, type: Button) -> bool {
	return (button == type)
}

lmb_click :: proc() -> bool { return mouse_button(state.mouse.left, .CLICK) }
lmb_drag :: proc() -> bool { return mouse_button(state.mouse.left, .DRAG) }
lmb_release :: proc() -> bool { return mouse_button(state.mouse.left, .RELEASE) }
lmb_release_up :: proc() -> bool { return (mouse_button(state.mouse.left, .RELEASE) || mouse_button(state.mouse.left, .UP)) }
lmb_up :: proc() -> bool { return mouse_button(state.mouse.left, .UP) }

mouse_callback :: proc(window: glfw.WindowHandle, button: int, action: int, mods: int) {
	mouse_buttons: [3]^Button = { &state.mouse.left, &state.mouse.right, &state.mouse.middle }
	for mouse_button, index in mouse_buttons
	{
		if button == index {
			if action == int(glfw.PRESS) {
				mouse_button^ = .CLICK 
			} else if action == int(glfw.RELEASE) {
				mouse_button^ = .RELEASE
			}
		}
	}
}
