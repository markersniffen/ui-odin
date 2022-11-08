package ui

import glfw "vendor:glfw"
import "core:fmt"

Window :: struct {
	handle: glfw.WindowHandle,
	size: v2i,
	framebuffer: v2i,
	quad: Quad,
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

glfw_init :: proc() -> bool {
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
	// glfw.SetWindowSizeCallback(state.window.handle, cast(glfw.WindowSizeProc)size_callback)
	glfw.SetWindowUserPointer(state.window.handle, state)

	state.window.cursor.arrow = glfw.CreateStandardCursor(glfw.ARROW_CURSOR)
	state.window.cursor.text = glfw.CreateStandardCursor(glfw.IBEAM_CURSOR)
	state.window.cursor.cross = glfw.CreateStandardCursor(glfw.CROSSHAIR_CURSOR)
	state.window.cursor.hand = glfw.CreateStandardCursor(glfw.HAND_CURSOR)
	state.window.cursor.x = glfw.CreateStandardCursor(glfw.HRESIZE_CURSOR)
	state.window.cursor.y = glfw.CreateStandardCursor(glfw.VRESIZE_CURSOR)
	

	return true
}

glfw_update :: proc() {
	state.quit = bool(glfw.WindowShouldClose(state.window.handle))
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
}

glfw_quit :: proc() {
	glfw.DestroyWindow(state.window.handle)
	glfw.Terminate()
}

glfw_set_cursor :: proc() {
	cursor:glfw.CursorHandle
	#partial switch state.window.cursor.type {
		case .NULL:
		cursor = nil
		case .ARROW:
		cursor = state.window.cursor.arrow
		case .TEXT:
		cursor = state.window.cursor.text
		case .CROSS:
		cursor = state.window.cursor.cross
		case .HAND:
		cursor = state.window.cursor.hand
		case .X:
		cursor = state.window.cursor.x
		case .Y:
		cursor = state.window.cursor.y
	}
	if state.window.cursor.active != cursor {
		glfw.SetCursor(state.window.handle, cursor)
		state.window.cursor.active = cursor
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