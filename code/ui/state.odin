package ui

PROFILER :: false

when PROFILER do import tracy "../../../odin-tracy"

import "core:fmt"
import "core:time"
import "core:runtime"
import "core:os"
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

state : ^State

State :: struct {
	debug: 		Debug,

	quit: 		bool,
	uid: 			Uid,
	window: 		Window,
	ui: 			Ui,
	render: 		Gl,
	stats: 		Stats,
	input: 		Input,
}

Window :: struct {
	handle: glfw.WindowHandle,
	size: v2i,
	framebuffer: v2i,
	quad: Quad,
}

Stats :: struct {
	start_time: time.Time,
	prev_time: time.Time,
	delta_time: f64,
	fps: f64,
}

Input :: struct {
	mouse: Mouse,
	keys: Keys,
}

Mouse :: struct {
	pos: v2,
	delta: v2,
	delta_temp: v2,
	left: Button,
	right: Button,
	middle: Button,
	scroll: v2,
	cursor: Cursor,
	cursor_handle: glfw.CursorHandle,
}

Cursor :: struct {
	type: Cursor_Type,
	active: glfw.CursorHandle,
	arrow: glfw.CursorHandle,
	text: glfw.CursorHandle,
	cross: glfw.CursorHandle,
	hand: glfw.CursorHandle,
	x: glfw.CursorHandle,
	y: glfw.CursorHandle,
}

Cursor_Type :: enum {
	NULL,
	ACTIVE,
	ARROW,
	TEXT,
	HAND,
	CROSS,
	X,
	Y,
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
	home: bool,
	end: bool,

	n_enter: bool,
	n_plus: bool,
	n_minus: bool,

	ctrl: bool,
	alt: bool,
	shift: bool,

	a: bool,
	c: bool,
	x: bool,
	v: bool,
}

init :: proc() -> (^State, bool) {
	state = new(State)

	fmt.println(context.temp_allocator)
	if !bool(glfw.Init())
	{
		fmt.eprintln("GLFW has failed to load.")
		return state, false
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
		return state, false
	}

	glfw.SetWindowPos(state.window.handle, 500,200)
	glfw.MakeContextCurrent(state.window.handle)
	glfw.SetKeyCallback(state.window.handle, cast(glfw.KeyProc)keyboard_callback)
	glfw.SetMouseButtonCallback(state.window.handle, cast(glfw.MouseButtonProc)mouse_callback)
	glfw.SetScrollCallback(state.window.handle, cast(glfw.ScrollProc)scroll_callback)
	glfw.SetCharCallback(state.window.handle, cast(glfw.CharProc)typing_callback)
	// glfw.SetWindowSizeCallback(state.window.handle, cast(glfw.WindowSizeProc)size_callback)
	glfw.SetWindowUserPointer(state.window.handle, state)

	state.input.mouse.cursor.arrow = glfw.CreateStandardCursor(glfw.ARROW_CURSOR)
	state.input.mouse.cursor.text = glfw.CreateStandardCursor(glfw.IBEAM_CURSOR)
	state.input.mouse.cursor.cross = glfw.CreateStandardCursor(glfw.CROSSHAIR_CURSOR)
	state.input.mouse.cursor.hand = glfw.CreateStandardCursor(glfw.HAND_CURSOR)
	state.input.mouse.cursor.x = glfw.CreateStandardCursor(glfw.HRESIZE_CURSOR)
	state.input.mouse.cursor.y = glfw.CreateStandardCursor(glfw.VRESIZE_CURSOR)
	
	when ODIN_OS == .Windows do win.timeBeginPeriod(1)
	
	opengl_init()
	ui_init()

	return state, true
}

update :: proc() {
	state.stats.start_time = time.now()
	state.stats.delta_time = time.duration_milliseconds(time.diff(state.stats.prev_time, state.stats.start_time))
	state.stats.fps = 1000 / state.stats.delta_time

	state.quit = bool(glfw.WindowShouldClose(state.window.handle))
	if state.quit do return
	
	glfw.PollEvents()

	width, height := glfw.GetWindowSize(state.window.handle)
	state.window.size = {width, height}
	state.window.quad = {0, 0, f32(width), f32(height)}
	
	framebuffer_width, framebuffer_height := glfw.GetFramebufferSize(state.window.handle)
	state.window.framebuffer = {framebuffer_width, framebuffer_height}
	
	mouseX, mouseY := glfw.GetCursorPos(state.window.handle)
	old_mouse := state.input.mouse.pos
	state.input.mouse.pos = {f32(mouseX), f32(mouseY)}
	state.input.mouse.delta = state.input.mouse.pos - old_mouse
	
	ui_update()
	opengl_render()

	// frame_goal : time.Duration = 16665000
	frame_goal : time.Duration = 8332500
	time_so_far := time.diff(state.stats.start_time, time.now())
	sleep_for:= frame_goal - time_so_far

	time.accurate_sleep(sleep_for)

	mouse_buttons: [3]^Button = { &state.input.mouse.left, &state.input.mouse.right, &state.input.mouse.middle }
	for mouse_button, index in mouse_buttons {
		if mouse_button^ == .CLICK do mouse_button^ = .DRAG
		if mouse_button^ == .RELEASE do mouse_button^ = .UP
	}
	state.input.mouse.scroll = {0,0}
	state.stats.prev_time = state.stats.start_time
	
}

quit :: proc() {
	glfw.DestroyWindow(state.window.handle)
	glfw.Terminate()
	free(state)
}


// size_callback :: proc(Window: glfw.WindowHandle) {
// }

shift :: proc() -> bool { return state.input.keys.shift }
alt :: proc() -> bool { return state.input.keys.alt }
ctrl :: proc() -> bool { return state.input.keys.ctrl }

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
		case glfw.KEY_LEFT:				process_keyboard_input(action, &state.input.keys.left, true)
		case glfw.KEY_RIGHT:			process_keyboard_input(action, &state.input.keys.right, true)
		case glfw.KEY_UP:				process_keyboard_input(action, &state.input.keys.up, true)
		case glfw.KEY_DOWN:				process_keyboard_input(action, &state.input.keys.down, true)
		
		case glfw.KEY_ESCAPE:			process_keyboard_input(action, &state.input.keys.escape, true)
		case glfw.KEY_TAB:				process_keyboard_input(action, &state.input.keys.tab, false)
		case glfw.KEY_ENTER:		 	process_keyboard_input(action, &state.input.keys.enter, true)
		case glfw.KEY_SPACE:			process_keyboard_input(action, &state.input.keys.space, true)
		case glfw.KEY_BACKSPACE:		process_keyboard_input(action, &state.input.keys.backspace, true)
		case glfw.KEY_DELETE:			process_keyboard_input(action, &state.input.keys.delete, true)
		case glfw.KEY_HOME:				process_keyboard_input(action, &state.input.keys.home, true)
	 	case glfw.KEY_END:				process_keyboard_input(action, &state.input.keys.end, true)

		case glfw.KEY_KP_ENTER:			process_keyboard_input(action, &state.input.keys.enter, true)
		case glfw.KEY_KP_SUBTRACT:		process_keyboard_input(action, &state.input.keys.n_minus, false)
		case glfw.KEY_KP_ADD:			process_keyboard_input(action, &state.input.keys.n_plus, false)
		
		case glfw.KEY_LEFT_ALT:			process_keyboard_input(action, &state.input.keys.alt, false)
		case glfw.KEY_RIGHT_ALT:		process_keyboard_input(action, &state.input.keys.alt, false)
		
		case glfw.KEY_LEFT_CONTROL:		process_keyboard_input(action, &state.input.keys.ctrl, false)
		case glfw.KEY_RIGHT_CONTROL:	process_keyboard_input(action, &state.input.keys.ctrl, false)
		
		case glfw.KEY_LEFT_SHIFT:		process_keyboard_input(action, &state.input.keys.shift, false)
		case glfw.KEY_RIGHT_SHIFT:		process_keyboard_input(action, &state.input.keys.shift, false)

		case glfw.KEY_A:					process_keyboard_input(action, &state.input.keys.a, false)
	}
}

typing_callback :: proc(window: glfw.WindowHandle, codepoint: u32) {
	if !state.input.keys.ctrl && !state.input.keys.alt {
		state.ui.last_char = rune(codepoint)
	} else {
		state.ui.last_char = -1
	}
}

scroll_callback :: proc(window: glfw.WindowHandle, x: f64, y: f64) {
	if shift() {
		state.input.mouse.scroll = {f32(y), 0}
	} else {
		state.input.mouse.scroll = {f32(x),f32(y)}
	}
}

mouse_button :: proc(button: Button, type: Button) -> bool {
	return (button == type)
}

enter :: proc() -> bool { return state.input.keys.enter }

lmb_click :: proc() -> bool { return mouse_button(state.input.mouse.left, .CLICK) }
lmb_drag :: proc() -> bool { return mouse_button(state.input.mouse.left, .DRAG) }
lmb_click_drag :: proc() -> bool { return lmb_click() || lmb_drag() }
lmb_release :: proc() -> bool { return mouse_button(state.input.mouse.left, .RELEASE) }
lmb_release_up :: proc() -> bool { return (mouse_button(state.input.mouse.left, .RELEASE) || mouse_button(state.input.mouse.left, .UP)) }
lmb_up :: proc() -> bool { return mouse_button(state.input.mouse.left, .UP) }

rmb_click :: proc() -> bool { return mouse_button(state.input.mouse.right, .CLICK) }
rmb_drag :: proc() -> bool { return mouse_button(state.input.mouse.right, .DRAG) }
rmb_click_drag :: proc() -> bool { return rmb_click() || rmb_drag() }
rmb_release :: proc() -> bool { return mouse_button(state.input.mouse.right, .RELEASE) }
rmb_release_up :: proc() -> bool { return (mouse_button(state.input.mouse.right, .RELEASE) || mouse_button(state.input.mouse.right, .UP)) }
rmb_up :: proc() -> bool { return mouse_button(state.input.mouse.right, .UP) }

mmb_click :: proc() -> bool { return mouse_button(state.input.mouse.middle, .CLICK) }
mmb_drag :: proc() -> bool { return mouse_button(state.input.mouse.middle, .DRAG) }
mmb_click_drag :: proc() -> bool { return mmb_click() || mmb_drag() }
mmb_release :: proc() -> bool { return mouse_button(state.input.mouse.middle, .RELEASE) }
mmb_release_up :: proc() -> bool { return (mouse_button(state.input.mouse.middle, .RELEASE) || mouse_button(state.input.mouse.middle, .UP)) }
mmb_up :: proc() -> bool { return mouse_button(state.input.mouse.middle, .UP) }

set_cursor :: proc() {
	cursor:glfw.CursorHandle
	#partial switch state.input.mouse.cursor.type {
		case .NULL:
		cursor = nil
		case .ARROW:
		cursor = state.input.mouse.cursor.arrow
		case .TEXT:
		cursor = state.input.mouse.cursor.text
		case .CROSS:
		cursor = state.input.mouse.cursor.cross
		case .HAND:
		cursor = state.input.mouse.cursor.hand
		case .X:
		cursor = state.input.mouse.cursor.x
		case .Y:
		cursor = state.input.mouse.cursor.y
	}
	if state.input.mouse.cursor.active != cursor {
		glfw.SetCursor(state.window.handle, cursor)
		state.input.mouse.cursor.active = cursor
	}
}

cursor :: proc(type: Cursor_Type) {
	state.input.mouse.cursor.type = type
}

cursor_size :: proc(axis: Axis) {
	if axis == .X {
		state.input.mouse.cursor.type = .X
	} else {
		state.input.mouse.cursor.type = .Y
	}
}

mouse_callback :: proc(window: glfw.WindowHandle, button: int, action: int, mods: int) {
	mouse_buttons: [3]^Button = { &state.input.mouse.left, &state.input.mouse.right, &state.input.mouse.middle }
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
